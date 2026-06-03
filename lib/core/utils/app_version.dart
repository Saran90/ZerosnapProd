import 'package:package_info_plus/package_info_plus.dart';

/// Utility class for getting app version information
class AppVersion {
  static PackageInfo? _packageInfo;

  /// Initialize package info - call this in main() before runApp()
  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get the app version string (e.g., "1.0.1")
  static String get version {
    return _packageInfo?.version ?? '1.0.0';
  }

  /// Get the build number (e.g., "2")
  static String get buildNumber {
    return _packageInfo?.buildNumber ?? '1';
  }

  /// Get the full version string (e.g., "version 1.0.1 (2)")
  static String get fullVersion {
    return 'version $version ($buildNumber)';
  }

  /// Get the simple version string (e.g., "version 1.0.1")
  static String get simpleVersion {
    return 'version $version';
  }
}
