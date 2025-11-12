namespace VendorDashboard.Models.DTOs
{
    public class EnhanceImageResponse
    {
        public bool Success { get; set; }
        public string? EnhancedImageUrl { get; set; }
        public string? Error { get; set; }
    }
}
