using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MoviePlusApi.Migrations
{
    /// <inheritdoc />
    public partial class AddNotesAndRatingsFeatures : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Rate_Score",
                table: "Ratings");

            migrationBuilder.DropIndex(
                name: "IX_Notes_UserId_TmdbId_MediaType",
                table: "Notes");

            migrationBuilder.AlterColumn<decimal>(
                name: "Score",
                table: "Ratings",
                type: "decimal(3,1)",
                nullable: false,
                oldClrType: typeof(byte),
                oldType: "tinyint");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Ratings",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Notes",
                type: "datetime2",
                nullable: true,
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldDefaultValueSql: "SYSUTCDATETIME()");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Notes",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "SYSUTCDATETIME()");

            migrationBuilder.AddCheckConstraint(
                name: "CK_Rate_Score",
                table: "Ratings",
                sql: "Score BETWEEN 1.0 AND 10.0");

            migrationBuilder.CreateIndex(
                name: "IX_Notes_UserId_CreatedAt",
                table: "Notes",
                columns: new[] { "UserId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_Notes_UserId_TmdbId_MediaType",
                table: "Notes",
                columns: new[] { "UserId", "TmdbId", "MediaType" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_Rate_Score",
                table: "Ratings");

            migrationBuilder.DropIndex(
                name: "IX_Notes_UserId_CreatedAt",
                table: "Notes");

            migrationBuilder.DropIndex(
                name: "IX_Notes_UserId_TmdbId_MediaType",
                table: "Notes");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Ratings");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Notes");

            migrationBuilder.AlterColumn<byte>(
                name: "Score",
                table: "Ratings",
                type: "tinyint",
                nullable: false,
                oldClrType: typeof(decimal),
                oldType: "decimal(3,1)");

            migrationBuilder.AlterColumn<DateTime>(
                name: "UpdatedAt",
                table: "Notes",
                type: "datetime2",
                nullable: false,
                defaultValueSql: "SYSUTCDATETIME()",
                oldClrType: typeof(DateTime),
                oldType: "datetime2",
                oldNullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "CK_Rate_Score",
                table: "Ratings",
                sql: "Score BETWEEN 1 AND 10");

            migrationBuilder.CreateIndex(
                name: "IX_Notes_UserId_TmdbId_MediaType",
                table: "Notes",
                columns: new[] { "UserId", "TmdbId", "MediaType" },
                unique: true);
        }
    }
}
