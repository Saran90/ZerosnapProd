import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import '../../../../core/theme/app_colors.dart';

/// Opens the native image cropper on [cardImagePath] so the user can
/// manually select the profile photo area from the already-cropped card image.
/// Returns the cropped file path, or null if cancelled.
Future<String?> cropProfileFromCard(
  BuildContext context,
  String cardImagePath,
) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: cardImagePath,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop Profile Photo',
        toolbarColor: AppColors.primary,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: AppColors.primary,
        backgroundColor: Colors.black,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: false,
        hideBottomControls: false,
        showCropGrid: true,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.original,
        ],
      ),
      IOSUiSettings(
        title: 'Crop Profile Photo',
        cancelButtonTitle: 'Cancel',
        doneButtonTitle: 'Done',
        aspectRatioLockEnabled: false,
        resetAspectRatioEnabled: true,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.original,
        ],
      ),
    ],
  );
  return cropped?.path;
}
