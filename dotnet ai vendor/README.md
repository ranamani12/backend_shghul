# Vendor Dashboard API

A stateless RESTful API for AI-powered product generation and image processing. This API provides endpoints for generating product descriptions, creating product images, removing backgrounds, and enhancing images using AI services.

## Features

- **AI Product Generation**: Generate product descriptions and images using OpenAI GPT-4o-mini and DALL-E 3
- **Background Removal**: Remove backgrounds from product images using Remove.bg API
- **Image Enhancement**: AI-powered image enhancement for products
- **Bilingual Support**: Generate content in English or Arabic
- **Stateless Design**: No database required - perfect for microservices architecture
- **CORS Enabled**: Use from any frontend application
- **Swagger Documentation**: Interactive API documentation at root URL

## Prerequisites

- .NET 9.0 SDK
- OpenAI API Key
- Remove.bg API Key (optional, for background removal)

## Installation

1. Clone the repository
2. Navigate to the project directory
3. Restore dependencies:
```bash
dotnet restore
```

4. Configure your API keys in `appsettings.json` or create a `.env` file:
```env
OPENAI_API_KEY=your_openai_api_key
REMOVEBG_API_KEY=your_removebg_api_key
```

## Running the API

```bash
dotnet run
```

The API will start at:
- HTTPS: `https://localhost:5001`
- HTTP: `http://localhost:5000`

Swagger documentation is available at the root URL: `https://localhost:5001`

## API Endpoints

### 1. Generate Product Content
**POST** `/api/products/generate`

Generates AI-powered product descriptions in both English and Arabic, with optional image generation.

**Request Body:**
```json
{
  "productName": "Wireless Bluetooth Headphones",
  "additionalDetails": "Premium quality with noise cancellation",
  "generateImage": true
}
```

**Parameters:**
- `productName` (required): Name of the product
- `additionalDetails` (optional): Additional product details
- `generateImage` (optional, default: true): Set to `false` to skip image generation

**Response:**
```json
{
  "success": true,
  "descriptionEnglish": "High-quality wireless Bluetooth headphones with premium sound...",
  "descriptionArabic": "سماعات بلوتوث لاسلكية عالية الجودة مع صوت متميز...",
  "imageUrl": "https://generated-image-url.com/image.png",
  "error": null
}
```

**Note:** Descriptions are always generated in both languages. Set `generateImage: false` to get faster responses without image generation (imageUrl will be null).

### 2. Remove Background
**POST** `/api/products/remove-background`

Removes background from uploaded image.

**Request:** `multipart/form-data`
- `imageFile`: Image file (JPG, PNG, or WebP)

**Response:**
```json
{
  "success": true,
  "processedImageUrl": "/uploads/enhanced/image.png",
  "originalImageUrl": "/uploads/original/image.jpg",
  "error": null
}
```

### 3. Enhance Image
**POST** `/api/products/enhance-image`

Enhances uploaded image using AI.

**Request:** `multipart/form-data`
- `imageFile`: Image file
- `productName`: Product name for context

**Response:**
```json
{
  "success": true,
  "enhancedImageUrl": "https://enhanced-image-url.com/image.png",
  "error": null
}
```

### 4. Health Check
**GET** `/api/products/health`

Check API health status.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Configuration

### appsettings.json

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "OpenAI": {
    "ApiKey": "your_api_key_here"
  },
  "RemoveBg": {
    "ApiKey": "your_api_key_here"
  }
}
```

### Environment Variables

Alternatively, use environment variables or a `.env` file:
- `OPENAI_API_KEY`
- `REMOVEBG_API_KEY`

## CORS Configuration

The API is configured to allow requests from any origin. To restrict access to specific domains, modify the CORS policy in `Program.cs`:

```csharp
options.AddPolicy("AllowAll", policy =>
{
    policy.WithOrigins("https://yourdomain.com")
          .AllowAnyMethod()
          .AllowAnyHeader();
});
```

## Usage Examples

### JavaScript/Fetch

```javascript
// Generate Product with Image
const response = await fetch('https://localhost:5001/api/products/generate', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    productName: 'Gaming Mouse',
    additionalDetails: 'RGB lighting, ergonomic design',
    generateImage: true
  })
});

const data = await response.json();
console.log('English:', data.descriptionEnglish);
console.log('Arabic:', data.descriptionArabic);
console.log('Image:', data.imageUrl);

// Generate Product without Image (faster)
const response2 = await fetch('https://localhost:5001/api/products/generate', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    productName: 'Gaming Mouse',
    additionalDetails: 'RGB lighting, ergonomic design',
    generateImage: false
  })
});

