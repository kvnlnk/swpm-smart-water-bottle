namespace smart_water_bottle_backend.Features.User.Endpoints.Patch.UpdateProfile;

public class Request
{
    public string? Username { get; set; }
    public int? DailyGoalMl { get; set; }
    public bool? NotificationsEnabled { get; set; } 
    public int? WeightKg { get; set; }
    public int? HeightCm { get; set; }
}