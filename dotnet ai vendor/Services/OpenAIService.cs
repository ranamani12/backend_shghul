using OpenAI.Chat;
using OpenAI.Images;
using System.ClientModel;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Png;
using SixLabors.ImageSharp.Processing;
using VendorDashboard.Models;

namespace VendorDashboard.Services
{
    public class OpenAIService : IOpenAIService
    {
        private readonly string _apiKey;
        private readonly ILogger<OpenAIService> _logger;
        private readonly IWebHostEnvironment _environment;

        public OpenAIService(IConfiguration configuration, ILogger<OpenAIService> logger, IWebHostEnvironment environment)
        {
            _apiKey = Environment.GetEnvironmentVariable("OPENAI_API_KEY")
                      ?? configuration["OpenAI:ApiKey"]
                      ?? throw new InvalidOperationException("OpenAI API key not found");
            _logger = logger;
            _environment = environment;
        }

        public async Task<string> GenerateProductDescriptionAsync(string productName, string? additionalDetails = null, string language = "en")
        {
            try
            {
                var chatClient = new ChatClient("gpt-4o-mini", _apiKey);

                var languageInstruction = language == "ar" ? "Write the description in Arabic language." : "Write the description in English language.";
                var detailsContext = !string.IsNullOrEmpty(additionalDetails) ? $" Additional context: {additionalDetails}" : "";

                var prompt = $"Write a compelling and detailed product description for '{productName}'. {languageInstruction} " +
                           $"The description should be professional, highlight key features and benefits, " +
                           $"and be suitable for an e-commerce platform. Keep it between 100-150 words.{detailsContext}";

                var completion = await chatClient.CompleteChatAsync(prompt);

                return completion.Value.Content[0].Text;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating product description for {ProductName}", productName);

                return GenerateSmartFallbackDescription(productName, additionalDetails, language);
            }
        }

        private string GenerateSmartFallbackDescription(string productName, string? additionalDetails = null, string language = "en")
        {
            var product = productName.ToLower();

            if (language == "ar")
            {
                return product switch
                {
                    var p when p.Contains("mango") => "مانجو طازج وعصيري مليء بالحلاوة الاستوائية. هذه المانجو المتميزة مختارة يدوياً لنضجها المثالي ونكهتها الاستثنائية. غنية بفيتامين أ وسي، مما يجعلها وجبة خفيفة صحية ممتازة أو إضافة رائعة للعصائر والحلويات وسلطات الفواكه.",
                    var p when p.Contains("phone") || p.Contains("smartphone") => "هاتف ذكي متقدم يتميز بتقنية حديثة وتصميم أنيق. مجهز بكاميرا عالية الدقة ومعالج قوي وبطارية تدوم طويلاً. مثالي للتواصل والتصوير والترفيه والإنتاجية.",
                    var p when p.Contains("laptop") || p.Contains("computer") => "جهاز كمبيوتر محمول عالي الأداء مصمم للإنتاجية والترفيه. يتميز بقوة معالجة سريعة وشاشة واضحة وبطارية تدوم طوال اليوم.",
                    _ => $"منتج عالي الجودة {productName} مختار بعناية لمواصفاته الاستثنائية وموثوقيته. مصمم لتلبية احتياجاتك مع حرفية فائقة واهتمام بالتفاصيل."
                };
            }

            return product switch
            {
                var p when p.Contains("mango") => "Fresh, juicy mangoes bursting with tropical sweetness. These premium mangoes are hand-selected for their perfect ripeness and exceptional flavor. Rich in vitamins A and C, they make an excellent healthy snack or addition to smoothies, desserts, and fruit salads. Experience the taste of sunshine with every bite of these delicious mangoes.",
                var p when p.Contains("apple") => "Crisp, refreshing apples with a perfect balance of sweetness and tartness. These premium apples are carefully selected for their firm texture and natural flavor. Packed with fiber, antioxidants, and vitamin C, they make an ideal healthy snack for any time of day. Perfect for eating fresh, baking, or adding to your favorite recipes.",
                var p when p.Contains("phone") || p.Contains("smartphone") => "Advanced smartphone featuring cutting-edge technology and sleek design. Equipped with high-resolution camera, powerful processor, and long-lasting battery life. Perfect for communication, photography, entertainment, and productivity. Experience seamless connectivity and premium performance in your daily life.",
                var p when p.Contains("laptop") || p.Contains("computer") => "High-performance laptop designed for productivity and entertainment. Features fast processing power, crisp display, and all-day battery life. Perfect for work, gaming, creative projects, and everyday computing needs. Built with quality components for reliable performance and durability.",
                var p when p.Contains("headphone") || p.Contains("earphone") => "Premium wireless headphones delivering crystal-clear audio and comfortable fit. Features noise cancellation, long battery life, and seamless connectivity. Perfect for music lovers, professionals, and anyone who appreciates high-quality sound. Experience immersive audio with superior comfort.",
                var p when p.Contains("watch") || p.Contains("smartwatch") => "Smart wearable device that combines style with functionality. Features fitness tracking, notifications, and health monitoring capabilities. Water-resistant design with customizable faces and bands. Stay connected and motivated with this advanced timepiece.",
                var p when p.Contains("coffee") || p.Contains("mug") => "Premium coffee blend with rich aroma and smooth taste. Carefully sourced beans roasted to perfection for an exceptional coffee experience. Perfect for morning routines, afternoon breaks, or anytime you need a quality caffeine boost. Enjoy the finest coffee in the comfort of your home.",
                var p when p.Contains("shoes") || p.Contains("sneaker") => "Comfortable and stylish footwear designed for all-day wear. Features cushioned sole, breathable materials, and modern design. Perfect for casual outings, light exercise, or everyday activities. Step out in confidence with these quality shoes.",
                _ => $"Premium quality {productName} carefully selected for its exceptional features and reliability. Designed to meet your needs with superior craftsmanship and attention to detail. Perfect for everyday use and long-lasting performance. Experience the difference that quality makes."
            };
        }

