using System.ComponentModel.DataAnnotations;

namespace VendorDashboard.Models.DTOs
{
    public class GenerateProductRequest
    {
        [Required]
        [StringLength(200)]
        public string ProductName { get; set; } = string.Empty;

        [StringLength(1000)]
        public string? AdditionalDetails { get; set; }

        public bool GenerateImage { get; set; } = true;
    }
}
