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
        
        // Chat system tables
        public DbSet<MoviePlusApi.Models.Chat.Conversation> Conversations { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.ConversationParticipant> ConversationParticipants { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.Message> Messages { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.MessageReadReceipt> MessageReadReceipts { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.UserConnection> UserConnections { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.MessageReaction> MessageReactions { get; set; }
        public DbSet<MoviePlusApi.Models.Chat.DeviceToken> DeviceTokens { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // User configuration
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Email).HasMaxLength(255).IsRequired();
                entity.Property(e => e.DisplayName).HasMaxLength(100);
                entity.Property(e => e.BioAuthEnabled).HasDefaultValue(false);
                
                // Indexes for performance
                entity.HasIndex(e => e.Email).IsUnique().HasDatabaseName("IX_Users_Email");
            });

            // Favorite configuration
            modelBuilder.Entity<Favorite>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Favorites)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Watchlist configuration
            modelBuilder.Entity<Watchlist>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Watchlists)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Note configuration
            modelBuilder.Entity<Note>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Content).HasColumnType("nvarchar(max)");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Notes)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // History configuration
            modelBuilder.Entity<History>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.WatchedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.MediaType).HasMaxLength(10);
                entity.Property(e => e.Action).HasMaxLength(32);
                entity.Property(e => e.Extra).HasColumnType("nvarchar(max)");
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Histories)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Rating configuration
            modelBuilder.Entity<Rating>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
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
                entity.Property(e => e.Content).HasColumnType("nvarchar(max)");
                entity.Property(e => e.PosterPath).HasMaxLength(500);
                entity.Property(e => e.MediaType).HasMaxLength(20);
                entity.Property(e => e.Title).HasMaxLength(200);
                
                entity.HasOne(e => e.User)
                    .WithMany(u => u.Posts)
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // PostReaction configuration
            modelBuilder.Entity<PostReaction>(entity =>
            {
                entity.HasKey(e => new { e.PostId, e.UserId });
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.PostReactions)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                    
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // PostComment configuration
            modelBuilder.Entity<PostComment>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Content).HasColumnType("nvarchar(max)");
                
                entity.HasOne(e => e.Post)
                    .WithMany(p => p.PostComments)
                    .HasForeignKey(e => e.PostId)
                    .OnDelete(DeleteBehavior.Cascade);
                    
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // CommentReaction configuration
            modelBuilder.Entity<CommentReaction>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                entity.HasOne(e => e.PostComment)
                    .WithMany(c => c.CommentReactions)
                    .HasForeignKey(e => e.CommentId)
                    .OnDelete(DeleteBehavior.Cascade);
                    
                entity.HasOne(e => e.User)
                    .WithMany()
                    .HasForeignKey(e => e.UserId)
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // UserFollow configuration
            modelBuilder.Entity<UserFollow>(entity =>
            {
                entity.HasKey(e => new { e.FollowerId, e.FolloweeId });
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
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
                    .OnDelete(DeleteBehavior.NoAction);
            });

            // Chat system configuration
            // Conversation configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.Conversation>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.IsGroup).HasDefaultValue(false);
                entity.Property(e => e.Title).HasMaxLength(200);
                
                // Configure navigation properties
                entity.HasMany(e => e.Participants)
                    .WithOne(p => p.Conversation)
                    .HasForeignKey(p => p.ConversationId)
                    .OnDelete(DeleteBehavior.Cascade);
                    
                entity.HasMany(e => e.Messages)
                    .WithOne(m => m.Conversation)
                    .HasForeignKey(m => m.ConversationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // ConversationParticipant configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.ConversationParticipant>(entity =>
            {
                entity.HasKey(e => new { e.ConversationId, e.UserId });
                entity.Property(e => e.JoinedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Role).HasMaxLength(50);
                
                // Configure foreign key relationships
                entity.HasOne(e => e.Conversation)
                    .WithMany(c => c.Participants)
                    .HasForeignKey(e => e.ConversationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // Message configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.Message>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Type).HasDefaultValue("text").HasMaxLength(50);
                entity.Property(e => e.MediaUrl).HasMaxLength(1000);
                entity.Property(e => e.MediaType).HasMaxLength(50);
                entity.Property(e => e.IsDeleted).HasDefaultValue(false);
                
                // Indexes for performance
                entity.HasIndex(e => new { e.ConversationId, e.CreatedAt }).HasDatabaseName("IX_Messages_ConversationId_CreatedAt");
                
                // Configure foreign key relationships
                entity.HasOne(e => e.Conversation)
                    .WithMany(c => c.Messages)
                    .HasForeignKey(e => e.ConversationId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // MessageReadReceipt configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.MessageReadReceipt>(entity =>
            {
                entity.HasKey(e => new { e.MessageId, e.UserId });
                entity.Property(e => e.ReadAt).HasDefaultValueSql("SYSUTCDATETIME()");
                
                entity.HasOne(e => e.Message)
                    .WithMany(m => m.ReadReceipts)
                    .HasForeignKey(e => e.MessageId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // MessageReaction configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.MessageReaction>(entity =>
            {
                entity.HasKey(e => new { e.MessageId, e.UserId });
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Reaction).HasMaxLength(50);
                
                entity.HasOne(e => e.Message)
                    .WithMany(m => m.Reactions)
                    .HasForeignKey(e => e.MessageId)
                    .OnDelete(DeleteBehavior.Cascade);
            });

            // UserConnection configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.UserConnection>(entity =>
            {
                entity.HasKey(e => e.ConnectionId);
                entity.Property(e => e.ConnectionId).HasMaxLength(200);
                entity.Property(e => e.DeviceInfo).HasMaxLength(500);
                entity.Property(e => e.ConnectedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.LastSeenAt).HasDefaultValueSql("SYSUTCDATETIME()");
            });

            // DeviceToken configuration
            modelBuilder.Entity<MoviePlusApi.Models.Chat.DeviceToken>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
                entity.Property(e => e.Token).HasMaxLength(500);
                entity.Property(e => e.Platform).HasMaxLength(50);
            });
        }
    }
}