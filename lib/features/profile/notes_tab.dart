import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/notes_provider.dart';
import '../../core/models/note.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({Key? key}) : super(key: key);

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notesProvider.notifier).loadMoreNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesState = ref.watch(notesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        title: const Text('Ghi chú của tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              ref.read(notesProvider.notifier).loadNotes(refresh: true);
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm ghi chú...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Notes list
          Expanded(
            child: notesState.isLoading && notesState.notes.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : notesState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Lỗi: ${notesState.error}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(notesProvider.notifier).loadNotes(refresh: true);
                              },
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ),
                      )
                    : notesState.notes.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.note_add,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Chưa có ghi chú nào',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Hãy xem phim và thêm ghi chú!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.read(notesProvider.notifier).loadNotes(refresh: true);
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: notesState.notes.length + (notesState.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == notesState.notes.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final note = notesState.notes[index];
                                return _buildNoteCard(note);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: note.mediaType == 'movie' ? Colors.blue : Colors.purple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.mediaType == 'movie' ? 'Phim' : 'TV',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${note.tmdbId}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(note.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Text(
            note.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (note.updatedAt != null)
                Text(
                  'Đã sửa: ${_formatDate(note.updatedAt!)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _viewMovie(note.tmdbId, note.mediaType),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Xem phim'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _editNote(note),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () => _deleteNote(note),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewMovie(int tmdbId, String mediaType) {
    if (mediaType == 'tv') {
      context.push('/tv/$tmdbId');
    } else {
      context.push('/movie/$tmdbId');
    }
  }

  void _editNote(Note note) {
    final controller = TextEditingController(text: note.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Sửa ghi chú', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nội dung ghi chú...',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(notesProvider.notifier)
                    .updateNote(note.id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Xóa ghi chú', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bạn có chắc chắn muốn xóa ghi chú này?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(note.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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
}
