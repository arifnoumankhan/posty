import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:posty/src/launch/posty_desktop_window.dart';
import 'package:posty/src/launch/posty_launch_request.dart';
import 'package:posty/src/launch/posty_platform.dart';
import 'package:posty/src/launch/posty_web_launcher.dart';
import 'package:posty/src/widgets/posty_screen.dart';
import 'package:universal_html/html.dart' as html;

/// Opens Posty in-app, in a new desktop window, or in a new browser tab.
abstract final class PostyLauncher {
  /// Whether the current platform can use a separate window/tab when
  /// [PostyLaunchRequest.openInNewWindow] is `true`.
  static bool get supportsSeparateWindow {
    if (kIsWeb) return true;
    return postyIsDesktopHost;
  }

  /// Default for [PostyLaunchRequest.openInNewWindow] (desktop + web → separate).
  static bool get defaultOpenInNewWindow => supportsSeparateWindow;

  static Future<void> open(
    BuildContext context,
    PostyLaunchRequest request,
  ) async {
    if (!request.openInNewWindow) {
      await _openInApp(context, request);
      return;
    }

    if (kIsWeb) {
      await _openWebTab(context, request);
      return;
    }

    if (postyIsDesktopHost) {
      await _openDesktop(context, request);
      return;
    }

    await _openInApp(context, request);
  }

  static Future<void> _openInApp(
    BuildContext context,
    PostyLaunchRequest request,
  ) async {
    if (request.onOpenInApp != null) {
      await request.onOpenInApp!(context);
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PostyScreen()),
    );
  }

  static Future<void> _openWebTab(
    BuildContext context,
    PostyLaunchRequest request,
  ) async {
    final url = request.webUrl ?? _webUrlFromHashRoute(request.webHashRoute);
    if (url == null) {
      _showError(
        context,
        'webUrl or webHashRoute is required to open Posty in a new tab on web.',
      );
      return;
    }
    try {
      openPostyInBrowserTab(url, windowName: request.webTabName);
    } catch (e) {
      _showError(context, 'Could not open Posty: $e');
    }
  }

  static Future<void> _openDesktop(
    BuildContext context,
    PostyLaunchRequest request,
  ) async {
    try {
      await PostyDesktopWindow.open(windowId: request.desktopWindowId);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Could not open Posty: $e');
    }
  }

  static Uri? _webUrlFromHashRoute(String? hashRoute) {
    if (hashRoute == null || hashRoute.isEmpty) return null;
    final origin = html.window.location.origin ?? '';
    if (origin.isEmpty) return null;
    final pathname = html.window.location.pathname ?? '/';
    final base = (pathname.isEmpty || pathname == '/')
        ? origin
        : '$origin${pathname.endsWith('/') ? pathname.substring(0, pathname.length - 1) : pathname}';
    return PostyLaunchRequest.webHashUrl(
      origin: base,
      hashRoute: hashRoute,
    );
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
