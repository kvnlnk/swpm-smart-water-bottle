namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.LastDrinkingTime;

public enum DrinkReminderType
{
    None, Normal, Important
}


public class Response
{
    public DateTime? LastDrinkingTime { get; set; }
    public int MinutesSinceLastDrink { get; set; }
    public bool ShouldSendReminder { get; set; } 
    public DrinkReminderType DrinkReminderType { get; set; } 
}