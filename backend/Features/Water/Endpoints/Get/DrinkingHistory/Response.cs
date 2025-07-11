namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.DrinkingHistory;

public class Response
{
    public DateTime Date { get; set; }
    public int TotalAmountMl { get; set; }
    public int DrinkCount { get; set; }
    public List<DrinkingEntry> DrinkingEntries { get; set; } = [];
}


public class DrinkingEntry
{
    public string Id { get; set; }
    public int AmountMl { get; set; }
    public DateTime CreatedAt { get; set; }
}