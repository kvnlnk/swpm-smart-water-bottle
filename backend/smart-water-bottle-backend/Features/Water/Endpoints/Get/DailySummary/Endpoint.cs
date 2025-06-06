using FastEndpoints;

namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.DailySummary;

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
        Get("api/water/daily-summary");
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        _logger.LogInformation("Handling request to get today's drinking history");
        var userId = User.FindFirst("sub")?.Value;

        if (userId == null)
        {
            _logger.LogInformation("User ID claim not found in JWT");
            await SendUnauthorizedAsync(ct);
            return;
        }

        var today = DateOnly.FromDateTime(DateTime.Today);
        _logger.LogInformation("Retrieving daily summary for {Date}", today.ToString("yyyy-MM-dd"));

        var dailySummary = await _supabase
            .From<Entities.DailySummary>()
            .Where(x => x.UserId == userId)
            .Where(x => x.Date == today)
            .Limit(1)
            .Get(cancellationToken: ct);

        if (dailySummary.Model != null)
        {
            var summary = dailySummary.Models.First();
            _logger.LogInformation("Found daily summary for {Date}", today);

            var response = new Response
            {
                Date = today,
                TotalAmountMl = summary.TotalConsumedMl,
                GoalAmountMl = summary.GoalMl,
                PercentageAchieved = summary.GoalMl > 0
                    ? (int)((double)summary.TotalConsumedMl / summary.GoalMl * 100)
                    : 0,
                DrinkCount = summary.DrinkCount,
                IsGoalReached = summary.GoalAchieved
            };

            await SendOkAsync(response, ct);
        }
        else
        {
            _logger.LogWarning("No water history data found for user with ID {UserId}", userId);
            var user = await _supabase
                .From<Entities.User>()
                .Where(x => x.Id == userId)
                .Single(ct);

            if (user != null)
            {
                await SendAsync(new Response
                {
                    Date = today,
                    TotalAmountMl = 0,
                    GoalAmountMl = user.DailyGoalMl,
                    PercentageAchieved = 0,
                    DrinkCount = 0,
                    IsGoalReached = false
                }, 200, ct);
            }
            else
            {
                _logger.LogWarning("User with ID {UserId} not found in database", userId);
                await SendNotFoundAsync(ct);
            }
        }
    }
}