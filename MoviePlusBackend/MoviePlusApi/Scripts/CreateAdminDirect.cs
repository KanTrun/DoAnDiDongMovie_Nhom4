using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models;
using Microsoft.AspNetCore.Identity;

namespace MoviePlusApi.Scripts
{
    public static class CreateAdminDirect
    {
        public static async Task CreateAdminUserAsync()
        {
            // Connection string
            var connectionString = "Server=HP\\KANSQL;Database=MoviePlusDb;Trusted_Connection=true;MultipleActiveResultSets=true;TrustServerCertificate=true";
            
            // Create DbContext options
            var options = new DbContextOptionsBuilder<MoviePlusContext>()
                .UseSqlServer(connectionString)
                .Options;

            using var context = new MoviePlusContext(options);
            var passwordHasher = new PasswordHasher<User>();

            try
            {
                // Check if admin already exists
                var existingAdmin = await context.Users.FirstOrDefaultAsync(u => u.Email == "admin@gmail.com");
                if (existingAdmin != null)
                {
                    Console.WriteLine("Admin user already exists.");
                    return;
                }

                // Create admin user
                var adminUser = new User
                {
                    Id = Guid.NewGuid(),
                    Email = "admin@gmail.com",
                    DisplayName = "System Administrator",
                    Role = "Admin",
                    BioAuthEnabled = false,
                    CreatedAt = DateTime.UtcNow
                };

                // Hash the password
                adminUser.PasswordHash = passwordHasher.HashPassword(adminUser, "Admin@123");

                // Add to database
                context.Users.Add(adminUser);
                await context.SaveChangesAsync();

                Console.WriteLine("✅ Admin user created successfully!");
                Console.WriteLine("📧 Email: admin@gmail.com");
                Console.WriteLine("🔑 Password: Admin@123");
                Console.WriteLine("👤 Role: Admin");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error creating admin user: {ex.Message}");
                Console.WriteLine($"Stack trace: {ex.StackTrace}");
            }
        }
    }
}
