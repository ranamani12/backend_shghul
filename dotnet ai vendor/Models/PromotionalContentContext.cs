namespace VendorDashboard.Models;

/// <summary>
/// Encapsulates the context required to generate promotional copy and imagery.
/// </summary>
public class PromotionalContentContext
{
    public string StoreType { get; set; } = string.Empty;
    public string ProductCategory { get; set; } = string.Empty;
    public string? ProductName { get; set; }
        = null;
    public decimal? ProductPrice { get; set; }
        = null;
    public string? TargetAudience { get; set; }
        = null;
    public string? SellingPoint { get; set; }
        = null;
    public string? CampaignObjective { get; set; }
        = null;
    public string? BrandTone { get; set; }
        = null;
    public string? ProductDescription { get; set; }
        = null;
}