        public async Task<string> GenerateProductImageAsync(string productName, string? additionalDetails = null)
        {
            try
            {
                var imageClient = new ImageClient("dall-e-3", _apiKey);

                var detailsContext = !string.IsNullOrEmpty(additionalDetails) ? $" {additionalDetails}" : "";
                var prompt = $"A professional, high-quality product photo of {productName} on a clean white background, " +
                           $"well-lit, commercial photography style, 4K quality, perfect for e-commerce{detailsContext}";

                var imageGeneration = await imageClient.GenerateImageAsync(
                    prompt,
                    new ImageGenerationOptions()
                    {
                        Size = GeneratedImageSize.W1024xH1024,
                        Quality = GeneratedImageQuality.Standard
                    });

                return imageGeneration.Value.ImageUri.ToString();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating product image for {ProductName}", productName);

                var seed = $"{productName}_{additionalDetails}".Replace(" ", "_");
                return $"https://picsum.photos/seed/{seed}/1024/1024";
            }
        }

        public async Task<string> EnhanceImageAsync(string imagePath)
        {
            try
            {
                _logger.LogInformation("Enhancing image: {ImagePath}", imagePath);

                var fullPath = Path.Combine(_environment.WebRootPath, imagePath.TrimStart('/'));

                if (!File.Exists(fullPath))
                {
                    _logger.LogWarning("Image file not found: {Path}", fullPath);
                    throw new FileNotFoundException("Image file not found", fullPath);
                }

                using var originalImage = await Image.LoadAsync(fullPath);

                int targetSize = 1024;
                using var rgbaImage = new Image<SixLabors.ImageSharp.PixelFormats.Rgba32>(targetSize, targetSize);

                var ratio = Math.Min((float)targetSize / originalImage.Width, (float)targetSize / originalImage.Height);
                var newWidth = (int)(originalImage.Width * ratio);
                var newHeight = (int)(originalImage.Height * ratio);

                originalImage.Mutate(ctx => ctx.Resize(newWidth, newHeight));

                var xPos = (targetSize - newWidth) / 2;
                var yPos = (targetSize - newHeight) / 2;

                rgbaImage.Mutate(ctx =>
                {
                    ctx.DrawImage(originalImage, new Point(xPos, yPos), 1f);
                });

                using var imageStream = new MemoryStream();
                await rgbaImage.SaveAsPngAsync(imageStream);
                imageStream.Position = 0;

                var imageClient = new ImageClient("dall-e-2", _apiKey);

                var prompt = "A professional, high-quality, vibrant product photo with perfect lighting, sharp details, and appealing colors, ideal for e-commerce";

                _logger.LogInformation("Sending image to OpenAI for enhancement");

                var result = await imageClient.GenerateImageEditAsync(
                    imageStream,
                    "product.png",
                    prompt,
                    new ImageEditOptions
                    {
                        Size = GeneratedImageSize.W1024xH1024,
                        ResponseFormat = GeneratedImageFormat.Uri
                    });

                var enhancedImageUrl = result.Value.ImageUri.ToString();

                _logger.LogInformation("Image enhanced successfully via OpenAI: {Url}", enhancedImageUrl);
                return enhancedImageUrl;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error enhancing image: {ErrorMessage}. Details: {Details}",
                    ex.Message, ex.InnerException?.Message ?? "No additional details");
                throw;
            }
        }

