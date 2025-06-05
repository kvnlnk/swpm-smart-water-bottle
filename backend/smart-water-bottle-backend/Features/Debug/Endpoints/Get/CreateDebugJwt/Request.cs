namespace smart_water_bottle_backend.Features.Debug.Endpoints.Get.CreateDebugJWT;

public class Request
{
    public required string Email { get; set; }
    public required string Password { get; set; }
}