import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/post.dart';
import '../../../core/providers/community_provider.dart';
import 'movie_search_dialog.dart';
import '../../../core/services/tmdb_service.dart';

class PostEditor extends ConsumerStatefulWidget {
  final int? tmdbId;
  final String? mediaType;
  final VoidCallback? onPostCreated;
  final String? initialTitle;
  final String? initialContent;
  final int? initialVisibility;
  final int? postId; // For edit mode
  final bool isEditMode;

  const PostEditor({
    super.key,
    this.tmdbId,
    this.mediaType,
    this.onPostCreated,
    this.initialTitle,
    this.initialContent,
    this.initialVisibility,
    this.postId,
    this.isEditMode = false,
  });

  @override
  ConsumerState<PostEditor> createState() => _PostEditorState();
}

class _PostEditorState extends ConsumerState<PostEditor> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _visibility = 1; // Default to Public
  bool _isLoading = false;
  String? _selectedMovieTitle;
  int? _selectedTmdbId;
  String? _selectedMediaType;
  String? _selectedPosterPath;

  @override
  void initState() {
    super.initState();
    // Set initial values for edit mode
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    if (widget.initialVisibility != null) {
      _visibility = widget.initialVisibility!;
    }

    // If tmdbId is provided (e.g., creating from a movie context or editing), prefetch title/poster
    if (widget.tmdbId != null) {
      _prefillFromTmdb(widget.tmdbId!, widget.mediaType ?? 'movie');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _showMoviePicker() {
    showDialog(
      context: context,
      builder: (context) => MovieSearchDialog(
        onMovieSelected: (tmdbId, mediaType, title, posterPath) {
          print('Movie selected: $title, tmdbId: $tmdbId, mediaType: $mediaType, posterPath: $posterPath');
          setState(() {
            _selectedMovieTitle = title;
            _selectedTmdbId = tmdbId;
            _selectedMediaType = mediaType;
            _selectedPosterPath = posterPath;
          });
          print('_selectedMovieTitle after setState: $_selectedMovieTitle');
          print('_selectedTmdbId: $_selectedTmdbId, _selectedMediaType: $_selectedMediaType, _selectedPosterPath: $_selectedPosterPath');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã chọn: $title'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  String? _getPosterPath() {
    return _selectedPosterPath;
  }

  Future<void> _prefillFromTmdb(int tmdbId, String mediaType) async {
    try {
      if (mediaType == 'tv') {
        final tv = await TmdbService.getTvShowDetails(tmdbId);
        setState(() {
          _selectedMovieTitle = tv.name;
          _selectedTmdbId = tmdbId;
          _selectedMediaType = 'tv';
          _selectedPosterPath = tv.posterPath;
        });
      } else {
        final movie = await TmdbService.getMovieDetails(tmdbId);
        setState(() {
          _selectedMovieTitle = movie.title;
          _selectedTmdbId = tmdbId;
          _selectedMediaType = 'movie';
          _selectedPosterPath = movie.posterPath;
        });
      }
      // If no initial title, default to movie/tv title
      if (_titleController.text.trim().isEmpty && _selectedMovieTitle != null) {
        _titleController.text = _selectedMovieTitle!;
      }
    } catch (_) {
      // ignore prefill errors silently
    }
  }

  void _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isEditMode && widget.postId != null) {
        // Edit mode
        // Only send visibility if different from initial
        final int? newVisibility = (widget.initialVisibility != null && _visibility == widget.initialVisibility)
            ? null
            : _visibility;

        final request = UpdatePostRequest(
          title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
          content: _contentController.text.trim(),
          visibility: newVisibility,
          tmdbId: _selectedTmdbId,
          mediaType: _selectedMediaType,
          posterPath: _getPosterPath(),
        );
        
        await ref.read(postsProvider.notifier).updatePost(widget.postId!, request);
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onPostCreated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bài viết đã được cập nhật thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create mode
        final request = CreatePostRequest(
          tmdbId: _selectedTmdbId ?? widget.tmdbId,
          mediaType: _selectedMediaType ?? widget.mediaType,
          // Default title to selected movie title if user leaves it blank
          title: _titleController.text.trim().isEmpty
              ? (_selectedMovieTitle ?? widget.initialTitle)
              : _titleController.text.trim(),
          content: _contentController.text.trim(),
          visibility: _visibility,
          posterPath: _getPosterPath(),
        );

        await ref.read(postsProvider.notifier).createPost(request);
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onPostCreated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bài viết đã được tạo thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
              const Spacer(),
              Text(
                'Tạo bài viết',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoading ? null : _submitPost,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Đăng'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          // Form
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Movie selector
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: (_selectedMovieTitle != null || _selectedTmdbId != null)
                                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (_selectedMovieTitle != null || _selectedTmdbId != null)
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Builder(
                              builder: (context) {
                                print('Building movie display: _selectedMovieTitle = $_selectedMovieTitle');
                                return Text(
                                  _selectedMovieTitle != null 
                                      ? _selectedMovieTitle!
                                      : _selectedTmdbId != null 
                                          ? 'Đang viết về ${widget.mediaType == 'tv' ? 'TV Show' : 'Movie'}'
                                          : 'Chọn phim (tùy chọn)',
                                  style: TextStyle(
                                    color: (_selectedMovieTitle != null || _selectedTmdbId != null)
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[600],
                                    fontWeight: (_selectedMovieTitle != null || _selectedTmdbId != null)
                                        ? FontWeight.bold 
                                        : FontWeight.normal,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_selectedMovieTitle != null || _selectedTmdbId != null)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedMovieTitle = null;
                                _selectedTmdbId = null;
                                _selectedMediaType = null;
                                _selectedPosterPath = null;
                              });
                            },
                          ),
                        if (_selectedMovieTitle == null && _selectedTmdbId == null)
                          TextButton(
                            onPressed: () {
                              _showMoviePicker();
                            },
                            child: const Text('Chọn phim'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề (tùy chọn)',
                      hintText: 'Nhập tiêu đề cho bài viết...',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 200,
                  ),
                  const SizedBox(height: 16),
                  
                  // Content field
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung *',
                      hintText: 'Chia sẻ suy nghĩ của bạn về bộ phim...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 8,
                    maxLength: 2000,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập nội dung';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Visibility selector
                  Text(
                    'Quyền riêng tư',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(3, (index) {
                    final visibility = index;
                    final labels = ['Riêng tư', 'Công khai', 'Không liệt kê'];
                    final descriptions = [
                      'Chỉ bạn có thể xem',
                      'Mọi người có thể xem',
                      'Chỉ người có link mới xem được',
                    ];
                    
                    return RadioListTile<int>(
                      value: visibility,
                      groupValue: _visibility,
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                      title: Text(labels[visibility]),
                      subtitle: Text(descriptions[visibility]),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
