import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/home/home_shell.dart';
import 'features/discover/discover_tab.dart';
import 'features/search/search_tab.dart';
import 'features/favorites/favorites_tab.dart';
import 'features/watchlist/watchlist_tab.dart';
import 'features/community/community_tab.dart';
import 'features/profile/profile_tab.dart';
import 'features/movie_detail/movie_detail_screen.dart';
import 'features/movie_detail/tv_show_detail_screen.dart';
import 'features/person/person_detail_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';

class MoviePlusApp extends ConsumerStatefulWidget {
  const MoviePlusApp({super.key});

  @override
  ConsumerState<MoviePlusApp> createState() => _MoviePlusAppState();
}

class _MoviePlusAppState extends ConsumerState<MoviePlusApp> {
  @override
  void initState() {
    super.initState();
    // Initialize auth state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MoviePlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _createRouter(ref),
    );
  }

  GoRouter _createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isInitialized = !ref.read(authLoadingProvider);

        // Wait for auth initialization
        if (!isInitialized) {
          return null;
        }

        // Simple redirect logic
        if (!isAuthenticated && 
            !state.matchedLocation.startsWith('/login') &&
            !state.matchedLocation.startsWith('/register')) {
          return '/login';
        }

        if (isAuthenticated && 
            (state.matchedLocation == '/login' || state.matchedLocation == '/register')) {
          return '/home';
        }

        return null;
      },
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Shell route with bottom navigation
        ShellRoute(
          builder: (context, state, child) => HomeShell(child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const DiscoverTab(),
            ),
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const SearchTab(),
            ),
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesTab(),
            ),
            GoRoute(
              path: '/watchlist',
              name: 'watchlist',
              builder: (context, state) => const WatchlistTab(),
            ),
            GoRoute(
              path: '/community',
              name: 'community',
              builder: (context, state) => const CommunityTab(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileTab(),
            ),
          ],
        ),
        
        // Detail routes
        GoRoute(
          path: '/movie/:id',
          name: 'movie-detail',
          builder: (context, state) {
            final movieId = int.parse(state.pathParameters['id']!);
            return MovieDetailScreen(movieId: movieId);
          },
        ),
        GoRoute(
          path: '/tv/:id',
          name: 'tv-detail',
          builder: (context, state) {
            final tvShowId = int.parse(state.pathParameters['id']!);
            return TvShowDetailScreen(tvShowId: tvShowId);
          },
        ),
        GoRoute(
          path: '/person/:id',
          name: 'person-detail',
          builder: (context, state) {
            final personId = int.parse(state.pathParameters['id']!);
            return PersonDetailScreen(personId: personId);
          },
        ),
      ],
    );
  }
}