import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../movie_detail/movie_detail_screen.dart';
import '../../core/providers/tmdb_provider.dart';
import '../../core/widgets/content_placeholder.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final int personId;

  const PersonDetailScreen({
    super.key,
    required this.personId,
  });

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  bool _isBiographyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final personDetailsAsync = ref.watch(personDetailsProvider(widget.personId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'MoviePlus',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.language, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.login, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: personDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $error',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
        data: (person) {
          final credits = person['movie_credits'] ?? {};
          
          // Debug: Print person data to console
          print('Person data received:');
          print('Name: ${person['name']}');
          print('Biography: ${person['biography']}');
          print('Biography length: ${(person['biography'] as String?)?.length ?? 0}');
          print('Biography language: ${person['biography_language']}');
          print('Birthday: ${person['birthday']}');
          print('Place of birth: ${person['place_of_birth']}');
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(person),
                
                // Main Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Biography
                      _buildBiographySection(person),
                      
                      const SizedBox(height: 32),
                      
                      // Known For Section
                      _buildKnownForSection(credits),
                      
                      const SizedBox(height: 32),
                      
                      // Personal Information
                      _buildPersonalInfoSection(person),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> person) {
    return Container(
      constraints: const BoxConstraints(minHeight: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          
          if (isWideScreen) {
            // Wide screen: side by side layout
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Image
                Container(
                  width: 280,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: person['profile_path'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${person['profile_path']}',
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                ),
                
                // Profile Info and Social Media
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          person['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Biography Label
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tiểu sử',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Biography Text
                        _buildBiographyText(person),
                        
                        const SizedBox(height: 16),
                        
                        // Read More Link
                        if ((person['biography'] ?? '').length > 200)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBiographyExpanded = !_isBiographyExpanded;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _isBiographyExpanded ? 'Thu gọn <' : 'Đọc thêm >',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Social Media Links
                        Row(
                          children: [
                            _buildSocialIcon(Icons.facebook, () {}),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.alternate_email, () {}),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.camera_alt, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Narrow screen: stacked layout
            return Column(
              children: [
                // Profile Image
                Container(
                  width: 200,
                  height: 280,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: person['profile_path'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            'https://image.tmdb.org/t/p/w500${person['profile_path']}',
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                ),
                
                // Profile Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        person['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Biography Label
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tiểu sử',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Biography Text
                      _buildBiographyText(person),
                      
                      const SizedBox(height: 16),
                      
                      // Social Media Links
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSocialIcon(Icons.facebook, () {}),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.alternate_email, () {}),
                            const SizedBox(width: 16),
                            _buildSocialIcon(Icons.camera_alt, () {}),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBiographyText(Map<String, dynamic> person) {
    final biography = person['biography'] as String? ?? '';
    final bioLanguage = person['biography_language'] as String? ?? 'unknown';
    
    if (biography.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Không có thông tin tiểu sử',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dữ liệu có thể chưa được cập nhật từ TMDB',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          biography,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[300],
            height: 1.5,
          ),
          maxLines: _isBiographyExpanded ? null : 15,
          overflow: _isBiographyExpanded ? null : TextOverflow.ellipsis,
        ),
        if (bioLanguage == 'en') ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange),
            ),
            child: Text(
              'Tiểu sử bằng tiếng Anh (bản tiếng Việt không có sẵn)',
              style: TextStyle(
                color: Colors.orange[300],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ] else if (bioLanguage == 'vi' && person['original_biography'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.translate,
                  color: Colors.green[300],
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Đã dịch từ tiếng Anh',
                  style: TextStyle(
                    color: Colors.green[300],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 1),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnownForSection(Map<String, dynamic> credits) {
    final cast = credits['cast'] as List<dynamic>? ?? [];
    
    // Sort cast by popularity/vote_average and get top movies
    cast.sort((a, b) {
      final aVote = (a['vote_average'] as num?)?.toDouble() ?? 0.0;
      final bVote = (b['vote_average'] as num?)?.toDouble() ?? 0.0;
      final aDate = a['release_date'] as String? ?? '';
      final bDate = b['release_date'] as String? ?? '';
      
      // First sort by vote average
      if (bVote != aVote) {
        return bVote.compareTo(aVote);
      }
      
      // Then by release date (newer first)
      return bDate.compareTo(aDate);
    });
    
    final topMovies = cast.take(8).toList();
    
    if (topMovies.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Known For',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ContentPlaceholder(
              message: 'Không có thông tin về các tác phẩm.\nDữ liệu có thể chưa được cập nhật từ TMDB.',
              icon: Icons.movie_outlined,
            ),
          ],
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 3,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Known For',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: topMovies.length,
            itemBuilder: (context, index) {
              final credit = topMovies[index];
              return _buildKnownForCard(context, credit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKnownForCard(BuildContext context, Map<String, dynamic> credit) {
    final title = credit['title'] ?? credit['name'] ?? 'Unknown';
    final posterPath = credit['poster_path'];
    final releaseDate = credit['release_date'] ?? credit['first_air_date'] ?? '';
    // final character = credit['character']; // Unused variable

    return GestureDetector(
      onTap: () {
        if (credit['id'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movieId: credit['id']),
            ),
          );
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 2/3,
                  child: posterPath != null
                      ? Image.network(
                          'https://image.tmdb.org/t/p/w200$posterPath',
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.movie,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Vietnamese Title (placeholder)
            if (releaseDate.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                _getVietnameseTitle(title),
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Year
            if (releaseDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  releaseDate.split('-')[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getVietnameseTitle(String originalTitle) {
    // This is a placeholder function - in a real app, you'd have a translation service
    // For now, just return some common Vietnamese titles for well-known movies
    final vietnameseTitles = {
      'The Conjuring': 'Ám Ảnh Kinh Hoàng',
      'The Conjuring 2': 'Ám Ảnh Kinh Hoàng 2',
      'Orphan': 'Đứa Trẻ Mồ Côi',
      'The Boy in the Striped Pyjamas': 'Chú Bé Mang Pyjama',
      'Godzilla: King of the Monsters': 'Chúa Tể Godzilla',
      'Source Code': 'Mật Mã Sống Còn',
    };
    
    return vietnameseTitles[originalTitle] ?? originalTitle;
  }

  // Widget _buildCreditCard(BuildContext context, Map<String, dynamic> credit, [String type = 'cast']) { // Unused function
  /*
    final title = credit['title'] ?? credit['name'] ?? 'Unknown';
    final posterPath = credit['poster_path'];
    final releaseDate = credit['release_date'] ?? credit['first_air_date'] ?? '';
    // final character = credit['character']; // Unused variable
    final job = credit['job'];
    final voteAverage = (credit['vote_average'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () {
        if (credit['id'] != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movieId: credit['id']),
            ),
          );
        }
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AspectRatio(
                      aspectRatio: 2/3,
                      child: posterPath != null
                          ? Image.network(
                              'https://image.tmdb.org/t/p/w200$posterPath',
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.movie,
                                color: Colors.grey,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                  // Rating badge
                  if (voteAverage > 0) 
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.yellow, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Year
            if (releaseDate.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                releaseDate.split('-')[0],
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                ),
              ),
            ],
            // Character or Job
            if (type == 'cast' && credit['character'] != null) ...[
              const SizedBox(height: 1),
              Text(
                'vai ${credit['character']}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else if (type == 'crew' && job != null) ...[
              const SizedBox(height: 1),
              Text(
                job,
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
  */

  // Widget _buildFilmographySection(Map<String, dynamic> credits) { // Unused function
  /*
    final cast = credits['cast'] as List<dynamic>? ?? [];
    final crew = credits['crew'] as List<dynamic>? ?? [];
    
    // Sort cast by popularity/vote_average and release date
    cast.sort((a, b) {
      final aVote = (a['vote_average'] as num?)?.toDouble() ?? 0.0;
      final bVote = (b['vote_average'] as num?)?.toDouble() ?? 0.0;
      final aDate = a['release_date'] as String? ?? '';
      final bDate = b['release_date'] as String? ?? '';
      
      // First sort by vote average
      if (bVote != aVote) {
        return bVote.compareTo(aVote);
      }
      
      // Then by release date (newer first)
      return bDate.compareTo(aDate);
    });
    
    if (cast.isEmpty && crew.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filmography',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ContentPlaceholder(
            message: 'Không có thông tin về các tác phẩm.\nDữ liệu có thể chưa được cập nhật từ TMDB.',
            icon: Icons.movie_outlined,
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (cast.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Diễn xuất',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  '${cast.length}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cast.length > 20 ? 20 : cast.length,
              itemBuilder: (context, index) {
                final credit = cast[index];
                return _buildCreditCard(context, credit, 'cast');
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        
        if (crew.isNotEmpty) ...[
          // Group crew by department
          ...() {
            final groupedCrew = <String, List<dynamic>>{};
            for (final member in crew) {
              final department = member['department'] as String? ?? 'Other';
              groupedCrew.putIfAbsent(department, () => []).add(member);
            }
            
            // Sort departments by importance
            final departments = groupedCrew.keys.toList();
            departments.sort((a, b) {
              const priority = {
                'Directing': 1,
                'Writing': 2,
                'Production': 3,
                'Camera': 4,
                'Editing': 5,
                'Sound': 6,
              };
              
              return (priority[a] ?? 99).compareTo(priority[b] ?? 99);
            });
            
            return departments.take(3).map((department) {
              final departmentCrew = groupedCrew[department]!;
              departmentCrew.sort((a, b) {
                final aDate = a['release_date'] as String? ?? '';
                final bDate = b['release_date'] as String? ?? '';
                return bDate.compareTo(aDate);
              });
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getDepartmentName(department),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          '${departmentCrew.length}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: departmentCrew.length > 10 ? 10 : departmentCrew.length,
                      itemBuilder: (context, index) {
                        final credit = departmentCrew[index];
                        return _buildCreditCard(context, credit, 'crew');
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }).toList();
          }(),
        ],
      ],
    );
  }
  */

  // String _getDepartmentName(String department) { // Unused function
  /*
    switch (department) {
      case 'Directing':
        return 'Đạo diễn';
      case 'Writing':
        return 'Biên kịch';
      case 'Production':
        return 'Sản xuất';
      case 'Camera':
        return 'Quay phim';
      case 'Editing':
        return 'Biên tập';
      case 'Sound':
        return 'Âm thanh';
      case 'Art':
        return 'Nghệ thuật';
      case 'Costume & Make-Up':
        return 'Trang phục & Trang điểm';
      case 'Visual Effects':
        return 'Hiệu ứng hình ảnh';
      default:
        return department;
    }
  }
  */

  Widget _buildPersonalInfoSection(Map<String, dynamic> person) {
    final hasPersonalInfo = person['birthday'] != null || 
                           person['place_of_birth'] != null ||
                           person['deathday'] != null ||
                           person['also_known_as'] != null ||
                           person['gender'] != null ||
                           person['popularity'] != null;

    if (!hasPersonalInfo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin cá nhân',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ContentPlaceholder(
            message: 'Không có thông tin cá nhân chi tiết.\nDữ liệu có thể chưa được cập nhật từ TMDB.',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Basic info
        if (person['birthday'] != null)
          _buildInfoRow('Ngày sinh', _formatDate(person['birthday'])),
        if (person['deathday'] != null)
          _buildInfoRow('Ngày mất', _formatDate(person['deathday'])),
        if (person['place_of_birth'] != null)
          _buildInfoRow('Nơi sinh', person['place_of_birth']),
        
        // Gender
        if (person['gender'] != null)
          _buildInfoRow('Giới tính', _getGenderText(person['gender'])),
        
        // Popularity
        if (person['popularity'] != null && person['popularity'] > 0)
          _buildInfoRow('Độ nổi tiếng', person['popularity'].toStringAsFixed(1)),
        
        // Also known as
        if (person['also_known_as'] != null && (person['also_known_as'] as List).isNotEmpty) ...[
          _buildInfoRow('Tên khác', (person['also_known_as'] as List).take(3).join(', ')),
        ],
        
        // External IDs if available
        if (person['external_ids'] != null) ...[
          _buildExternalIds(person['external_ids']),
        ],
        
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBiographySection(Map<String, dynamic> person) {
    // final biography = person['biography'] as String? ?? ''; // Unused variable
    // final bioLanguage = person['biography_language'] as String? ?? 'unknown'; // Unused variable
    
    // Skip this section since biography is now in the header and we don't want duplication
    return const SizedBox();
  }

  Widget _buildExternalIds(Map<String, dynamic> externalIds) {
    final ids = <String>[];
    
    if (externalIds['imdb_id'] != null && externalIds['imdb_id'].toString().isNotEmpty) {
      ids.add('IMDB: ${externalIds['imdb_id']}');
    }
    if (externalIds['facebook_id'] != null && externalIds['facebook_id'].toString().isNotEmpty) {
      ids.add('Facebook: ${externalIds['facebook_id']}');
    }
    if (externalIds['instagram_id'] != null && externalIds['instagram_id'].toString().isNotEmpty) {
      ids.add('Instagram: @${externalIds['instagram_id']}');
    }
    if (externalIds['twitter_id'] != null && externalIds['twitter_id'].toString().isNotEmpty) {
      ids.add('Twitter: @${externalIds['twitter_id']}');
    }
    
    if (ids.isEmpty) return const SizedBox();
    
    return Column(
      children: [
        _buildInfoRow('Liên kết', ''),
        const SizedBox(height: 4),
        ...ids.map((id) => Padding(
          padding: const EdgeInsets.only(left: 120, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  id,
                  style: TextStyle(
                    color: Colors.red[400],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Không rõ';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final age = now.year - date.year;
      
      return '${date.day}/${date.month}/${date.year} (${age} tuổi)';
    } catch (e) {
      return dateString;
    }
  }

  String _getGenderText(int? gender) {
    switch (gender) {
      case 1:
        return 'Nữ';
      case 2:
        return 'Nam';
      case 3:
        return 'Khác';
      default:
        return 'Không rõ';
    }
  }
}