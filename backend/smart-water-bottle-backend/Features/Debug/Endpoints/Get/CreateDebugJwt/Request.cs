namespace smart_water_bottle_backend.Features.Debug.Endpoints.Get.CreateDebugJWT;

public class Request
{
    public string? FirstName { get; set; }
    public string? LastName { get; set; }
    public required string Email { get; set; }
}