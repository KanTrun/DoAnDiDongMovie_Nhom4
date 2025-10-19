using Microsoft.EntityFrameworkCore;
using MoviePlusApi.Models;

namespace MoviePlusApi.Data
{
    public class MoviePlusContext : DbContext
    {
        public MoviePlusContext(DbContextOptions<MoviePlusContext> options) : base(options)
        {
        }

        public DbSet<User> Users { get; set; }
        public DbSet<Favorite> Favorites { get; set; }
        public DbSet<Watchlist> Watchlists { get; set; }
        public DbSet<Note> Notes { get; set; }
        public DbSet<History> Histories { get; set; }
        public DbSet<Rating> Ratings { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User configuration
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => e.Email).IsUnique();
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.BioAuthEnabled).HasDefaultValue(false);
                entity.Property(e => e.Role).HasDefaultValue("User");
                entity.HasCheckConstraint("CK_User_Role", "Role IN ('Admin','User')");
            });

            // Favorite configuration
            modelBuilder.Entity<Favorite>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.UserId, e.TmdbId, e.MediaType }).IsUnique();
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasCheckConstraint("CK_Fav_Media", "MediaType IN ('movie','tv')");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Favorites)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Watchlist configuration
            modelBuilder.Entity<Watchlist>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.UserId, e.TmdbId, e.MediaType }).IsUnique();
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.HasCheckConstraint("CK_Watch_Media", "MediaType IN ('movie','tv')");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Watchlists)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Note configuration
            modelBuilder.Entity<Note>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.UserId, e.TmdbId, e.MediaType });
                entity.HasIndex(e => new { e.UserId, e.CreatedAt }).HasDatabaseName("IX_Notes_UserId_CreatedAt");
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Content).IsRequired();
                entity.HasCheckConstraint("CK_Notes_Media", "MediaType IN ('movie','tv')");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Notes)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // History configuration
            modelBuilder.Entity<History>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.MediaType).HasMaxLength(10).IsRequired();
                entity.Property(e => e.Action).HasMaxLength(32).IsRequired();
                entity.Property(e => e.WatchedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                // Indexes for performance
                entity.HasIndex(e => new { e.UserId, e.WatchedAt }).HasDatabaseName("IX_Histories_User_Time");
                entity.HasIndex(e => new { e.TmdbId, e.MediaType, e.Action, e.WatchedAt }).HasDatabaseName("IX_Histories_Tmdb_Action");
                
                // Constraints
                entity.HasCheckConstraint("CK_Histories_Media", "MediaType IN ('movie','tv')");
                entity.HasCheckConstraint("CK_Histories_Action", 
                    "Action IN ('TrailerView','DetailOpen','ProviderClick','NoteCreated','RatingGiven','FavoriteAdded','FavoriteRemoved','WatchlistAdded','WatchlistRemoved','ShareClick')");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Histories)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Rating configuration
            modelBuilder.Entity<Rating>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.HasIndex(e => new { e.UserId, e.TmdbId, e.MediaType }).IsUnique();
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Score).HasColumnType("decimal(3,1)");
                entity.HasCheckConstraint("CK_Rate_Media", "MediaType IN ('movie','tv')");
                entity.HasCheckConstraint("CK_Rate_Score", "Score BETWEEN 1.0 AND 10.0");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Ratings)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}