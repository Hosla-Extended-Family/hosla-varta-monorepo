import 'package:flutter/material.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/widgets/post_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Varta Wall', style: TextThemes.title),
        actions: [
          IconButton(
            onPressed: () {
              // Todo: Add action for the icon button here
            },
            icon: Icon(Icons.add_photo_alternate),
          ),
            IconButton(
            onPressed: () {
              // Todo: Add action for the icon button here
            },
            icon: Icon(Icons.person_4_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            PostWidget(),
            PostWidget(),
            PostWidget(),
          ],
        ),
      ),
    );
  }
}
