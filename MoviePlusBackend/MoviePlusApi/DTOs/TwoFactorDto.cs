namespace MoviePlusApi.DTOs
{
    public class Enable2FAResponseDto
    {
        public string SecretKey { get; set; } = string.Empty;
        public string QrCodeBase64 { get; set; } = string.Empty;
        public string ManualEntryKey { get; set; } = string.Empty;
    }

    public class Verify2FARequestDto
    {
        public string TotpCode { get; set; } = string.Empty;
    }

    public class Verify2FAResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public string[] RecoveryCodes { get; set; } = Array.Empty<string>();
    }

    public class LoginWith2FARequestDto
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string TotpCode { get; set; } = string.Empty;
    }

    public class Disable2FARequestDto
    {
        public string TotpCode { get; set; } = string.Empty;
    }

    public class Disable2FAResponseDto
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
    }
}
