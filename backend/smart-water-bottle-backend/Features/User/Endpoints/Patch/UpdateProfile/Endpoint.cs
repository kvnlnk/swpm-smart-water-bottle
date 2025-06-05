using FastEndpoints;
using Supabase.Gotrue;

namespace smart_water_bottle_backend.Features.User.Endpoints.Patch.UpdateProfile;

public class Endpoint : Endpoint<Request>
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
        Patch("api/user/profile/update");
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        _logger.LogInformation("Handling request to update user information");
        var userId = User.FindFirst("sub")?.Value;

        if (userId == null)
        {
            _logger.LogInformation("User ID claim not found in JWT");
            await SendUnauthorizedAsync(ct);
            return;
        }

        _logger.LogInformation("Retrieve user information for user: {userId}", userId);

        var user = await _supabase
            .From<Entities.User>()
            .Where(x => x.Id == userId)
            .Single(ct);

        if (user != null)
        {
            try
            {
                _logger.LogInformation("Update user information for user: {userId}", user.Id);
                
                UpdateUserProperties(user, req);
                var test = await user.Update<Entities.User>(ct);
                
                _logger.LogInformation("Successfully updated user profile for user: {userId}", test);
                await SendOkAsync(ct);
            }
            catch (Exception ex)
            {
                _logger.LogError("Failed to update user profile for user: {userId}", ex);
                await SendErrorsAsync(500,ct);
            }
        }
        else
        {
            _logger.LogWarning("User with ID {UserId} not found in database", userId);
            await SendNotFoundAsync(ct);
        }

    }


    private void UpdateUserProperties(Entities.User user, Request request)
    {
        try
        {
            _logger.LogDebug("Starting property update for user entity");

            foreach (var prop in request.GetType().GetProperties())
            {
                var value = prop.GetValue(request);
                if (value != null)
                {
                    var userProp = typeof(Entities.User).GetProperty(prop.Name);
                    if (userProp != null && userProp.CanWrite)
                    {
                        userProp.SetValue(user, value);
                    }
                }
            }
        }
        catch (Exception ex)
        {
            // Re-throw error to be handled by calling method
            _logger.LogError(ex, "Critical error during property update process");
            throw; 
        }
    }
}