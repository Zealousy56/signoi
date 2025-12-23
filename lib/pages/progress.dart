import 'package:flutter/material.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(
        child: Icon(
          Icons.show_chart,
          size: 96,
          color: Colors.green,
        ),
      ),
    );
  }
}
