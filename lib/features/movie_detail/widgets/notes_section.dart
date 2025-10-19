import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notes_provider.dart';
import '../../../core/models/note.dart';

class NotesSection extends ConsumerStatefulWidget {
  final int tmdbId;
  final String mediaType;

  const NotesSection({
    Key? key,
    required this.tmdbId,
    required this.mediaType,
  }) : super(key: key);

  @override
  ConsumerState<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends ConsumerState<NotesSection> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final providerKey = '${widget.tmdbId}_${widget.mediaType}';
    final notesState = ref.watch(movieNotesProvider(providerKey));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ghi chú của tôi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isAddingNote = !_isAddingNote;
                });
              },
              icon: Icon(
                _isAddingNote ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Add note form
        if (_isAddingNote) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Viết ghi chú về bộ phim này...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isAddingNote = false;
                          _noteController.clear();
                        });
                      },
                      child: const Text('Hủy'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _noteController.text.trim().isEmpty
                          ? null
                          : () => _addNote(),
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Notes list
        if (notesState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (notesState.error != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Lỗi: ${notesState.error}',
              style: const TextStyle(color: Colors.white),
            ),
          )
        else if (notesState.notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Chưa có ghi chú nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notesState.notes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final note = notesState.notes[index];
              return _buildNoteCard(note);
            },
          ),
      ],
    );
  }

  Widget _buildNoteCard(Note note) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(note.createdAt),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
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
          const SizedBox(height: 8),
          Text(
            note.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          if (note.updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Đã sửa: ${_formatDate(note.updatedAt!)}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    try {
      await ref.read(movieNotesProvider('${widget.tmdbId}_${widget.mediaType}').notifier)
          .addNote(_noteController.text.trim());

      if (mounted) {
        setState(() {
          _isAddingNote = false;
          _noteController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu ghi chú!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                ref.read(movieNotesProvider('${widget.tmdbId}_${widget.mediaType}').notifier)
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
              ref.read(movieNotesProvider('${widget.tmdbId}_${widget.mediaType}').notifier)
                  .deleteNote(note.id);
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
