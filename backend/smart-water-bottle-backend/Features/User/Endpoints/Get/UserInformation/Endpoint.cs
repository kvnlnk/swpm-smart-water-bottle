using FastEndpoints;


namespace smart_water_bottle_backend.Features.User.Endpoints.Get.UserInformation;

public class Endpoint : EndpointWithoutRequest<Response>
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
        Get("api/user/information");
    }


    public override async Task HandleAsync(CancellationToken ct)
    {
        _logger.LogInformation("Handling request for user information");

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
            _logger.LogInformation("Return user information for user: {userId}", user.Id);
            await SendAsync(new Response
            {
                Id = user.Id,
                Email = user.Email,
                Username = user.Username,
                DailyGoalMl = user.DailyGoalMl,
                NotificationsEnabled = user.NotificationsEnabled,
                WeightKg = user.WeightKg,
                HeightCm = user.HeightCm
            }, 200, ct);
        }
        else
        {
            _logger.LogWarning("User with ID {UserId} not found in database", userId);
            await SendNotFoundAsync(ct);
        }
    }
}