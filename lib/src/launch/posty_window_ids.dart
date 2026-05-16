/// Window metadata for [WindowManagerPlus] secondary Posty windows.
abstract final class PostyWindowIds {
  /// `createWindow` first argument (display / window id).
  static const int defaultDisplayId = 21;

  /// `createWindow` second argument — must match [PostyBootstrap.handleSecondaryWindowArgs].
  static const String screenType = 'posty_tools';

  static const String closeWindowMethod = 'closeWindow';
}
