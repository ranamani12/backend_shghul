using Microsoft.AspNetCore.Mvc;
using SixLabors.ImageSharp;
using VendorDashboard.Models;
using VendorDashboard.Models.DTOs;
using VendorDashboard.Services;

namespace VendorDashboard.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly IOpenAIService _openAIService;
        private readonly IBackgroundRemovalService _backgroundRemovalService;
        private readonly ILogger<ProductsController> _logger;
        private readonly IWebHostEnvironment _environment;
        private readonly BaseUrlConfiguration _baseUrlConfig;

        public ProductsController(
            IOpenAIService openAIService,
            IBackgroundRemovalService backgroundRemovalService,
            ILogger<ProductsController> logger,
            IWebHostEnvironment environment,
            BaseUrlConfiguration baseUrlConfig)
        {
            _openAIService = openAIService;
            _backgroundRemovalService = backgroundRemovalService;
            _logger = logger;
            _environment = environment;
            _baseUrlConfig = baseUrlConfig;
        }

        /// <summary>
        /// Generates AI-powered product descriptions in both English and Arabic, with optional image generation
        /// </summary>
        /// <param name="request">Product generation request containing product name, additional details, and generateImage flag</param>
        /// <returns>Generated product descriptions in both languages and optional image URL</returns>
        /// <remarks>
        /// Sample request:
        ///
        ///     POST /api/products/generate
        ///     {
        ///        "productName": "Wireless Headphones",
        ///        "additionalDetails": "Premium quality with noise cancellation",
        ///        "generateImage": true
        ///     }
        ///
        /// Response includes:
        /// - descriptionEnglish: Product description in English
        /// - descriptionArabic: Product description in Arabic
        /// - imageUrl: Generated image URL (null if generateImage is false)
        /// </remarks>
        [HttpPost("generate")]
        [ProducesResponseType(typeof(GenerateProductResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<GenerateProductResponse>> GenerateProduct([FromBody] GenerateProductRequest request)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    return BadRequest(new GenerateProductResponse
                    {
                        Success = false,
                        Error = "Invalid request data"
                    });
                }

                _logger.LogInformation("Generating content for product: {ProductName}, GenerateImage: {GenerateImage}",
                    request.ProductName, request.GenerateImage);

                // Generate descriptions in both English and Arabic
                var descriptionEnglishTask = _openAIService.GenerateProductDescriptionAsync(
                    request.ProductName,
                    request.AdditionalDetails,
                    "en");
                var descriptionArabicTask = _openAIService.GenerateProductDescriptionAsync(
                    request.ProductName,
                    request.AdditionalDetails,
                    "ar");

                // Conditionally generate image based on request parameter
                Task<string>? imageTask = null;
                if (request.GenerateImage)
                {
                    imageTask = _openAIService.GenerateProductImageAsync(
                        request.ProductName,
                        request.AdditionalDetails);
                }

                // Wait for all tasks to complete
                if (imageTask != null)
                {
                    await Task.WhenAll(descriptionEnglishTask, descriptionArabicTask, imageTask);
                }
                else
                {
                    await Task.WhenAll(descriptionEnglishTask, descriptionArabicTask);
                }

                var descriptionEnglish = await descriptionEnglishTask;
                var descriptionArabic = await descriptionArabicTask;
                var imageUrl = imageTask != null ? await imageTask : null;

                return Ok(new GenerateProductResponse
                {
                    Success = true,
                    DescriptionEnglish = descriptionEnglish,
                    DescriptionArabic = descriptionArabic,
                    ImageUrl = imageUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating product content");
                return StatusCode(500, new GenerateProductResponse
                {
                    Success = false,
                    Error = "Failed to generate product content. Please try again."
                });
            }
        }

        /// <summary>
        /// Removes background from uploaded image
        /// </summary>
        /// <param name="imageFile">The image file to process</param>
        /// <returns>Processed image URL with background removed</returns>
        [HttpPost("remove-background")]
        [ProducesResponseType(typeof(RemoveBackgroundResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<RemoveBackgroundResponse>> RemoveBackground(IFormFile imageFile)
        {
            try
            {
                if (imageFile == null || imageFile.Length == 0)
                {
                    return BadRequest(new RemoveBackgroundResponse
                    {
                        Success = false,
                        Error = "No image file provided"
                    });
                }

                // Validate file type
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                var fileExtension = Path.GetExtension(imageFile.FileName).ToLowerInvariant();

                if (!allowedExtensions.Contains(fileExtension))
                {
                    return BadRequest(new RemoveBackgroundResponse
                    {
                        Success = false,
                        Error = "Invalid file type. Only JPG, PNG, and WebP images are supported."
                    });
                }

                // Save the uploaded image to original directory
                var uploadsPath = Path.Combine(_environment.WebRootPath, "uploads", "original");
                Directory.CreateDirectory(uploadsPath);

                var fileName = $"{Guid.NewGuid():N}{fileExtension}";
                var filePath = Path.Combine(uploadsPath, fileName);
                var relativePath = $"uploads/original/{fileName}";

                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await imageFile.CopyToAsync(stream);
                }

                _logger.LogInformation("Processing background removal for file: {FileName}", fileName);

                // Remove background from the image
                var processedImagePath = await _backgroundRemovalService.RemoveBackgroundAndEnhanceAsync(
                    relativePath,
                    Path.GetFileNameWithoutExtension(imageFile.FileName));

                // Remove leading slash from paths and prepend BASE_URL
                processedImagePath = processedImagePath.TrimStart('/');
                relativePath = relativePath.TrimStart('/');

                var fullProcessedImageUrl = $"{_baseUrlConfig.BaseUrl.TrimEnd('/')}/{processedImagePath}";
                var fullOriginalImageUrl = $"{_baseUrlConfig.BaseUrl.TrimEnd('/')}/{relativePath}";

                return Ok(new RemoveBackgroundResponse
                {
                    Success = true,
                    ProcessedImageUrl = fullProcessedImageUrl,
                    OriginalImageUrl = fullOriginalImageUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing background");
                return StatusCode(500, new RemoveBackgroundResponse
                {
                    Success = false,
                    Error = "Failed to remove background. Please try again."
                });
            }
        }

        /// <summary>
        /// Enhances uploaded image using OpenAI DALL-E 2 image editing
        /// </summary>
        /// <param name="imageFile">The image file to enhance</param>
        /// <returns>Enhanced image URL from OpenAI</returns>
        /// <remarks>
        /// Sample request:
        ///
        ///     POST /api/products/enhance-image
        ///     Content-Type: multipart/form-data
        ///     imageFile: [file]
        ///
        /// The endpoint uses OpenAI DALL-E 2 to enhance the image quality, lighting, colors, and overall appearance.
        /// Supports JPG, JPEG, PNG, and WebP formats (automatically converts to PNG for OpenAI processing).
        /// </remarks>
        [HttpPost("enhance-image")]
        [ProducesResponseType(typeof(EnhanceImageResponse), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public async Task<ActionResult<EnhanceImageResponse>> EnhanceImage(IFormFile imageFile)
        {
            try
            {
                if (imageFile == null || imageFile.Length == 0)
                {
                    return BadRequest(new EnhanceImageResponse
                    {
                        Success = false,
                        Error = "No image file provided"
                    });
                }

                // Validate file type
                var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                var fileExtension = Path.GetExtension(imageFile.FileName).ToLowerInvariant();

                if (!allowedExtensions.Contains(fileExtension))
                {
                    return BadRequest(new EnhanceImageResponse
                    {
                        Success = false,
                        Error = "Invalid file type. Only JPG, JPEG, PNG, and WebP images are supported."
                    });
                }

                // Save the uploaded image to enhance_images directory
                var uploadsPath = Path.Combine(_environment.WebRootPath, "uploads", "enhance_images");
                Directory.CreateDirectory(uploadsPath);

                // Always save as PNG for OpenAI compatibility
                var fileName = $"{Guid.NewGuid():N}.png";
                var filePath = Path.Combine(uploadsPath, fileName);
                var relativePath = $"uploads/enhance_images/{fileName}";

                // Convert image to PNG if necessary
                using (var inputStream = imageFile.OpenReadStream())
                {
                    using var image = await Image.LoadAsync(inputStream);
                    await image.SaveAsPngAsync(filePath);
                }

                _logger.LogInformation("Image uploaded and converted to PNG for AI enhancement: {FileName}", fileName);

                // Use OpenAI to enhance the image
                var enhancedImageUrl = await _openAIService.EnhanceImageAsync(relativePath);

                return Ok(new EnhanceImageResponse
                {
                    Success = true,
                    EnhancedImageUrl = enhancedImageUrl
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error enhancing image");
                return StatusCode(500, new EnhanceImageResponse
                {
                    Success = false,
                    Error = "Failed to enhance image. Please try again."
                });
            }
        }

        /// <summary>
        /// Deletes an uploaded image by its relative path
        /// </summary>
        /// <param name="imageUrl">The full URL of the image to delete</param>
        /// <returns>Success status</returns>
        /// <remarks>
        /// Sample request:
        ///
        ///     DELETE /api/products/delete-image?imageUrl=https://localhost:5001/uploads/original/image.jpg
        ///
        /// The endpoint accepts full URLs and extracts the relative path automatically.
        /// Supported directories: original, background_removal_images, enhance_images
        /// </remarks>
        [HttpDelete("delete-image")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status400BadRequest)]
        [ProducesResponseType(StatusCodes.Status404NotFound)]
        [ProducesResponseType(StatusCodes.Status500InternalServerError)]
        public IActionResult DeleteImage([FromQuery] string imageUrl)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(imageUrl))
                {
                    return BadRequest(new { success = false, error = "Image URL is required" });
                }

                // Extract relative path from full URL
                string relativePath;
                if (imageUrl.StartsWith("http://") || imageUrl.StartsWith("https://"))
                {
                    var uri = new Uri(imageUrl);
                    relativePath = uri.AbsolutePath.TrimStart('/');
                }
                else
                {
                    relativePath = imageUrl.TrimStart('/');
                }

                // Validate that the path is in an allowed directory
                var allowedDirectories = new[] { "uploads/original/", "uploads/background_removal_images/", "uploads/enhance_images/" };
                if (!allowedDirectories.Any(dir => relativePath.StartsWith(dir)))
                {
                    return BadRequest(new { success = false, error = "Invalid image path. Only images in uploads directories can be deleted." });
                }

                // Construct the full file path
                var filePath = Path.Combine(_environment.WebRootPath, relativePath);

                // Check if file exists
                if (!System.IO.File.Exists(filePath))
                {
                    return NotFound(new { success = false, error = "Image file not found" });
                }

                // Delete the file
                System.IO.File.Delete(filePath);

                _logger.LogInformation("Deleted image: {FilePath}", relativePath);

                return Ok(new { success = true, message = "Image deleted successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting image: {ImageUrl}", imageUrl);
                return StatusCode(500, new { success = false, error = "Failed to delete image. Please try again." });
            }
        }

        /// <summary>
        /// Health check endpoint
        /// </summary>
        [HttpGet("health")]
        [ProducesResponseType(StatusCodes.Status200OK)]
        public IActionResult Health()
        {
            return Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
        }
    }
}
