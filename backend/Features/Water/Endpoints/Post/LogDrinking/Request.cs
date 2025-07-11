namespace smart_water_bottle_backend.Features.Water.Endpoints.Post.LogDrinking;

public class Request
{
    public int AmountMl { get; set; }
    public DateTime Timestamp { get; set; }
}