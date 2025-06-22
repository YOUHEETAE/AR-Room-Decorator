import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'gallery_manager.dart';

class ARScreenshotHandler {
  final GalleryManager galleryManager;
  final VoidCallback onSuccess;
  final Function(String) onError;

  ARScreenshotHandler({
    required this.galleryManager,
    required this.onSuccess,
    required this.onError,
  });

  Future<void> takeScreenshot(ARSessionManager? arSessionManager) async {
    try {
      if (arSessionManager == null) return;

      var screenshotProvider = await arSessionManager.snapshot();

      if (screenshotProvider != null) {
        Uint8List? imageData = await _convertImageProviderToBytes(screenshotProvider);

        if (imageData != null) {
          await galleryManager.saveScreenshot(imageData);
          onSuccess();
        } else {
          onError("이미지 변환에 실패했습니다.");
        }
      } else {
        onError("스크린샷 촬영에 실패했습니다.");
      }
    } catch (e) {
      onError("스크린샷 저장 중 오류가 발생했습니다.");
    }
  }

  Future<Uint8List?> _convertImageProviderToBytes(ImageProvider imageProvider) async {
    try {
      final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
      final Completer<Uint8List> completer = Completer<Uint8List>();

      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        info.image.toByteData(format: ui.ImageByteFormat.png).then((byteData) {
          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          } else {
            completer.complete(null);
          }
        });
        stream.removeListener(listener);
      });

      stream.addListener(listener);
      return await completer.future;
    } catch (e) {
      return null;
    }
  }
}
