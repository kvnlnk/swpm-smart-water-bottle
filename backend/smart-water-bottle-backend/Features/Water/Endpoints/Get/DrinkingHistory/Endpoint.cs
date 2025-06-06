using FastEndpoints;
using Supabase.Postgrest;

namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.DrinkingHistory;

public class Endpoint: EndpointWithoutRequest<Response>
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
        Get("api/water/drinking-history");
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
        
        var today = DateTime.Today;
        var tomorrow = today.AddDays(1);

        _logger.LogInformation("Retrieving drinking history for {Date}", today.ToString("yyyy-MM-dd"));
        
        var drinkingHistory = await _supabase
            .From<Entities.DrinkingData>()
            .Where(x => x.UserId == userId)
            .Where(x => x.CreatedAt >= today)
            .Where(x => x.CreatedAt < tomorrow)
            .Order(d => d.CreatedAt, Constants.Ordering.Descending)
            .Get(cancellationToken: ct);

        if (drinkingHistory != null)
        {
            var totalAmountToday = drinkingHistory.Models.Sum(d => d.AmountMl);
            
            var response = new Response
            {
                Date = today,
                TotalAmountMl = totalAmountToday,
                DrinkCount = drinkingHistory.Models.Count(),
                DrinkingEntries = drinkingHistory.Models.Select(drinks => new DrinkingEntry
                {
                    Id = drinks.Id,
                    AmountMl = drinks.AmountMl,
                    CreatedAt = drinks.CreatedAt
                }).ToList()
            };
            _logger.LogInformation("Found {Count} drinks totaling {Amount}ml for today", 
                response.DrinkCount, response.TotalAmountMl);
            
            await SendOkAsync(response, ct);
        }
        else
        {
            _logger.LogWarning("No water history data found for user with ID {UserId}", userId);
            await SendAsync(new Response
            {
                Date = today,
                TotalAmountMl = 0,
                DrinkCount = 0,
                DrinkingEntries = []
            }, 200, ct);
        }
    }
}