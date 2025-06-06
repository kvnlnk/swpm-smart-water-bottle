using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;

namespace smart_water_bottle_backend.Entities;

[Table("daily_summaries")]
public class DailySummary : BaseModel
{
    [PrimaryKey("id")]
    public string Id { get; set; }
    
    [Column("user_id")] 
    public string UserId { get; set; }
    
    [Column("date")]
    public DateOnly Date { get; set; }    
    
    [Column("total_consumed_ml")]
    public int TotalConsumedMl { get; set; }
    
    [Column("goal_ml")]
    public int GoalMl { get; set; }
    
    [Column("goal_achieved")]
    public bool GoalAchieved { get; set; }
    
    [Column("drink_count")]
    public int DrinkCount { get; set; }
}