using System.ComponentModel.DataAnnotations;

namespace VendorDashboard.Models.DTOs
{
    public class RemoveBackgroundRequest
    {
        [Required]
        public IFormFile ImageFile { get; set; } = null!;
    }
}
