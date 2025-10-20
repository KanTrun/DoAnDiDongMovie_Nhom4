using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MoviePlusApi.Migrations
{
    /// <inheritdoc />
    public partial class AddBiometricTemplate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BiometricTemplate",
                table: "Users",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BiometricTemplate",
                table: "Users");
        }
    }
}
