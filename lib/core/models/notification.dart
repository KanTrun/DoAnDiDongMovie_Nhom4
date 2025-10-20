import '../utils/time_utils.dart';

class Notification {
  final int id;
  final String type;
  final int? refId;
  final String? payload;
  final bool isRead;
  final DateTime createdAt;
  final String? message;
  final String? actionUrl;

  Notification({
    required this.id,
    required this.type,
    this.refId,
    this.payload,
    required this.isRead,
    required this.createdAt,
    this.message,
    this.actionUrl,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      type: json['type'],
      refId: json['refId'],
      payload: json['payload'],
      isRead: json['isRead'],
      createdAt: TimeUtils.parseUtcDateTime(json['createdAt']),
      message: json['message'],
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'refId': refId,
      'payload': payload,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
      'actionUrl': actionUrl,
    };
  }

  Notification copyWith({
    int? id,
    String? type,
    int? refId,
    String? payload,
    bool? isRead,
    DateTime? createdAt,
    String? message,
    String? actionUrl,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      refId: refId ?? this.refId,
      payload: payload ?? this.payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      message: message ?? this.message,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'post_liked':
        return 'Post Liked';
      case 'post_commented':
        return 'Post Commented';
      case 'comment_liked':
        return 'Comment Liked';
      case 'user_followed':
        return 'User Followed';
      default:
        return 'Notification';
    }
  }

  String get icon {
    switch (type) {
      case 'post_liked':
        return '❤️';
      case 'post_commented':
        return '💬';
      case 'comment_liked':
        return '👍';
      case 'user_followed':
        return '👤';
      default:
        return '🔔';
    }
  }
}

class PagedNotificationsResponse {
  final List<Notification> notifications;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;
  final int unreadCount;

  PagedNotificationsResponse({
    required this.notifications,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.unreadCount,
  });

  factory PagedNotificationsResponse.fromJson(Map<String, dynamic> json) {
    return PagedNotificationsResponse(
      notifications: (json['notifications'] as List)
          .map((notificationJson) => Notification.fromJson(notificationJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
      unreadCount: json['unreadCount'],
    );
  }
}

class NotificationFilter {
  final bool? isRead;
  final String? type;
  final int page;
  final int pageSize;

  NotificationFilter({
    this.isRead,
    this.type,
    this.page = 1,
    this.pageSize = 20,
  });

  Map<String, dynamic> toJson() {
    return {
      'isRead': isRead,
      'type': type,
      'page': page,
      'pageSize': pageSize,
    };
  }
}

class MarkNotificationReadRequest {
  final int notificationId;

  MarkNotificationReadRequest({
    required this.notificationId,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
    };
  }
}

class MarkAllNotificationsReadRequest {
  final List<int>? notificationIds;

  MarkAllNotificationsReadRequest({
    this.notificationIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'notificationIds': notificationIds,
    };
  }
}
