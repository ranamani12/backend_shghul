namespace VendorDashboard.Models.DTOs
{
    public class RemoveBackgroundResponse
    {
        public bool Success { get; set; }
        public string? ProcessedImageUrl { get; set; }
        public string? OriginalImageUrl { get; set; }
        public string? Error { get; set; }
    }
}
