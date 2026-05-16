import 'package:flutter/material.dart';
import 'package:posty/src/launch/posty_window_ids.dart';

/// How to open Posty from a host app (drawer, menu, etc.).
class PostyLaunchRequest {
  const PostyLaunchRequest({
    this.openInNewWindow = true,
    this.onOpenInApp,
    this.webUrl,
    this.webHashRoute,
    this.webTabName = 'posty',
    this.desktopWindowId = PostyWindowIds.defaultDisplayId,
  });

  /// When `true`, opens a separate desktop window or browser tab (if supported).
  /// When `false`, uses [onOpenInApp] or a simple [Navigator] push.
  final bool openInNewWindow;

  /// Host navigation (e.g. `context.pushNamed('posty_api_screen')`).
  final Future<void> Function(BuildContext context)? onOpenInApp;

  /// Explicit tab URL on web. If null, [webHashRoute] builds `origin/#/route`.
  final Uri? webUrl;

  /// Hash route for Flutter web hosts (e.g. `posty_api_screen`).
  final String? webHashRoute;

  /// `window.open` name on web.
  final String webTabName;

  final int desktopWindowId;

  /// Builds a hash URL for Flutter web hosts (`origin/#/route`).
  static Uri webHashUrl({
    required String origin,
    required String hashRoute,
  }) {
    final route = hashRoute.startsWith('/') ? hashRoute.substring(1) : hashRoute;
    var base = origin.trim();
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return Uri.parse('$base/#/$route');
  }
}
