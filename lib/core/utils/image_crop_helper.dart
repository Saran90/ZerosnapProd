import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../theme/app_colors.dart';

/// Launches the image cropper for a given file path.
/// Returns the cropped file path, or null if the user cancelled.
Future<String?> cropImage(
  BuildContext context,
  String sourcePath, {
  CropAspectRatio? aspectRatio,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    aspectRatio: aspectRatio,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Image',
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.primary,
        initAspectRatio: CropAspectRatioPreset.original,
        lockAspectRatio: false,
        hideBottomControls: false,
      ),
      IOSUiSettings(
        title: 'Crop Image',
        cancelButtonTitle: 'Cancel',
        doneButtonTitle: 'Done',
      ),
    ],
  );
  return cropped?.path;
}
