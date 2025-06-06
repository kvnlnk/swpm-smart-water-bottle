namespace smart_water_bottle_backend.Features.Water.Endpoints.Get.DailySummary;

public class Response
{
    public DateOnly Date { get; set; }
    public int TotalAmountMl { get; set; }
    public int GoalAmountMl { get; set; }
    public int PercentageAchieved { get; set; }
    public int DrinkCount { get; set; }
    public bool IsGoalReached { get; set; }
}