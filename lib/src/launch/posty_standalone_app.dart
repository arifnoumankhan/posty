import 'package:flutter/material.dart';
import 'package:posty/src/theme/posty_theme.dart';
import 'package:posty/src/widgets/posty_screen.dart';

/// Supplies the home widget for [PostyStandaloneApp] in a secondary window.
abstract final class PostyStandaloneConfig {
  static WidgetBuilder homeBuilder = (_) => const PostyScreen();
}

/// Minimal shell for a dedicated Posty desktop window.
class PostyStandaloneApp extends StatelessWidget {
  const PostyStandaloneApp({
    super.key,
    this.title = 'Posty',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = PostyTheme.dark();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: title,
      theme: theme.toThemeData(),
      home: Builder(builder: PostyStandaloneConfig.homeBuilder),
    );
  }
}
