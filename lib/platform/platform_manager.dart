import 'dart:io';

class PlatformManager {
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static bool get isWindows => Platform.isWindows;
  static bool get isAndroid => Platform.isAndroid;
}
