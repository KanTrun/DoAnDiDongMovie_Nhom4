import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/models/backend_models.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Statistics'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildStatsContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading statistics: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(adminStatsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsContent(BuildContext context, AdminStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview section
          _buildSection(
            'Platform Overview',
            [
              _buildStatCard(
                'Total Users',
                stats.totalUsers.toString(),
                Icons.people,
                Colors.blue,
                'All registered users',
              ),
              _buildStatCard(
                'Administrators',
                stats.totalAdmins.toString(),
                Icons.admin_panel_settings,
                Colors.red,
                'Admin accounts',
              ),
              _buildStatCard(
                'Regular Users',
                stats.totalRegularUsers.toString(),
                Icons.person,
                Colors.green,
                'Standard user accounts',
              ),
              _buildStatCard(
                'Recent Users',
                stats.recentUsers.toString(),
                Icons.person_add,
                Colors.purple,
                'Joined in last 7 days',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User engagement section
          _buildSection(
            'User Engagement',
            [
              _buildStatCard(
                'Total Favorites',
                stats.totalFavorites.toString(),
                Icons.favorite,
                Colors.pink,
                'Movies/TV shows favorited',
              ),
              _buildStatCard(
                'Total Watchlists',
                stats.totalWatchlists.toString(),
                Icons.playlist_add,
                Colors.orange,
                'Items in watchlists',
              ),
              _buildStatCard(
                'Total Notes',
                stats.totalNotes.toString(),
                Icons.note,
                Colors.amber,
                'User notes created',
              ),
              _buildStatCard(
                'Total Histories',
                stats.totalHistories.toString(),
                Icons.history,
                Colors.teal,
                'User activity records',
              ),
              _buildStatCard(
                'Total Ratings',
                stats.totalRatings.toString(),
                Icons.star,
                Colors.yellow,
                'User ratings given',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Insights section
          _buildInsightsSection(stats),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: children,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(AdminStats stats) {
    final avgFavoritesPerUser = stats.totalUsers > 0 ? (stats.totalFavorites / stats.totalUsers).toStringAsFixed(1) : '0';
    final avgWatchlistsPerUser = stats.totalUsers > 0 ? (stats.totalWatchlists / stats.totalUsers).toStringAsFixed(1) : '0';
    final avgNotesPerUser = stats.totalUsers > 0 ? (stats.totalNotes / stats.totalUsers).toStringAsFixed(1) : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInsightRow(
            'Average favorites per user',
            '$avgFavoritesPerUser',
            Icons.favorite,
            Colors.pink,
          ),
          _buildInsightRow(
            'Average watchlists per user',
            '$avgWatchlistsPerUser',
            Icons.playlist_add,
            Colors.orange,
          ),
          _buildInsightRow(
            'Average notes per user',
            '$avgNotesPerUser',
            Icons.note,
            Colors.amber,
          ),
          _buildInsightRow(
            'Admin to user ratio',
            '${stats.totalAdmins}:${stats.totalRegularUsers}',
            Icons.admin_panel_settings,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
