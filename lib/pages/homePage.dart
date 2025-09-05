import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Padding(
        padding: Constants.defaultPadding,
        child: const Center(child: Text('Welcome to the Home Page!')),
      ),
    );
  }
}
