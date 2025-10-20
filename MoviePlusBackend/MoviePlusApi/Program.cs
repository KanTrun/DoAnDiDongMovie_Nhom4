using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using MoviePlusApi.Data;
using MoviePlusApi.Services;
using Microsoft.AspNetCore.Identity;
using MoviePlusApi.Models;
using MoviePlusApi.Scripts;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Add DbContext
builder.Services.AddDbContext<MoviePlusContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection") ?? 
                        "Server=HP\\KANSQL;Database=MoviePlusDb;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=true"));

// Add JWT Service
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();
// Community services
builder.Services.AddScoped<IPostService, PostService>();

// Add JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secretKey = jwtSettings["SecretKey"] ?? "your-super-secret-key-that-is-at-least-32-characters-long";

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtSettings["Issuer"] ?? "MoviePlusApi",
            ValidAudience = jwtSettings["Audience"] ?? "MoviePlusClient",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey))
        };
    });

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// Create admin user on startup
using (var scope = app.Services.CreateScope())
{
    try
    {
        await CreateAdminUser.CreateDefaultAdminAsync(scope.ServiceProvider);
    }
    catch (Exception ex)
    {
        Console.WriteLine($"Error creating admin user: {ex.Message}");
    }
}

// Configure to run on all network interfaces
app.Urls.Add("http://0.0.0.0:5127");

app.Run();
