import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/widgets/list_tile_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: TextThemes.title)),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          children: [
            ListTileWidget(title: 'Profile', onTap: () {}),
            ListTileWidget(title: 'Notifications', onTap: () {}),
            ListTileWidget(title: 'Privacy', onTap: () {}),
            ListTileWidget(title: 'About', onTap: () {}),
          ],
        ),

      ),
    );
  }
}
