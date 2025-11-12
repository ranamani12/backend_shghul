namespace VendorDashboard.Models.DTOs;

/// <summary>
/// Response payload returned from the promotional content generation endpoint.
/// </summary>
public class PromotionalContentResponse
{
    public bool Success { get; set; }

    public string? Message { get; set; }

    /// <summary>
    /// Optional AI generated promotional copy.
    /// </summary>
    public PromotionalCopy? PromotionalCopy { get; set; }

    /// <summary>
    /// URL of the generated or supplied product image.
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// Additional metadata describing how the promotion was generated.
    /// </summary>
    public PromotionMetadata Metadata { get; set; } = new();
}

public class PromotionalCopy
{
    public string? English { get; set; }
    public string? Arabic { get; set; }
}

public class PromotionMetadata
{
    public string StoreType { get; set; } = string.Empty;
    public string ProductCategory { get; set; } = string.Empty;
    public string? ProductName { get; set; }
        = null;
    public decimal? ProductPrice { get; set; }
        = null;
    public bool CopyGenerated { get; set; }
        = false;
    public bool ImageGenerated { get; set; }
        = false;
    public DateTime GeneratedAtUtc { get; set; } = DateTime.UtcNow;
}
