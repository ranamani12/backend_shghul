using VendorDashboard.Models;
using VendorDashboard.Services;
using DotNetEnv;

var builder = WebApplication.CreateBuilder(args);

// Load .env file if it exists
if (File.Exists(".env"))
{
    Env.Load();
}

// Configure BASE_URL from environment or configuration
var baseUrl = Environment.GetEnvironmentVariable("BASE_URL")
              ?? builder.Configuration["BaseUrl"]
              ?? "https://localhost:5001";
builder.Services.AddSingleton(new BaseUrlConfiguration { BaseUrl = baseUrl });

// Add services to the container
builder.Services.AddControllers();

// Add API Explorer for Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new Microsoft.OpenApi.Models.OpenApiInfo
    {
        Title = "Vendor Dashboard API",
        Version = "v1",
        Description = "AI-powered product generation API with image processing capabilities",
        Contact = new Microsoft.OpenApi.Models.OpenApiContact
        {
            Name = "Vendor Dashboard",
            Email = "support@vendordashboard.com"
        }
    });

    // Enable annotations
    options.EnableAnnotations();

    // Include XML comments if available
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

// Configure CORS to allow multiple projects to use this API
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

// Register OpenAI Service
builder.Services.AddScoped<IOpenAIService, OpenAIService>();

// Register Background Removal Service
builder.Services.AddScoped<IBackgroundRemovalService, BackgroundRemovalService>();

// Add logging
builder.Services.AddLogging(logging =>
{
    logging.AddConsole();
    logging.AddDebug();
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "Vendor Dashboard API v1");
        options.RoutePrefix = string.Empty; // Serve Swagger UI at root
    });
    app.UseDeveloperExceptionPage();
}

app.UseHttpsRedirection();

// Enable CORS
app.UseCors("AllowAll");

// Serve static files for uploaded images
app.UseStaticFiles();

app.UseAuthorization();

app.MapControllers();

app.Run();
