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
        
        // Community features
        public DbSet<Post> Posts { get; set; }
        public DbSet<PostReaction> PostReactions { get; set; }
        public DbSet<PostComment> PostComments { get; set; }
        public DbSet<CommentReaction> CommentReactions { get; set; }
        public DbSet<UserFollow> UserFollows { get; set; }
        public DbSet<Notification> Notifications { get; set; }

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

            // Post configuration
            modelBuilder.Entity<Post>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Visibility).HasDefaultValue(1);
                entity.Property(e => e.LikeCount).HasDefaultValue(0);
                entity.Property(e => e.CommentCount).HasDefaultValue(0);
                entity.Property(e => e.Title).HasMaxLength(200);
                entity.Property(e => e.MediaType).HasMaxLength(20);
                entity.HasCheckConstraint("CK_Post_Visibility", "Visibility IN (0,1,2)");
                entity.HasCheckConstraint("CK_Post_Media", "MediaType IN ('movie','tv') OR MediaType IS NULL");
                
                // Indexes for performance
                entity.HasIndex(e => new { e.Visibility, e.CreatedAt }).HasDatabaseName("IX_Posts_Public_Feed");
                entity.HasIndex(e => new { e.TmdbId, e.MediaType, e.Visibility, e.CreatedAt }).HasDatabaseName("IX_Posts_ByMovie");
                entity.HasIndex(e => new { e.UserId, e.CreatedAt }).HasDatabaseName("IX_Posts_ByUser");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Posts)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // PostReaction configuration
            modelBuilder.Entity<PostReaction>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Type).HasDefaultValue(1);
                entity.HasCheckConstraint("CK_PostReaction_Type", "Type = 1"); // Only like for now
                
                // Unique constraint to prevent duplicate reactions
                entity.HasIndex(e => new { e.PostId, e.UserId, e.Type }).IsUnique().HasDatabaseName("UQ_PostReactions");
                
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.PostReactions)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.NoAction);
                    
                entity.HasOne(e => e.User)
                    .WithMany(u => u.PostReactions)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // PostComment configuration
            modelBuilder.Entity<PostComment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.LikeCount).HasDefaultValue(0);
                
                // Indexes for performance
                entity.HasIndex(e => new { e.PostId, e.CreatedAt }).HasDatabaseName("IX_PostComments_Post");
                entity.HasIndex(e => new { e.UserId, e.CreatedAt }).HasDatabaseName("IX_PostComments_User");
                
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.PostComments)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.NoAction);
                    
                entity.HasOne(e => e.User)
                    .WithMany(u => u.PostComments)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
                    
                entity.HasOne(e => e.ParentComment)
                    .WithMany(c => c.Replies)
                    .HasForeignKey(e => e.ParentCommentId)
                    .OnDelete(DeleteBehavior.Restrict);
            });

            // CommentReaction configuration
            modelBuilder.Entity<CommentReaction>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Type).HasDefaultValue(1);
                entity.HasCheckConstraint("CK_CommentReaction_Type", "Type = 1"); // Only like for now
                
                // Unique constraint to prevent duplicate reactions
                entity.HasIndex(e => new { e.CommentId, e.UserId, e.Type }).IsUnique().HasDatabaseName("UQ_CommentReactions");
                
                entity.HasOne(e => e.PostComment)
                    .WithMany(c => c.CommentReactions)
                    .HasForeignKey(e => e.CommentId)
                    .OnDelete(DeleteBehavior.NoAction);
                    
                entity.HasOne(e => e.User)
                    .WithMany(u => u.CommentReactions)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // UserFollow configuration
            modelBuilder.Entity<UserFollow>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                // Unique constraint to prevent duplicate follows
                entity.HasIndex(e => new { e.FollowerId, e.FolloweeId }).IsUnique().HasDatabaseName("UQ_UserFollows");
                
                entity.HasOne(e => e.Follower)
                    .WithMany(u => u.Following)
                    .HasForeignKey(e => e.FollowerId)
                    .OnDelete(DeleteBehavior.NoAction);
                    
                entity.HasOne(e => e.Followee)
                    .WithMany(u => u.Followers)
                    .HasForeignKey(e => e.FolloweeId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // Notification configuration
            modelBuilder.Entity<Notification>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.IsRead).HasDefaultValue(false);
                entity.Property(e => e.Type).HasMaxLength(30).IsRequired();
                
                // Indexes for performance
                entity.HasIndex(e => new { e.UserId, e.IsRead, e.CreatedAt }).HasDatabaseName("IX_Notifications_User");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Notifications)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });
        }
    }
}