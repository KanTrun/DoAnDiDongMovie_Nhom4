using MoviePlusApi.Scripts;

namespace MoviePlusApi.Scripts
{
    class CreateAdminProgram
    {
        static async Task Main(string[] args)
        {
            Console.WriteLine("🚀 Creating Admin User...");
            await CreateAdminDirect.CreateAdminUserAsync();
            Console.WriteLine("✅ Done!");
        }
    }
}
