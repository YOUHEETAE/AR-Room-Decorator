import 'package:flutter/material.dart';
import 'initial_ar_screen.dart';

class ARNavigationHandler {
  final BuildContext context;
  final VoidCallback onDispose;

  ARNavigationHandler({
    required this.context,
    required this.onDispose,
  });

  Future<bool> handleBackPress() async {
    debugPrint("📱 시스템 뒤로가기 버튼 감지");
    await navigateBack();
    return false;
  }

  Future<void> navigateBack() async {
    debugPrint("🔙 안전한 뒤로가기 시작");

    try {
      debugPrint("🚀 즉시 네비게이션 실행");

      if (context.mounted) {
        // 백그라운드에서 AR 정리 시작
        onDispose();

        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
          debugPrint("✅ pop()으로 뒤로가기 완료");
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ModernInitialARScreen(),
            ),
          );
          debugPrint("✅ pushReplacement()로 초기화면 이동 완료");
        }
      } else {
        debugPrint("⚠️ 네비게이션 불가능 - mounted: false");
      }
    } catch (e) {
      debugPrint("⚠️ 뒤로가기 중 오류: $e");
      try {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ModernInitialARScreen(),
            ),
          );
          debugPrint("✅ 오류 복구 - 강제 초기화면 이동 완료");
        }
      } catch (e2) {
        debugPrint("⚠️ 강제 뒤로가기도 실패: $e2");
      }
    }
  }
}