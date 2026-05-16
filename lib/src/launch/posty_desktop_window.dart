import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:posty/src/launch/posty_window_ids.dart';
import 'package:window_manager_plus/window_manager_plus.dart';

/// Desktop secondary-window setup and creation for Posty.
abstract final class PostyDesktopWindow {
  static const Size defaultSize = Size(1180, 820);
  static const Size minimumSize = Size(800, 560);

  static bool isPostyWindowArgs(List<String> args) {
    if (args.length < 3) return false;
    final id = int.tryParse(args[1]);
    if (id == null || id == 0) return false;
    return args[2] == PostyWindowIds.screenType;
  }

  /// Call from the secondary window `main` before `runApp` (matches Barioo window helper).
  static Future<void> setupFromArgs(List<String> args) async {
    final windowId = int.tryParse(args[1]);
    if (windowId == null) {
      throw ArgumentError('Invalid Posty window id: ${args[1]}');
    }

    await WindowManagerPlus.ensureInitialized(windowId);

    const windowOptions = WindowOptions(
      size: defaultSize,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      minimumSize: minimumSize,
    );

    WindowManagerPlus.current.waitUntilReadyToShow(windowOptions, () async {
      developer.log('Posty window ready', name: 'PostyDesktopWindow');
      await WindowManagerPlus.current.setPreventClose(false);
      await WindowManagerPlus.current.center();
      await WindowManagerPlus.current.show();
      await WindowManagerPlus.current.focus();
    });
  }

  /// Opens Posty in a new desktop window from the primary app.
  static Future<void> open({
    int windowId = PostyWindowIds.defaultDisplayId,
  }) async {
    try {
      await _create(windowId);
    } catch (e) {
      developer.log(
        'Posty createWindow failed, retrying: $e',
        name: 'PostyDesktopWindow',
      );
      try {
        await WindowManagerPlus.current.invokeMethodToWindow(
          windowId,
          PostyWindowIds.closeWindowMethod,
        );
        await Future<void>.delayed(const Duration(milliseconds: 350));
        await _create(windowId);
      } catch (e2) {
        developer.log(
          'Posty createWindow retry failed: $e2',
          name: 'PostyDesktopWindow',
        );
        rethrow;
      }
    }
  }

  static Future<void> _create(int windowId) async {
    final created = await WindowManagerPlus.createWindow([
      windowId.toString(),
      PostyWindowIds.screenType,
    ]);
    if (created == null) {
      throw StateError('WindowManagerPlus.createWindow returned null');
    }
  }
}
