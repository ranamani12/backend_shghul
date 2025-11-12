using System.ComponentModel.DataAnnotations;

namespace VendorDashboard.Models.DTOs
{
    public class EnhanceImageRequest
    {
        [Required]
        public IFormFile ImageFile { get; set; } = null!;
    }
}
