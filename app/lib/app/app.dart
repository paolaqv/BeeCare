import 'package:flutter/material.dart';

class BeeCareApp extends StatelessWidget {
  const BeeCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeeCare',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(
          child: Text('BeeCare'),
        ),
      ),
    );
  }
}