const data2 = await response2.json();
console.log('English:', data2.descriptionEnglish);
console.log('Arabic:', data2.descriptionArabic);
// data2.imageUrl will be null
```

### cURL

```bash
# Generate Product with Image
curl -X POST https://localhost:5001/api/products/generate \
  -H "Content-Type: application/json" \
  -d '{
    "productName": "Gaming Mouse",
    "additionalDetails": "RGB lighting",
    "generateImage": true
  }'

# Generate Product without Image
curl -X POST https://localhost:5001/api/products/generate \
  -H "Content-Type: application/json" \
  -d '{
    "productName": "Gaming Mouse",
    "additionalDetails": "RGB lighting",
    "generateImage": false
  }'

# Remove Background
curl -X POST https://localhost:5001/api/products/remove-background \
  -F "imageFile=@/path/to/image.jpg"
```

### C# HttpClient

```csharp
using var client = new HttpClient();
var request = new
{
    ProductName = "Gaming Mouse",
    AdditionalDetails = "RGB lighting",
    GenerateImage = true
};

var response = await client.PostAsJsonAsync(
    "https://localhost:5001/api/products/generate",
    request
);

var result = await response.Content.ReadFromJsonAsync<GenerateProductResponse>();
Console.WriteLine($"English: {result.DescriptionEnglish}");
Console.WriteLine($"Arabic: {result.DescriptionArabic}");
Console.WriteLine($"Image: {result.ImageUrl}");
```

## Architecture

- **Controllers**: REST API endpoints (`ProductsController`)
- **Services**: Business logic for AI and image processing
  - `OpenAIService`: GPT-4o-mini and DALL-E 3 integration
  - `BackgroundRemovalService`: Remove.bg API integration
- **DTOs**: Request/Response data transfer objects
- **Stateless**: No database - all operations are transient

## Dependencies

- **OpenAI SDK** (v2.0.0): AI generation
- **DotNetEnv** (v3.0.0): Environment variable management
- **Swashbuckle.AspNetCore** (v6.5.0): Swagger/OpenAPI documentation

## Error Handling

All endpoints return consistent error responses:

```json
{
  "success": false,
  "error": "Error message description"
}
```

HTTP Status Codes:
- `200 OK`: Successful operation
- `400 Bad Request`: Invalid request data
- `500 Internal Server Error`: Server-side error

## Development

### Building

```bash
dotnet build
```

### Running Tests

```bash
dotnet test
```

### Publishing

```bash
dotnet publish -c Release -o ./publish
```

## Deployment

This API can be deployed to:
- Azure App Service
- AWS Elastic Beanstalk
- Docker containers
- Any .NET 9.0 compatible hosting environment

## License

MIT License

## Support

For issues and questions, please create an issue in the repository.


### 2. Generate Promotional Content for Kuwait Market
**POST** `/api/promotions/generate`

Creates high-performing social media copy (English & Arabic) and optional imagery tailored to the Kuwait retail market.

**Request Body:**
```json
{
  "storeType": "Grocery Store",
  "productCategory": "Organic Fruits",
  "productName": "Premium Kuwaiti Dates",
  "productPrice": 5.500,
  "targetAudience": "Health-conscious families",
  "sellingPoint": "Freshly harvested, rich in nutrients",
  "campaignObjective": "Drive weekend footfall",
  "brandTone": "luxury",
  "generateCopy": true,
  "generateImage": true,
  "existingImageUrl": null
}
```

**Key Flags:**
- `generateCopy` – When `true`, the API returns persuasive copy in English and Arabic.
- `generateImage` – When `true`, the API generates an AI-powered promotional image.
- `existingImageUrl` – Provide your own image URL; set `generateImage` to `false` to reuse it.

**Response Example:**
```json
{
  "success": true,
  "message": "Promotional assets generated successfully.",
  "promotionalCopy": {
    "english": "Experience the finest Kuwaiti dates ...",
    "arabic": "استمتع بأفضل أنواع التمر الكويتي ..."
  },
  "imageUrl": "https://generated-image-url.com/promo.png",
  "metadata": {
    "storeType": "Grocery Store",
    "productCategory": "Organic Fruits",
    "productName": "Premium Kuwaiti Dates",
    "productPrice": 5.5,
    "copyGenerated": true,
    "imageGenerated": true,
    "generatedAtUtc": "2025-11-10T09:21:34.000Z"
  }
}
```

> ℹ️ The API automatically factors in Kuwait-specific cultural cues, shopping behaviour, and buyer psychology to craft high-conversion assets.


