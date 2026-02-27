import 'package:flutter/material.dart';
import 'package:hosla/core/constants/constants.dart';
import 'package:hosla/core/constants/text_theme.dart';
import 'package:hosla/widgets/button.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Emergency', style: TextThemes.getTitleStyle(context)),
      ),
      body: SingleChildScrollView(
        padding: Constants.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Text(
              'Are you in distress?',
              style: TextThemes.getBodyLargeStyle(context),
            ),
            SizedBox(height: 10),
            Text(
              'If you\'re feeling unsafe or need immediate assistance, please use the options below.',
              style: TextThemes.getBodyMediumStyle(context),
            ),
            SizedBox(height: 30),

            // TODO: Add functionalities to the buttons
            Button(text: "Give a Call", onPressed: () {}),
            SizedBox(height: 16),
            Button(text: "Post an emergency message", onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
