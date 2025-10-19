using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MoviePlusApi.Migrations
{
    /// <inheritdoc />
    public partial class UpdateHistoryModelForEngagementLogging : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Histories_UserId",
                table: "Histories");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Hist_Action",
                table: "Histories");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Hist_Media",
                table: "Histories");

            migrationBuilder.AlterColumn<string>(
                name: "Extra",
                table: "Histories",
                type: "nvarchar(max)",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(1000)",
                oldMaxLength: 1000,
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "Histories",
                type: "nvarchar(32)",
                maxLength: 32,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(30)",
                oldMaxLength: 30);

            migrationBuilder.CreateIndex(
                name: "IX_Histories_Tmdb_Action",
                table: "Histories",
                columns: new[] { "TmdbId", "MediaType", "Action", "WatchedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Histories_User_Time",
                table: "Histories",
                columns: new[] { "UserId", "WatchedAt" });

            migrationBuilder.AddCheckConstraint(
                name: "CK_Histories_Action",
                table: "Histories",
                sql: "Action IN ('TrailerView','DetailOpen','ProviderClick','NoteCreated','RatingGiven','FavoriteAdded','FavoriteRemoved','WatchlistAdded','WatchlistRemoved','ShareClick')");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Histories_Media",
                table: "Histories",
                sql: "MediaType IN ('movie','tv')");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Histories_Tmdb_Action",
                table: "Histories");

            migrationBuilder.DropIndex(
                name: "IX_Histories_User_Time",
                table: "Histories");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Histories_Action",
                table: "Histories");

            migrationBuilder.DropCheckConstraint(
                name: "CK_Histories_Media",
                table: "Histories");

            migrationBuilder.AlterColumn<string>(
                name: "Extra",
                table: "Histories",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true,
                oldClrType: typeof(string),
                oldType: "nvarchar(max)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "Action",
                table: "Histories",
                type: "nvarchar(30)",
                maxLength: 30,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "nvarchar(32)",
                oldMaxLength: 32);

            migrationBuilder.CreateIndex(
                name: "IX_Histories_UserId",
                table: "Histories",
                column: "UserId");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Hist_Action",
                table: "Histories",
                sql: "Action IN ('open_detail','play_trailer','finish_trailer')");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Hist_Media",
                table: "Histories",
                sql: "MediaType IN ('movie','tv')");
        }
    }
}
