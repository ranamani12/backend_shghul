using System.ComponentModel.DataAnnotations;

namespace VendorDashboard.Models.DTOs;

/// <summary>
/// Request payload for generating promotional content and imagery.
/// </summary>
public class PromotionalContentRequest
{
    [Required]
    [StringLength(120)]
    public string StoreType { get; set; } = string.Empty;

    [Required]
    [StringLength(120)]
    public string ProductCategory { get; set; } = string.Empty;

    [StringLength(160)]
    public string? ProductName { get; set; }
        = string.Empty;

    [Range(0, double.MaxValue)]
    public decimal? ProductPrice { get; set; }
        = null;

    [StringLength(200)]
    public string? TargetAudience { get; set; }
        = null;

    [StringLength(200)]
    public string? SellingPoint { get; set; }
        = null;

    [StringLength(200)]
    public string? CampaignObjective { get; set; }
        = null;

    /// <summary>
    /// Optional tone or style direction (e.g., "luxury", "youthful", "family-friendly").
    /// </summary>
    [StringLength(80)]
    public string? BrandTone { get; set; }
        = null;

    /// <summary>
    /// A short description or technical details supplied by the merchant.
    /// </summary>
    [StringLength(500)]
    public string? ProductDescription { get; set; }
        = null;

    /// <summary>
    /// If true, the API will craft promotional copy. Defaults to true.
    /// </summary>
    public bool GenerateCopy { get; set; } = true;

    /// <summary>
    /// If true, the API will create an AI-generated image. Defaults to true.
    /// </summary>
    public bool GenerateImage { get; set; } = true;

    /// <summary>
    /// Optional URL to a merchant-supplied product image. Used when GenerateImage is false.
    /// </summary>
    [Url]
    public string? ExistingImageUrl { get; set; }
        = null;
}
