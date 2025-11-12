namespace VendorDashboard.Models.DTOs
{
    public class GenerateProductResponse
    {
        public bool Success { get; set; }
        public string? DescriptionEnglish { get; set; }
        public string? DescriptionArabic { get; set; }
        public string? ImageUrl { get; set; }
        public string? Error { get; set; }
    }
}
