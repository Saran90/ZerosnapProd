import 'package:flutter/material.dart';
import '../utils/app_version.dart';

/// Widget that displays the app version
/// Automatically reads from pubspec.yaml via package_info_plus
class VersionText extends StatelessWidget {
  final TextStyle? style;
  final bool showBuildNumber;

  const VersionText({super.key, this.style, this.showBuildNumber = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      showBuildNumber ? AppVersion.fullVersion : AppVersion.simpleVersion,
      style: style,
    );
  }
}
