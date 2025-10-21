using OtpNet;
using QRCoder;
using System.Text;
using System.Drawing;

namespace MoviePlusApi.Services
{
    public interface ITotpService
    {
        string GenerateSecretKey();
        string GenerateQrCode(string email, string secretKey, string appName = "MoviePlus");
        bool VerifyTotp(string secretKey, string totpCode);
        string GenerateTotp(string secretKey);
    }

    public class TotpService : ITotpService
    {
        private const int SecretKeyLength = 20;
        private const int TotpLength = 6;
        private const int TotpStepSeconds = 30;

        public string GenerateSecretKey()
        {
            var key = KeyGeneration.GenerateRandomKey(SecretKeyLength);
            return Base32Encoding.ToString(key);
        }

        public string GenerateQrCode(string email, string secretKey, string appName = "MoviePlus")
        {
            // Create the TOTP URI for Google Authenticator
            var qrCodeText = $"otpauth://totp/{appName}:{email}?secret={secretKey}&issuer={appName}";
            
            // Return the QR code text directly (Flutter will generate the QR code)
            return Convert.ToBase64String(Encoding.UTF8.GetBytes(qrCodeText));
        }

        public bool VerifyTotp(string secretKey, string totpCode)
        {
            try
            {
                var keyBytes = Base32Encoding.ToBytes(secretKey);
                var totp = new Totp(keyBytes, step: TotpStepSeconds, totpSize: TotpLength);
                
                var currentTimeStep = DateTimeOffset.UtcNow.ToUnixTimeSeconds() / TotpStepSeconds;
                
                // Verify current and previous time step (for clock skew tolerance)
                return totp.VerifyTotp(totpCode, out _, window: new VerificationWindow(1, 1));
            }
            catch
            {
                return false;
            }
        }

        public string GenerateTotp(string secretKey)
        {
            try
            {
                var keyBytes = Base32Encoding.ToBytes(secretKey);
                var totp = new Totp(keyBytes, step: TotpStepSeconds, totpSize: TotpLength);
                return totp.ComputeTotp();
            }
            catch
            {
                return string.Empty;
            }
        }
    }
}
