import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Asetukset',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
