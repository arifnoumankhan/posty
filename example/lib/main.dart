import 'package:flutter/material.dart';
import 'package:posty/posty.dart';

void main() {
  runApp(const PostyExampleApp());
}

class PostyExampleApp extends StatelessWidget {
  const PostyExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Posty Demo',
      home: PostyScreen(
        initialBaseUrl: 'https://httpbin.org',
        persistenceId: 'posty_example',
      ),
    );
  }
}
