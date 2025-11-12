using Microsoft.AspNetCore.Mvc;
using VendorDashboard.Models;
using VendorDashboard.Models.DTOs;
using System.ClientModel;
using VendorDashboard.Services;

namespace VendorDashboard.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PromotionsController : ControllerBase
{
    private readonly IOpenAIService _openAIService;
    private readonly ILogger<PromotionsController> _logger;

    public PromotionsController(IOpenAIService openAIService, ILogger<PromotionsController> logger)
    {
        _openAIService = openAIService;
        _logger = logger;
    }

    /// <summary>
    /// Generates promotional copy and/or imagery tailored for the Kuwait market.
    /// </summary>
    [HttpPost("generate")]
    [ProducesResponseType(typeof(PromotionalContentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<PromotionalContentResponse>> GenerateAsync([FromBody] PromotionalContentRequest request)
    {
        if (!ModelState.IsValid)
        {
            return ValidationProblem(ModelState);
        }

        if (!request.GenerateCopy && !request.GenerateImage && string.IsNullOrWhiteSpace(request.ExistingImageUrl))
        {
            return BadRequest("At least one of GenerateCopy or GenerateImage must be true, or provide an ExistingImageUrl.");
        }

        var context = new PromotionalContentContext
        {
            StoreType = request.StoreType,
            ProductCategory = request.ProductCategory,
            ProductName = request.ProductName,
            ProductPrice = request.ProductPrice,
            TargetAudience = request.TargetAudience,
            SellingPoint = request.SellingPoint,
            CampaignObjective = request.CampaignObjective,
            BrandTone = request.BrandTone,
            ProductDescription = request.ProductDescription
        };

        var response = new PromotionalContentResponse
        {
            Success = true,
            Metadata = new PromotionMetadata
            {
                StoreType = context.StoreType,
                ProductCategory = context.ProductCategory,
                ProductName = context.ProductName,
                ProductPrice = context.ProductPrice
            }
        };

        try
        {
            if (request.GenerateCopy)
            {
                var englishCopy = await _openAIService.GeneratePromotionalTextAsync(context, "en");
                var arabicCopy = await _openAIService.GeneratePromotionalTextAsync(context, "ar");

                response.PromotionalCopy = new PromotionalCopy
                {
                    English = englishCopy,
                    Arabic = arabicCopy
                };
                response.Metadata.CopyGenerated = true;
            }

            if (request.GenerateImage)
            {
                response.ImageUrl = await _openAIService.GeneratePromotionalImageAsync(context);
                response.Metadata.ImageGenerated = true;
            }
            else if (!string.IsNullOrWhiteSpace(request.ExistingImageUrl))
            {
                response.ImageUrl = request.ExistingImageUrl;
                response.Metadata.ImageGenerated = false;
            }

            response.Message = "Promotional assets generated successfully.";
            response.Metadata.GeneratedAtUtc = DateTime.UtcNow;

            return Ok(response);
        }
        catch (ClientResultException clientEx)
        {
            _logger.LogError(clientEx, "OpenAI API error while generating promotion for {StoreType}/{Category}", request.StoreType, request.ProductCategory);
            return StatusCode(StatusCodes.Status502BadGateway, new PromotionalContentResponse
            {
                Success = false,
                Message = "OpenAI service returned an error. Please try again later."
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error while generating promotion for {StoreType}/{Category}", request.StoreType, request.ProductCategory);
            return StatusCode(StatusCodes.Status500InternalServerError, new PromotionalContentResponse
            {
                Success = false,
                Message = "An unexpected error occurred while generating the promotion."
            });
        }
    }
}
