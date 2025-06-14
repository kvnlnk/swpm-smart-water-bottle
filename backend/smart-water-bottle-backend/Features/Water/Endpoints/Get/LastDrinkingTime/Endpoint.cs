using FastEndpoints;
using Supabase.Postgrest;

namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.LastDrinkingTime;

public class Endpoint : EndpointWithoutRequest<Response>
{
    private readonly Supabase.Client _supabase;
    private readonly ILogger<Endpoint> _logger;
    
    private const int NormalReminderIntervalMinutes = 180;
    private const int ImportantReminderIntervalMinutes = 300;


    public Endpoint(Supabase.Client supabase, ILogger<Endpoint> logger)
    {
        _supabase = supabase;
        _logger = logger;
    }

    public override void Configure()
    {
        Get("api/water/last-drinking-time");
    }

    public override async Task HandleAsync(CancellationToken ct)
    {
        _logger.LogInformation("Handling request to get users last drinking time");
        var userId = User.FindFirst("sub")?.Value;

        if (userId == null)
        {
            _logger.LogInformation("User ID claim not found in JWT");
            await SendUnauthorizedAsync(ct);
            return;
        }

        _logger.LogInformation("Retrieving users last drinking time");
        
        var lastDrink = await _supabase
            .From<Entities.DrinkingData>()
            .Where(x => x.UserId == userId)
            .Order(d => d.CreatedAt, Constants.Ordering.Descending)
            .Limit(1)
            .Get(cancellationToken: ct);
        
        if (lastDrink.Model != null)
        {
            _logger.LogInformation("Retrieved users last drinking time: {lastDrink}",  lastDrink.Model.CreatedAt);
            var response = new Response();
            var lastDrinkTime = lastDrink.Model!.CreatedAt;
            var minutesSince = Math.Max(0, (int)(DateTime.Now - lastDrinkTime).TotalMinutes);
            
            response.LastDrinkingTime = lastDrinkTime;
            response.MinutesSinceLastDrink = minutesSince;
            

            switch (minutesSince)
            {
                case >= ImportantReminderIntervalMinutes:
                    response.DrinkReminderType = DrinkReminderType.Important;
                    response.ShouldSendReminder = true;
                    break;
                case >= NormalReminderIntervalMinutes:
                    response.DrinkReminderType = DrinkReminderType.Normal;
                    response.ShouldSendReminder = true;
                    break;
                default:
                    response.DrinkReminderType = DrinkReminderType.None;
                    response.ShouldSendReminder = false;
                    break;
            }
            
            await SendOkAsync(response, ct);
        }
        else
        {
            _logger.LogWarning("No water data found for user with ID {UserId}", userId);
            await SendAsync(new Response
            {
                LastDrinkingTime = null,
                MinutesSinceLastDrink = 0,
                ShouldSendReminder = true,
                DrinkReminderType = DrinkReminderType.Important,
            }, 200, ct);
        }
    }
}