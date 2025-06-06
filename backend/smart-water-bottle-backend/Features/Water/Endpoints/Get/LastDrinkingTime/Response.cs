namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.LastDrinkingTime;

public class Response
{
    public DateTime? LastDrinkingTime { get; set; }
    public int MinutesSinceLastDrink { get; set; }
    public bool ShouldSendReminder { get; set; } 
    public string? ReminderMessage { get; set; } 
}