using FastEndpoints;

namespace smart_water_bottle_backend.Features.Water.Endpoints.Post.LogDrinking;

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
        Post("api/water/log-drinking");
    }

    public override async Task HandleAsync(Request req, CancellationToken ct)
    {
        _logger.LogInformation("Handling request to log drinking");
        var userId = User.FindFirst("sub")?.Value;

        if (userId == null)
        {
            _logger.LogInformation("User ID claim not found in JWT");
            await SendUnauthorizedAsync(ct);
            return;
        }

        if (req.AmountMl <= 0)
        {
            _logger.LogWarning("Invalid amount: {Amount}ml", req.AmountMl);
            await SendAsync(new Response
            {
                Success = false,
                Message = "Amount must be greater than 0"
            }, 400, ct);
            return;
        }

        try
        {
            _logger.LogInformation("Logging {Amount}ml for user {UserId}", req.AmountMl, userId);

            var drinkingData = new Entities.DrinkingData
            {
                UserId = userId,
                AmountMl = req.AmountMl,
                CreatedAt = req.Timestamp
            };

            var result = await _supabase
                .From<Entities.DrinkingData>()
                .Insert(drinkingData, cancellationToken: ct);

            if (result.Model != null)
            {
                _logger.LogInformation("Successfully logged drinking data with ID {Id}", result.Model.Id);

                await UpdateDailySummaryAsync(userId, req.AmountMl, ct);

                var response = new Response
                {
                    Id = result.Model.Id,
                    Success = true,
                    Message = $"Successfully logged {req.AmountMl}ml"
                };

                await SendOkAsync(response, ct);
            }
            else
            {
                _logger.LogError("Failed to insert drinking data");
                await SendAsync(new Response
                {
                    Success = false,
                    Message = "Failed to log drinking data"
                }, 500, ct);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error logging drinking data for user {UserId}", userId);
            await SendAsync(new Response
            {
                Success = false,
                Message = "Internal server error"
            }, 500, ct);
        }
    }

    private async Task UpdateDailySummaryAsync(string userId, int amountMl, CancellationToken ct)
    {
        try
        {
            var today = DateOnly.FromDateTime(DateTime.Today);

            _logger.LogInformation("Retrieve daily summary for user with id: {UserId}", userId);
            var existingSummary = await _supabase
                .From<Entities.DailySummary>()
                .Where(x => x.UserId == userId)
                .Where(x => x.Date == today)
                .Get(cancellationToken: ct);

            _logger.LogInformation("Update daily summary for user with id: {UserId}", userId);
            if (existingSummary.Models.Count != 0)
            {
                var summary = existingSummary.Models.First();
                summary.TotalConsumedMl += amountMl;
                summary.DrinkCount += 1;
                summary.GoalAchieved = summary.TotalConsumedMl >= summary.GoalMl;

                _logger.LogInformation("Adding {Amount}ml to daily total. New total should be: {Total}ml",
                    amountMl, summary.TotalConsumedMl);

                await _supabase
                    .From<Entities.DailySummary>()
                    .Where(x => x.Id == summary.Id)
                    .Update(summary, cancellationToken: ct);

                _logger.LogInformation("Added {Amount}ml to daily total. New total: {Total}ml",
                    amountMl, summary.TotalConsumedMl);
            }
            else
            {
                _logger.LogInformation("Retrieve user with id: {UserId}", userId);
                var userResult = await _supabase
                    .From<Entities.User>()
                    .Where(x => x.Id == userId)
                    .Limit(1)
                    .Get(cancellationToken: ct);

                var userGoal = userResult.Models.FirstOrDefault()?.DailyGoalMl ?? 2000;

                _logger.LogInformation("Create new daily summary for user with id: {UserId}", userId);
                var newSummary = new Entities.DailySummary
                {
                    UserId = userId,
                    Date = today,
                    TotalConsumedMl = amountMl,
                    GoalMl = userGoal,
                    DrinkCount = 1,
                    GoalAchieved = amountMl >= userGoal
                };

                await _supabase
                    .From<Entities.DailySummary>()
                    .Insert(newSummary, cancellationToken: ct);

                _logger.LogInformation("Created new daily summary with {Amount}ml", amountMl);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update daily summary");
        }
    }
}