        public async Task<string> GeneratePromotionalTextAsync(PromotionalContentContext context, string language)
        {
            try
            {
                var chatClient = new ChatClient("gpt-4o-mini", _apiKey);

                var priceFragment = context.ProductPrice.HasValue
                    ? $"The price is {context.ProductPrice:0.###} Kuwaiti Dinars (KWD)."
                    : string.Empty;

                var languageInstruction = language.Equals("ar", StringComparison.OrdinalIgnoreCase)
                    ? "Write the copy in Arabic using Modern Standard Arabic that resonates with Kuwaiti shoppers."
                    : "Write the copy in English tailored to Kuwaiti shoppers.";

                var tone = string.IsNullOrWhiteSpace(context.BrandTone)
                    ? "Maintain an energetic yet authentic marketing tone suitable for social media platforms."
                    : $"Adopt a {context.BrandTone} marketing tone.";

                var prompt = $@"
You are a senior marketing strategist specialised in the Kuwait retail market. Craft a high-converting social media promotion.

Store type: {context.StoreType}
Product category: {context.ProductCategory}
Product name: {context.ProductName ?? "Not specified"}
{priceFragment}
Target audience: {context.TargetAudience ?? "Families and residents in Kuwait"}
Key selling point: {context.SellingPoint ?? "Highlight value, quality and local relevance."}
Campaign objective: {context.CampaignObjective ?? "Drive in-store and online purchases."}
Additional product details: {context.ProductDescription ?? "None"}

Requirements:
- Base all references on Kuwaiti consumer preferences, culture and shopping behaviour.
- Provide a persuasive hook, key benefits, and a strong call-to-action optimised for Kuwait (mention convenience, local delivery, or seasonal cues when appropriate).
- Keep the copy between 80 and 120 words.
- Make the copy platform-agnostic so it can be used on Instagram, Snapchat, TikTok, or Twitter.
- Avoid emojis unless they strongly enhance the message.

Language directive: {languageInstruction}
Tone directive: {tone}
Return only the promotional text without additional commentary.".Trim();

                var completion = await chatClient.CompleteChatAsync(prompt);
                return completion.Value.Content[0].Text.Trim();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating promotional copy for {StoreType}/{Category}", context.StoreType, context.ProductCategory);

                return language.Equals("ar", StringComparison.OrdinalIgnoreCase)
                    ? "اكتشف عرضنا الخاص في الكويت! منتجاتنا المختارة بعناية تجمع بين الجودة العالية والسعر المنافس لتلبية احتياجاتك اليومية. استفد الآن من العرض لفترة محدودة وقم بزيارة متجرنا أو اطلب عبر الإنترنت لتوصيل سريع داخل الكويت."
                    : "Discover our Kuwait-exclusive promotion! Enjoy premium quality and unbeatable value designed for your everyday needs. Limited-time offer—visit us in-store or order online for fast delivery across Kuwait.";
            }
        }

        public async Task<string> GeneratePromotionalImageAsync(PromotionalContentContext context)
        {
            try
            {
                var imageClient = new ImageClient("dall-e-3", _apiKey);

                var priceFragment = context.ProductPrice.HasValue
                    ? $"Display price tag showing {context.ProductPrice:0.###} KWD in an elegant style."
                    : string.Empty;

                var prompt = $"""
A vibrant, high-quality promotional photo for social media representing a {context.StoreType} in Kuwait.
Focus on {context.ProductCategory}{(string.IsNullOrWhiteSpace(context.ProductName) ? string.Empty : $", featuring {context.ProductName}")}.
Highlight modern Kuwaiti aesthetics, warm lighting, Gulf-inspired decor elements, and lifestyle appeal.
Include subtle Arabic typography accents suggesting a special offer. {priceFragment}
Aspect ratio square, 4K resolution, commercial photography, hero product centered, clean composition.
""";

                var options = new ImageGenerationOptions
                {
                    Size = GeneratedImageSize.W1024xH1024,
                    Quality = GeneratedImageQuality.Standard
                };

                var result = await imageClient.GenerateImageAsync(prompt, options);
                return result.Value.ImageUri.ToString();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating promotional image for {StoreType}/{Category}", context.StoreType, context.ProductCategory);
                var seed = $"promo_{context.StoreType}_{context.ProductCategory}".Replace(" ", "_");
                return $"https://picsum.photos/seed/{seed}/1024/1024";
            }
        }
    }
}
