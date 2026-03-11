import 'package:flutter/material.dart';
import 'package:hosla/core/constants/theme_colors.dart';
import 'package:hosla/pages/home/chat_page.dart';
import 'package:hosla/pages/home/emergency_page.dart';
import 'package:hosla/pages/home/events_page.dart';
import 'package:hosla/pages/home/feed_page.dart';
import 'package:hosla/pages/home/settings_page.dart';

class Homepage extends StatefulWidget {
  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToFeed() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const FeedPage(),
      const EventsPage(),
      const ChatPage(),
      EmergencyPage(onSuccess: _navigateToFeed),
      SettingsPage(showBackButton: false),
    ];
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 14,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w600,
        ),
        unselectedFontSize: 12,
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Quicksand',
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_rounded),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: ThemeColors.primaryColor,
        unselectedItemColor: ThemeColors.getSecondaryTextColor(context),
        onTap: _onItemTapped,
        backgroundColor: ThemeColors.getNavBarColor(context),
        elevation: 10,
        iconSize: 20,
      ),
    );
  }
}
