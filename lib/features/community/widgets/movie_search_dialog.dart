import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/tmdb_provider.dart';

class MovieSearchDialog extends ConsumerStatefulWidget {
  final Function(int tmdbId, String mediaType, String title, String? posterPath) onMovieSelected;

  const MovieSearchDialog({
    super.key,
    required this.onMovieSelected,
  });

  @override
  ConsumerState<MovieSearchDialog> createState() => _MovieSearchDialogState();
}

class _MovieSearchDialogState extends ConsumerState<MovieSearchDialog> {
  final _searchController = TextEditingController();
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchMovies(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _currentQuery = query.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Tìm phim',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập tên phim hoặc TV show...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _currentQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _searchMovies,
            ),
            const SizedBox(height: 16),
            
            // Search results
            Expanded(
              child: _currentQuery.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.movie_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nhập tên phim để tìm kiếm',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Consumer(
                      builder: (context, ref, child) {
                        final searchRequest = SearchRequest(query: _currentQuery);
                        final searchState = ref.watch(searchMoviesProvider(searchRequest));
                        
                        return searchState.when(
                          data: (response) {
                            if (response.results.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Không tìm thấy kết quả',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return ListView.builder(
                              itemCount: response.results.length,
                              itemBuilder: (context, index) {
                                final movie = response.results[index];
                                return ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: movie.posterPath.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              'https://image.tmdb.org/t/p/w200${movie.posterPath}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.movie,
                                                  color: Colors.grey,
                                                );
                                              },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.movie,
                                            color: Colors.grey,
                                          ),
                                  ),
                                  title: Text(movie.title),
                                  subtitle: Text('${movie.releaseDate.year} • ${movie.mediaType == 'tv' ? 'TV Show' : 'Movie'}'),
                                  onTap: () {
                                    widget.onMovieSelected(
                                      movie.id,
                                      movie.mediaType ?? 'movie',
                                      movie.title,
                                      movie.posterPath,
                                    );
                                    Navigator.of(context).pop();
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Lỗi tìm kiếm',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

