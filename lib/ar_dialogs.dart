// ar_dialogs.dart - 다이얼로그들 분리
import 'package:flutter/material.dart';
import 'node_manager.dart';

class ARDialogs {
  // 노드 선택 다이얼로그
  static void showNodeSelectedDialog(
      BuildContext context,
      NodeManager nodeManager,
      String tappedNodeId,
      List<String> nodeNames,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.touch_app, color: Colors.blue),
            const SizedBox(width: 8),
            const Text("노드 선택됨"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nodeManager.getNodeTapDialogContent(tappedNodeId, nodeNames)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "💡 사용법:",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "• Move Mode 버튼: 가구 이동 모드\n• 이동 모드에서 평면을 탭하여 이동\n• Remove Selected: 선택된 가구 삭제",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 에러 다이얼로그
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("오류"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}