import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ARPermissionHandler {
  final VoidCallback onPermissionGranted;
  final VoidCallback onPermissionDenied;

  ARPermissionHandler({
    required this.onPermissionGranted,
    required this.onPermissionDenied,
  });

  Future<void> checkPermissions() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      var status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        onPermissionGranted();
      } else {
        onPermissionDenied();
      }
    } catch (e) {
      // 권한 체크 실패 시에도 진행
      await Future.delayed(const Duration(milliseconds: 1000));
      onPermissionGranted();
    }
  }

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text('AR 기능을 사용하려면 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('뒤로가기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }
}
