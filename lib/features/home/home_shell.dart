import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends ConsumerStatefulWidget {
  final Widget child;

  const HomeShell({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  // Map routes to bottom nav indices
  int _getIndexForLocation(String location) {
    switch (location) {
      case '/home':
        return 0;
      case '/search':
        return 1;
      case '/favorites':
        return 2;
      case '/watchlist':
        return 3;
      case '/chat':
        return 4;
      case '/community':
        return 5;
      case '/profile':
        return 6;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current location and sync bottom nav index
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _getIndexForLocation(location);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: widget.child, // Use GoRouter's child instead of tabs array
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/home');
                break;
              case 1:
                context.go('/search');
                break;
              case 2:
                context.go('/favorites');
                break;
              case 3:
                context.go('/watchlist');
                break;
              case 4:
                context.go('/chat');
                break;
              case 5:
                context.go('/community');
                break;
              case 6:
                context.go('/profile');
                break;
            }
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFE50914),
          unselectedItemColor: Colors.grey[600],
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Khám phá',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Tìm kiếm',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Yêu thích',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_outline),
              activeIcon: Icon(Icons.bookmark),
              label: 'Danh sách',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_outlined),
              activeIcon: Icon(Icons.chat),
              label: 'Tin nhắn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Cộng đồng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}