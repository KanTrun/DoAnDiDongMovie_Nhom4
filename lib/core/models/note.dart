import '../utils/time_utils.dart';

class Note {
  final int id;
  final int tmdbId;
  final String mediaType;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      tmdbId: json['tmdbId'],
      mediaType: json['mediaType'],
      content: json['content'],
      createdAt: TimeUtils.parseUtcDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? TimeUtils.parseUtcDateTime(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tmdbId': tmdbId,
      'mediaType': mediaType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    int? id,
    int? tmdbId,
    String? mediaType,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      tmdbId: tmdbId ?? this.tmdbId,
      mediaType: mediaType ?? this.mediaType,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PagedNotesResponse {
  final List<Note> notes;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  PagedNotesResponse({
    required this.notes,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PagedNotesResponse.fromJson(Map<String, dynamic> json) {
    return PagedNotesResponse(
      notes: (json['notes'] as List)
          .map((noteJson) => Note.fromJson(noteJson))
          .toList(),
      totalCount: json['totalCount'],
      page: json['page'],
      pageSize: json['pageSize'],
      totalPages: json['totalPages'],
    );
  }
}

