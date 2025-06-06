using System.Globalization;
using FastEndpoints;
using Supabase.Gotrue;

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


        _logger.LogInformation("Trying to sign in user with email: {Email}", req.Email);
        Session? authResponse;

        try
        {
            authResponse = await _supabase.Auth.SignIn(req.Email, req.Password);
        }
        catch
        {
            await SendUnauthorizedAsync(ct);
            return;
        }

        try
        {
            _logger.LogInformation("Creating JWT for user by logging in: {Email}", req.Email);
            string? jwtToken;
            if (authResponse?.AccessToken != null)
            {
                jwtToken = authResponse.AccessToken;
                _logger.LogInformation("Login successful for {Email}", req.Email);
            }
            else
            {
                _logger.LogWarning("Login failed - no valid session for {Email}", req.Email);
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