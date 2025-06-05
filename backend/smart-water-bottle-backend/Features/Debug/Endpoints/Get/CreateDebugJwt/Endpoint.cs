using System.Globalization;
using FastEndpoints;
using FastEndpoints.Security;
using smart_water_bottle_backend.Entities;

namespace smart_water_bottle_backend.Features.Debug.Endpoints.Get.CreateDebugJWT;

public class Endpoint : Endpoint<Request, Response>
{
    private readonly Supabase.Client _supabase;
    private readonly ILogger<Endpoint> _logger;

    public Endpoint(Supabase.Client supabase, ILogger<Endpoint> logger)
    {
        _supabase = supabase;
        _logger = logger;
    }

    public override void Configure()
    {
        Get("api/auth/getJWT");
        AllowAnonymous();
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        _logger.LogInformation("JWT request for email: {Email}", req.Email);

        if (string.IsNullOrWhiteSpace(req.Email))
        {
            await SendErrorsAsync(400, ct);
            return;
        }

        _logger.LogInformation("Retrieve user with email: {Email}", req.Email);
        var user = await _supabase
            .From<User>()
            .Where(x => x.Email == req.Email)
            .Single(ct);

        if (user != null)
        {
            try
            {
                _logger.LogInformation("Creating JWT for user with id: {Id}", user.Id);
                var jwtToken = JwtBearer.CreateToken(options =>
                {
                    options.SigningKey = Environment.GetEnvironmentVariable("JWT_SECRET")!;
                    options.ExpireAt = DateTime.UtcNow.AddDays(1);
                    options.User.Claims.Add(("UserId", user.Id));
                    options.User.Roles.Add("Role", user.Role);
                    options.User.Claims.Add(("Username", user.Username ?? ""));
                    options.User.Claims.Add(("Email", user.Email ?? ""));
                });
                
                _logger.LogInformation("Sending response with JWT...");
                await SendOkAsync(new Response
                {
                    Token = jwtToken,
                    ExpiresAt = DateTime.UtcNow.AddDays(1).ToString(CultureInfo.InvariantCulture)
                }, ct);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "JWT creation error for user: {UserId}", user.Id);
            }
        }
        else
        {
            _logger.LogWarning("User with email: {Email} not found", req.Email);
            await SendNotFoundAsync(ct);
        }
    }
}