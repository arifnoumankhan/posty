import 'dart:io' show Platform;

bool get postyIsDesktopHost =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
