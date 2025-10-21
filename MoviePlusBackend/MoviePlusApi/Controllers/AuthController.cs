using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.DTOs;
using MoviePlusApi.Models;
using MoviePlusApi.Services;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace MoviePlusApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class AuthController : ControllerBase
    {
        private readonly MoviePlusContext _context;
        private readonly IJwtService _jwtService;
        private readonly IPasswordHasher<User> _passwordHasher;
        private readonly ITotpService _totpService;

        public AuthController(MoviePlusContext context, IJwtService jwtService, IPasswordHasher<User> passwordHasher, ITotpService totpService)
        {
            _context = context;
            _jwtService = jwtService;
            _passwordHasher = passwordHasher;
            _totpService = totpService;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register(RegisterDto dto)
        {
            if (await _context.Users.AnyAsync(x => x.Email == dto.Email))
            {
                return BadRequest(new { message = "Email already exists" });
            }

            var user = new User
            {
                Email = dto.Email,
                DisplayName = dto.DisplayName
            };

            user.PasswordHash = _passwordHasher.HashPassword(user, dto.Password);

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            return Ok(new { message = "User registered successfully" });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login(LoginDto dto)
        {
            var user = await _context.Users.SingleOrDefaultAsync(x => x.Email == dto.Email);
            if (user == null)
            {
                return Unauthorized(new { message = "Invalid email or password" });
            }

            var verificationResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
            if (verificationResult == PasswordVerificationResult.Failed)
            {
                return Unauthorized(new { message = "Invalid email or password" });
            }

            var token = _jwtService.GenerateToken(user);

            var userDto = new DTOs.UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                Role = user.Role,
                BioAuthEnabled = user.BioAuthEnabled,
                CreatedAt = user.CreatedAt
            };

            return Ok(new LoginResponseDto { Token = token, User = userDto });
        }

        [HttpGet("profile")]
        [Authorize]
        public async Task<IActionResult> GetProfile()
        {
            var userEmail = User.FindFirst(ClaimTypes.Email)?.Value;
            if (userEmail == null)
            {
                return Unauthorized();
            }

            var user = await _context.Users.SingleOrDefaultAsync(x => x.Email == userEmail);
            if (user == null)
            {
                return Unauthorized();
            }

            var userDto = new DTOs.UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                Role = user.Role,
                BioAuthEnabled = user.BioAuthEnabled,
                CreatedAt = user.CreatedAt
            };

            return Ok(userDto);
        }

        [HttpPost("register-biometric")]
        [Authorize]
        public async Task<IActionResult> RegisterBiometric(BiometricRegisterDto dto)
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            // Lưu template vân tay và bật bio auth
            user.BiometricTemplate = dto.Template;
            user.BioAuthEnabled = true;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Biometric authentication registered successfully" });
        }

        [HttpPost("login-biometric")]
        public async Task<IActionResult> LoginBiometric(BiometricLoginDto dto)
        {
            // Tìm tất cả user có template khớp
            var users = await _context.Users
                .Where(u => u.BiometricTemplate == dto.Template && u.BioAuthEnabled)
                .Select(u => new { u.Id, u.Email, u.DisplayName })
                .ToListAsync();

            if (!users.Any())
            {
                return Unauthorized(new { message = "Biometric authentication failed" });
            }

            // Nếu có nhiều tài khoản, trả về danh sách để user chọn
            if (users.Count > 1)
            {
                return Ok(new { 
                    multipleAccounts = true, 
                    accounts = users.Select(u => new { u.Id, u.Email, u.DisplayName })
                });
            }

            // Nếu chỉ có 1 tài khoản, đăng nhập luôn
            var user = await _context.Users.FindAsync(users.First().Id);
            var token = _jwtService.GenerateToken(user);

            var userDto = new DTOs.UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                Role = user.Role,
                BioAuthEnabled = user.BioAuthEnabled,
                CreatedAt = user.CreatedAt
            };

            return Ok(new LoginResponseDto { Token = token, User = userDto });
        }

        [HttpPost("login-biometric-account")]
        public async Task<IActionResult> LoginBiometricAccount(BiometricAccountLoginDto dto)
        {
            // Đăng nhập vào tài khoản cụ thể
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == dto.UserId && u.BiometricTemplate == dto.Template && u.BioAuthEnabled);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid account selection" });
            }

            var token = _jwtService.GenerateToken(user);

            var userDto = new DTOs.UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                Role = user.Role,
                BioAuthEnabled = user.BioAuthEnabled,
                CreatedAt = user.CreatedAt
            };

            return Ok(new LoginResponseDto { Token = token, User = userDto });
        }

        [HttpDelete("remove-biometric")]
        [Authorize]
        public async Task<IActionResult> RemoveBiometric()
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            // Xóa template và tắt bio auth
            user.BiometricTemplate = null;
            user.BioAuthEnabled = false;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Biometric authentication removed successfully" });
        }

        // ==================== TWO-FACTOR AUTHENTICATION ====================

        [HttpPost("enable-2fa")]
        [Authorize]
        public async Task<IActionResult> Enable2FA()
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            if (user.TwoFactorEnabled)
            {
                return BadRequest(new { message = "Two-factor authentication is already enabled" });
            }

            // Generate secret key
            var secretKey = _totpService.GenerateSecretKey();
            user.TwoFactorSecret = secretKey;

            // Generate QR code
            var qrCodeBase64 = _totpService.GenerateQrCode(user.Email, secretKey, "MoviePlus");

            await _context.SaveChangesAsync();

            return Ok(new Enable2FAResponseDto
            {
                SecretKey = secretKey,
                QrCodeBase64 = qrCodeBase64,
                ManualEntryKey = secretKey
            });
        }

        [HttpPost("verify-2fa")]
        [Authorize]
        public async Task<IActionResult> Verify2FA([FromBody] Verify2FARequestDto dto)
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            if (string.IsNullOrEmpty(user.TwoFactorSecret))
            {
                return BadRequest(new { message = "Two-factor authentication is not set up" });
            }

            // Verify TOTP code
            if (!_totpService.VerifyTotp(user.TwoFactorSecret, dto.TotpCode))
            {
                return BadRequest(new { message = "Invalid verification code" });
            }

            // Enable 2FA
            user.TwoFactorEnabled = true;
            user.TwoFactorEnabledAt = DateTime.UtcNow;

            // Generate recovery codes (optional)
            var recoveryCodes = GenerateRecoveryCodes();

            await _context.SaveChangesAsync();

            return Ok(new Verify2FAResponseDto
            {
                Success = true,
                Message = "Two-factor authentication enabled successfully",
                RecoveryCodes = recoveryCodes
            });
        }

        [HttpPost("disable-2fa")]
        [Authorize]
        public async Task<IActionResult> Disable2FA([FromBody] Disable2FARequestDto dto)
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            if (!user.TwoFactorEnabled)
            {
                return BadRequest(new { message = "Two-factor authentication is not enabled" });
            }

            // Verify TOTP code before disabling
            if (!_totpService.VerifyTotp(user.TwoFactorSecret!, dto.TotpCode))
            {
                return BadRequest(new { message = "Invalid verification code" });
            }

            // Disable 2FA
            user.TwoFactorEnabled = false;
            user.TwoFactorSecret = null;
            user.TwoFactorEnabledAt = null;

            await _context.SaveChangesAsync();

            return Ok(new Disable2FAResponseDto
            {
                Success = true,
                Message = "Two-factor authentication disabled successfully"
            });
        }

        [HttpPost("login-with-2fa")]
        public async Task<IActionResult> LoginWith2FA([FromBody] LoginWith2FARequestDto dto)
        {
            var user = await _context.Users.FirstOrDefaultAsync(x => x.Email == dto.Email);

            if (user == null)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            // Verify password
            var passwordResult = _passwordHasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
            if (passwordResult != PasswordVerificationResult.Success)
            {
                return Unauthorized(new { message = "Invalid credentials" });
            }

            // Check if 2FA is enabled
            if (!user.TwoFactorEnabled)
            {
                return BadRequest(new { message = "Two-factor authentication is not enabled for this account" });
            }

            // Verify TOTP code
            if (!_totpService.VerifyTotp(user.TwoFactorSecret!, dto.TotpCode))
            {
                return Unauthorized(new { message = "Invalid verification code" });
            }

            // Generate JWT token
            var token = _jwtService.GenerateToken(user);

            return Ok(new
            {
                token = token,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    displayName = user.DisplayName,
                    role = user.Role,
                    twoFactorEnabled = user.TwoFactorEnabled
                }
            });
        }

        [HttpPost("complete-2fa-biometric")]
        [Authorize]
        public async Task<IActionResult> Complete2FABiometric([FromBody] Verify2FARequestDto dto)
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            // Check if 2FA is enabled
            if (!user.TwoFactorEnabled)
            {
                return BadRequest(new { message = "Two-factor authentication is not enabled for this account" });
            }

            // Verify TOTP code
            if (!_totpService.VerifyTotp(user.TwoFactorSecret!, dto.TotpCode))
            {
                return Unauthorized(new { message = "Invalid verification code" });
            }

            // Generate new JWT token
            var token = _jwtService.GenerateToken(user);

            return Ok(new
            {
                token = token,
                user = new
                {
                    id = user.Id,
                    email = user.Email,
                    displayName = user.DisplayName,
                    role = user.Role,
                    twoFactorEnabled = user.TwoFactorEnabled
                }
            });
        }

        [HttpGet("2fa-status")]
        [Authorize]
        public async Task<IActionResult> Get2FAStatus()
        {
            var userId = GetCurrentUserId();
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
            {
                return NotFound(new { message = "User not found" });
            }

            return Ok(new
            {
                twoFactorEnabled = user.TwoFactorEnabled,
                twoFactorEnabledAt = user.TwoFactorEnabledAt
            });
        }

        private string[] GenerateRecoveryCodes()
        {
            var codes = new string[8];
            var random = new Random();
            
            for (int i = 0; i < 8; i++)
            {
                var code = "";
                for (int j = 0; j < 8; j++)
                {
                    code += (char)('A' + random.Next(26));
                }
                codes[i] = code;
            }
            
            return codes;
        }

        private Guid GetCurrentUserId()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return Guid.Parse(userIdClaim!);
        }
    }
}