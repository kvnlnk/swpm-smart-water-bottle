using System.Globalization;
using FastEndpoints;
using FastEndpoints.Security;

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

        try
        {
            string? jwtToken = null;
            _logger.LogInformation("Creating JWT for user by logging in: {Email}", req.Email);
            var authResponse = await _supabase.Auth.SignIn(req.Email, req.Password);
            if (authResponse != null)
            {
                jwtToken = authResponse.AccessToken;
            }
            else
            {
                await SendUnauthorizedAsync(ct);
                return;
            }

            _logger.LogInformation("Sending response with JWT...");
            await SendOkAsync(new Response
            {
                Token = jwtToken,
                ExpiresAt = DateTime.UtcNow.AddDays(1).ToString(CultureInfo.InvariantCulture)
            }, ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "JWT creation error for user: {Email}", req.Email);
        }
    }
}