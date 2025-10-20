/// Utility functions for time formatting
class TimeUtils {
  /// Parse UTC DateTime from JSON string
  static DateTime parseUtcDateTime(String dateTimeString) {
    // Ensure the string is treated as UTC
    if (dateTimeString.endsWith('Z')) {
      return DateTime.parse(dateTimeString);
    } else {
      // Add 'Z' to indicate UTC if not present
      return DateTime.parse('${dateTimeString}Z');
    }
  }

  /// Format a DateTime to a human-readable "time ago" string
  /// Handles UTC to local time conversion automatically
  static String formatTimeAgo(DateTime dateTime) {
    // Convert UTC time to local time for accurate calculation
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDateTime);


    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  /// Format a DateTime to a detailed timestamp
  static String formatDetailedTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localDateTime);

    if (difference.inDays > 0) {
      return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }
}
