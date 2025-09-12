import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/core/constants/constants.dart';

class ListTileWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ListTileWidget({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: Constants.defaultPadding / 4,
      child: ListTile(
        title: Text(title, style: TextThemes.bodyMedium),
        tileColor: Color.fromARGB(255, 240, 240, 240),
        onTap: onTap,
        selectedTileColor: Colors.grey[200],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
