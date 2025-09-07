import 'package:flutter/material.dart';

class ListTileWidget extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const ListTileWidget({super.key, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title), onTap: onTap);
  }
}
