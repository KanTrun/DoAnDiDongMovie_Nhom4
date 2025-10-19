import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import 'auth_provider.dart';

final notesServiceProvider = Provider<NotesService>((ref) {
  final token = ref.read(authTokenProvider);
  print('🔑 NOTES SERVICE PROVIDER - Token: ${token != null ? "Present" : "NULL"}');
  return NotesService(token);
});

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final notesService = ref.read(notesServiceProvider);
  return NotesNotifier(notesService);
});

final movieNotesProvider = StateNotifierProvider.family<MovieNotesNotifier, MovieNotesState, String>((ref, key) {
  print('🔍 NOTES PROVIDER - Creating provider for key: $key');
  final notesService = ref.read(notesServiceProvider);
  final parts = key.split('_');
  final tmdbId = int.parse(parts[0]);
  final mediaType = parts[1];
  print('🔍 NOTES PROVIDER - Parsed tmdbId: $tmdbId, mediaType: $mediaType');
  return MovieNotesNotifier(notesService, tmdbId, mediaType);
});

class NotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  NotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 0,
    this.hasMore = false,
  });

  NotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    bool? hasMore,
  }) {
    return NotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class MovieNotesState {
  final List<Note> notes;
  final bool isLoading;
  final String? error;

  MovieNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.error,
  });

  MovieNotesState copyWith({
    List<Note>? notes,
    bool? isLoading,
    String? error,
  }) {
    return MovieNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  final NotesService _notesService;

  NotesNotifier(this._notesService) : super(NotesState());

  Future<void> loadNotes({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, error: null, currentPage: 1);
    } else if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _notesService.getNotes(
        page: refresh ? 1 : state.currentPage,
        pageSize: 20,
      );

      final newNotes = refresh ? response.notes : [...state.notes, ...response.notes];

      state = state.copyWith(
        notes: newNotes,
        isLoading: false,
        currentPage: response.page,
        totalPages: response.totalPages,
        hasMore: response.page < response.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreNotes() async {
    if (!state.hasMore || state.isLoading) return;
    await loadNotes();
  }

  Future<void> addNote({
    required int tmdbId,
    required String mediaType,
    required String content,
  }) async {
    try {
      final newNote = await _notesService.createNote(
        tmdbId: tmdbId,
        mediaType: mediaType,
        content: content,
      );

      state = state.copyWith(
        notes: [newNote, ...state.notes],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateNote(int id, String content) async {
    try {
      final updatedNote = await _notesService.updateNote(id: id, content: content);

      final updatedNotes = state.notes.map((note) {
        return note.id == id ? updatedNote : note;
      }).toList();

      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _notesService.deleteNote(id);

      final updatedNotes = state.notes.where((note) => note.id != id).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

class MovieNotesNotifier extends StateNotifier<MovieNotesState> {
  final NotesService _notesService;
  final int tmdbId;
  final String mediaType;

  MovieNotesNotifier(this._notesService, this.tmdbId, this.mediaType) : super(MovieNotesState()) {
    print('🔍 NOTES NOTIFIER - Constructor called for tmdbId: $tmdbId, mediaType: $mediaType');
    loadNotes();
  }

  Future<void> loadNotes() async {
    print('🔍 NOTES PROVIDER - Loading notes for tmdbId: $tmdbId, mediaType: $mediaType');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final notes = await _notesService.getNotesByMovie(tmdbId, mediaType);
      print('✅ NOTES PROVIDER - Successfully loaded ${notes.length} notes');
      state = state.copyWith(notes: notes, isLoading: false);
    } catch (e) {
      print('❌ NOTES PROVIDER - Error loading notes: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addNote(String content) async {
    try {
      final newNote = await _notesService.createNote(
        tmdbId: tmdbId,
        mediaType: mediaType,
        content: content,
      );

      state = state.copyWith(
        notes: [newNote, ...state.notes],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateNote(int id, String content) async {
    try {
      final updatedNote = await _notesService.updateNote(id: id, content: content);

      final updatedNotes = state.notes.map((note) {
        return note.id == id ? updatedNote : note;
      }).toList();

      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNote(int id) async {
    try {
      await _notesService.deleteNote(id);

      final updatedNotes = state.notes.where((note) => note.id != id).toList();
      state = state.copyWith(notes: updatedNotes);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
