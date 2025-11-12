using OpenAI.Images;

namespace VendorDashboard.Services
{
    public class BackgroundRemovalService : IBackgroundRemovalService
    {
        private readonly string _apiKey;
        private readonly string? _removeBgApiKey;
        private readonly ILogger<BackgroundRemovalService> _logger;
        private readonly IWebHostEnvironment _environment;

        public BackgroundRemovalService(IConfiguration configuration, ILogger<BackgroundRemovalService> logger, IWebHostEnvironment environment)
        {
            _apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY") 
                      ?? configuration["OpenAI:ApiKey"] 
                      ?? throw new InvalidOperationException("OpenAI API key not found");
            _removeBgApiKey = Environment.GetEnvironmentVariable("REMOVEBG_API_KEY") 
                             ?? configuration["RemoveBg:ApiKey"];
            _logger = logger;
            _environment = environment;
        }

        public async Task<string> RemoveBackgroundAndEnhanceAsync(string imagePath, string productName)
        {
            try
            {
                // Read the uploaded image
                var fullPath = Path.Combine(_environment.WebRootPath, imagePath.TrimStart('/'));
                
                if (!File.Exists(fullPath))
                {
                    _logger.LogWarning("Image file not found: {Path}", fullPath);
                    return imagePath;
                }

                // Convert image to base64 for API
                byte[] imageBytes = await File.ReadAllBytesAsync(fullPath);
                
                // Check if Remove.bg API key is configured
                if (!string.IsNullOrEmpty(_removeBgApiKey) && _removeBgApiKey != "your-remove-bg-api-key-here")
                {
                    try
                    {
                        _logger.LogInformation("Removing background using Remove.bg API for {ProductName}", productName);
                        
                        using var client = new HttpClient();
                        client.DefaultRequestHeaders.Add("X-Api-Key", _removeBgApiKey);
                        
                        var formData = new MultipartFormDataContent();
                        formData.Add(new ByteArrayContent(imageBytes), "image_file", Path.GetFileName(fullPath));
                        formData.Add(new StringContent("auto"), "size");
                        
                        var response = await client.PostAsync("https://api.remove.bg/v1.0/removebg", formData);
                        
                        if (response.IsSuccessStatusCode)
                        {
                            var resultBytes = await response.Content.ReadAsByteArrayAsync();
                            
                            // Save the background-removed image
                            var uploadsPath = Path.Combine(_environment.WebRootPath, "uploads", "background_removal_images");
                            Directory.CreateDirectory(uploadsPath);

                            var fileName = $"{productName.Replace(" ", "_")}_{Guid.NewGuid():N}.png";
                            var filePath = Path.Combine(uploadsPath, fileName);

                            await File.WriteAllBytesAsync(filePath, resultBytes);

                            _logger.LogInformation("Background removed successfully for {ProductName}", productName);
                            return $"uploads/background_removal_images/{fileName}";
                        }
                        else
                        {
                            var errorContent = await response.Content.ReadAsStringAsync();
                            _logger.LogWarning("Remove.bg API failed: {StatusCode} - {Error}", response.StatusCode, errorContent);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error calling Remove.bg API");
                    }
                }
                
                // If Remove.bg is not configured or failed, return the original image
                _logger.LogInformation("Remove.bg API not configured or failed. Returning original image for {ProductName}", productName);
                _logger.LogInformation("To enable background removal, get a FREE API key from https://remove.bg/api and add it to appsettings.json or environment variables");
                
                return imagePath;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing background and enhancing image for {ProductName}", productName);
                
                // Fallback: return the original image path
                return imagePath;
            }
        }

        private async Task<string> SaveEnhancedImageAsync(string imageUrl, string productName)
        {
            try
            {
                using var httpClient = new HttpClient();
                var imageBytes = await httpClient.GetByteArrayAsync(imageUrl);
                
                var uploadsPath = Path.Combine(_environment.WebRootPath, "uploads", "background_removal_images");
                Directory.CreateDirectory(uploadsPath);

                var fileName = $"{productName.Replace(" ", "_")}_{Guid.NewGuid():N}.png";
                var filePath = Path.Combine(uploadsPath, fileName);

                await File.WriteAllBytesAsync(filePath, imageBytes);

                return $"uploads/background_removal_images/{fileName}";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error saving enhanced image");
                throw;
            }
        }
    }
}
