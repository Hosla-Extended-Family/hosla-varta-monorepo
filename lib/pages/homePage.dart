import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
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
  int _selectedIndex = 3;

  List<Widget> _pages = [
    FeedPage(),
    EventsPage(),
    ChatPage(),
    EmergencyPage(),
    SettingsPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
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
        selectedItemColor: ThemeColors.navBarIconColor,
        unselectedItemColor: ThemeColors.secondaryColor,
        onTap: _onItemTapped,
        selectedLabelStyle: TextThemes.button,
        unselectedLabelStyle: TextThemes.bodySmall,
        backgroundColor: ThemeColors.navBarColor,
        elevation: 10,
        iconSize: 20,
        selectedFontSize: 8,
        unselectedFontSize: 6,
      ),
    );
  }
}
