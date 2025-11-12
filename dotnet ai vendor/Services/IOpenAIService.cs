using VendorDashboard.Models;

namespace VendorDashboard.Services
{
    public interface IOpenAIService
    {
        Task<string> GenerateProductDescriptionAsync(string productName, string? additionalDetails = null, string language = "en");
        Task<string> GenerateProductImageAsync(string productName, string? additionalDetails = null);
        Task<string> EnhanceImageAsync(string imagePath);

        Task<string> GeneratePromotionalTextAsync(PromotionalContentContext context, string language);
        Task<string> GeneratePromotionalImageAsync(PromotionalContentContext context);
    }
}
