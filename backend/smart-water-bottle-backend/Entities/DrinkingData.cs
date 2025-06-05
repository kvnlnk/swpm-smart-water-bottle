using Supabase.Postgrest.Attributes;
using Supabase.Postgrest.Models;

namespace smart_water_bottle_backend.Entities;

[Table("drinking_data")]
public class DrinkingData : BaseModel
{
    [PrimaryKey("id")]
    public string Id { get; set; }
    
    [Column("user_id")] 
    public string UserId { get; set; }  
    
    [Column("amount_ml")]
    public int AmountMl { get; set; }
    
    [Column("created_at")]
    public DateTime CreatedAt { get; set; }
}