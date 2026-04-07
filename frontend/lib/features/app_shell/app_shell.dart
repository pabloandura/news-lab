import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/daily_news/presentation/screens/home/daily_news.dart';
import 'package:news_lab/features/explore/presentation/screens/explore_page.dart';
import 'package:news_lab/features/journalist_profile/presentation/screens/profile_tab_page.dart';
import 'package:news_lab/features/publish_article/presentation/screens/publish_tab_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final List<bool> _hasVisited = [true, false, false, false];

  void _onTabTapped(int index) {
    if (index == 2) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        Navigator.pushNamed(context, AppRoutes.login);
        return;
      }
    }
    if (index == 3) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        Navigator.pushNamed(context, AppRoutes.login);
        return;
      }
    }
    setState(() {
      if (!_hasVisited[index]) _hasVisited[index] = true;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const DailyNews(),
          _hasVisited[1] ? const ExplorePage() : const SizedBox.shrink(),
          _hasVisited[2] ? const PublishTabPage() : const SizedBox.shrink(),
          _hasVisited[3] ? const ProfileTabPage() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black38,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 32),
            activeIcon: Icon(Icons.add_circle, size: 32),
            label: 'Publish',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
