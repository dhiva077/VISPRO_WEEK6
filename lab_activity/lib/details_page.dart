import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final String itemId;
  const DetailsPage({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail')),
      body: Center(
        child: Text('You opened item ID: $itemId', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
