import 'package:flutter/material.dart';

class CommunityFilters extends StatelessWidget {
  final String currentFilter;
  final Function(String) onFilterChanged;
  final Function(int?, String?) onMovieFilterChanged;

  const CommunityFilters({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
    required this.onMovieFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  isSelected: currentFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Đang theo dõi',
                  isSelected: currentFilter == 'following',
                  onTap: () => onFilterChanged('following'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Phim này',
                  isSelected: currentFilter == 'movie',
                  onTap: () => onFilterChanged('movie'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Movie filter info
          if (currentFilter == 'movie')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hiển thị bài viết về phim hiện tại',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
