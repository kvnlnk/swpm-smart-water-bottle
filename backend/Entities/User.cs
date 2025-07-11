using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;

namespace smart_water_bottle_backend.Entities;

[Table("users")]
public class User : BaseModel
{
    [PrimaryKey("id")]
    public string Id { get; set; }

    [Column("email")]
    public string? Email { get; set; }

    [Column("username")]
    public string? Username { get; set; }

    [Column("role")] 
    public string Role { get; set; } = "User";

    [Column("daily_goal_ml")] 
    public int DailyGoalMl { get; set; } = 2000;
    
    [Column("notifications_enabled")] 
    public bool NotificationsEnabled { get; set; } = true;
    
    [Column("weight_kg")]
    public int? WeightKg { get; set; }
    
    [Column("height_cm")]
    public int? HeightCm { get; set; }
}