namespace smart_water_bottle_backend.Features.User.Endpoints.Get.UserInformation;

public class Response
{
    public string? Id { get; set; }
    public string? Email { get; set; }
    public string? Username { get; set; }
    public int? DailyGoalMl { get; set; }
    public bool? NotificationsEnabled { get; set; }
    public int? WeightKg { get; set; }
    public int? HeightCm { get; set; }
}