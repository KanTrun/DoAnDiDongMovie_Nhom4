using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Data;
using MoviePlusApi.Models;
using Microsoft.AspNetCore.Identity;

namespace MoviePlusApi.Scripts
{
    public static class CreateAdminUser
    {
        public static async Task CreateDefaultAdminAsync(IServiceProvider serviceProvider)
        {
            using var scope = serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MoviePlusContext>();
            var passwordHasher = scope.ServiceProvider.GetRequiredService<IPasswordHasher<User>>();

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

            Console.WriteLine("Admin user created successfully!");
            Console.WriteLine("Email: admin@gmail.com");
            Console.WriteLine("Password: Admin@123");
        }
    }
}
