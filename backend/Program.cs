using FastEndpoints;
using FastEndpoints.Security;
using FastEndpoints.Swagger; 

// Only load .env file from current directory if it exists 
// Use docker-compose environment variables
var isDocker = Environment.GetEnvironmentVariable("DOTNET_RUNNING_IN_CONTAINER") == "true";
if (!isDocker && File.Exists(".env"))
{
    DotNetEnv.Env.Load(".env");
}

var builder = WebApplication.CreateBuilder(args);

// Get variables from .env file
var url = Environment.GetEnvironmentVariable("SUPABASE_URL");
var anonKey = Environment.GetEnvironmentVariable("ANON_KEY");
var serviceRoleKey = Environment.GetEnvironmentVariable("SERVICE_ROLE_KEY");
var jwtSecret = Environment.GetEnvironmentVariable("JWT_SECRET");

// Check if configuration is missing
if (string.IsNullOrEmpty(url) || string.IsNullOrEmpty(anonKey) || string.IsNullOrEmpty(serviceRoleKey) || string.IsNullOrEmpty(jwtSecret))
{
    throw new InvalidOperationException("Supabase configuration is missing in .env or docker-compose environment variables");
}

// JWT Auth with FastEndpoints.Security
builder.Services.
    AddAuthenticationJwtBearer(s => s.SigningKey = jwtSecret)
    .AddAuthorization();

// FastEndpoints with Swagger
builder.Services.AddFastEndpoints();

builder.Services.SwaggerDocument(options =>
{
    options.DocumentSettings = settings =>
    {
        settings.Title = "SmartWaterBottle API Documentation";
        settings.Version = "v1";
    };
    options.EnableJWTBearerAuth = true;
});


// Register basic supabase client
builder.Services.AddSingleton<Supabase.Client>(provider =>
{
    var options = new Supabase.SupabaseOptions
    {
        AutoConnectRealtime = true
    };
    return new Supabase.Client(url, anonKey, options);
});


var app = builder.Build();

// Initialize supabase client
var supabaseClient = app.Services.GetRequiredService<Supabase.Client>();
await supabaseClient.InitializeAsync();

app.UseAuthentication()
    .UseAuthorization()
    .UseFastEndpoints()
    .UseSwaggerGen();

app.Run();