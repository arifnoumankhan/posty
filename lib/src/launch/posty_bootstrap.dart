import 'package:flutter/material.dart';
import 'package:posty/src/launch/posty_desktop_window.dart';
import 'package:posty/src/launch/posty_standalone_app.dart';

/// Host `main()` integration for a Posty secondary desktop window.
abstract final class PostyBootstrap {
  /// Returns `true` if [args] launch a Posty tools window (caller should return from `main`).
  static bool isPostyWindowArgs(List<String> args) =>
      PostyDesktopWindow.isPostyWindowArgs(args);

  /// Configure and run the standalone Posty app when [args] target a Posty window.
  ///
  /// ```dart
  /// if (await PostyBootstrap.runSecondaryWindowIfNeeded(
  ///   args,
  ///   home: (context) => const MyPostyHostScreen(),
  /// )) return;
  /// ```
  static Future<bool> runSecondaryWindowIfNeeded(
    List<String> args, {
    required WidgetBuilder home,
    String appTitle = 'Posty',
  }) async {
    if (!isPostyWindowArgs(args)) return false;

    WidgetsFlutterBinding.ensureInitialized();
    PostyStandaloneConfig.homeBuilder = home;
    await PostyDesktopWindow.setupFromArgs(args);
    runApp(PostyStandaloneApp(title: appTitle));
    return true;
  }
}
