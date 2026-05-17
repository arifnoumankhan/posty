import 'package:flutter/material.dart';
import 'package:posty/src/workspace/posty_workspace.dart';

/// Provides [PostyWorkspace] to request UI (auth tab, etc.).
class PostyScope extends InheritedWidget {
  const PostyScope({
    super.key,
    required this.workspace,
    required super.child,
  });

  final PostyWorkspace? workspace;

  static PostyWorkspace? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<PostyScope>()?.workspace;
  }

  @override
  bool updateShouldNotify(PostyScope oldWidget) =>
      oldWidget.workspace != workspace;
}
