import 'dart:async';
import 'package:cut_match_app/providers/auth_provider.dart';
import 'package:cut_match_app/providers/notification_provider.dart';
import 'package:cut_match_app/screens/hairstyles/hairstyle_list_screen.dart';
import 'package:cut_match_app/screens/profiles/profile_screen.dart';
import 'package:cut_match_app/screens/salon/salon_finder_screen.dart';
import 'package:cut_match_app/screens/social/feeds/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  Timer? _notificationTimer;

  final List<Widget> _pages = [
    const HairstyleListScreen(),
    const FeedScreen(),
    const SalonFinderScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications();
      }
    });
    _startNotificationTimer();
  }

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<NotificationProvider>(
          context,
          listen: false,
        ).fetchNotifications(isBackgroundRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.cut_outlined),
                activeIcon: Icon(Icons.cut),
                label: 'Gallery',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.dynamic_feed_outlined),
                activeIcon: Icon(Icons.dynamic_feed),
                label: 'Feed',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Salon',
              ),
              BottomNavigationBarItem(
                label: 'Profile',
                icon: _buildNotificationIcon(
                  icon: Icons.person_outline,
                  showBadge: notificationProvider.hasUnreadNotifications,
                ),
                activeIcon: _buildNotificationIcon(
                  icon: Icons.person,
                  showBadge: notificationProvider.hasUnreadNotifications,
                ),
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }

  Widget _buildNotificationIcon({
    required IconData icon,
    required bool showBadge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (showBadge)
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
