// ar_widgets.dart - UI 위젯들 분리 (디버그 위젯 제거, 반투명 적용)
import 'package:flutter/material.dart';
import 'node_manager.dart';

// 선택된 노드 정보 표시 위젯
class SelectedNodeInfoWidget extends StatelessWidget {
  final NodeManager nodeManager;

  const SelectedNodeInfoWidget({
    super.key,
    required this.nodeManager,
  });

  @override
  Widget build(BuildContext context) {
    if (nodeManager.selectedNodeName == null) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      left: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '선택됨: ${nodeManager.selectedNodeName}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (nodeManager.selectedTapId != null)
              Text(
                'ID: ${nodeManager.selectedTapId}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            const SizedBox(height: 8),

            // 모드 상태 표시
            if (nodeManager.isMoveMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '이동 모드 - 평면을 탭하여 이동',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            if (nodeManager.isRotateMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '회전 모드 - 버튼으로 회전',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 사용법 안내 위젯
class InstructionsWidget extends StatelessWidget {
  final bool isARInitialized;
  final NodeManager nodeManager;
  final bool showDebug;

  const InstructionsWidget({
    super.key,
    required this.isARInitialized,
    required this.nodeManager,
    required this.showDebug,
  });

  @override
  Widget build(BuildContext context) {
    if (!isARInitialized || nodeManager.nodes.isNotEmpty || showDebug) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 120,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Column(
          children: [
            Icon(Icons.touch_app, color: Colors.white, size: 40),
            SizedBox(height: 8),
            Text(
              '시작하기',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              '평면을 탭해서 가구를 배치해보세요!',
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 디버그 정보 위젯 (개선된 버전 - 스크롤 가능, 큰 화면)
class DebugInfoWidget extends StatelessWidget {
  final bool showDebug;
  final NodeManager nodeManager;
  final String debugMessage;
  final VoidCallback onClose;

  const DebugInfoWidget({
    super.key,
    required this.showDebug,
    required this.nodeManager,
    required this.debugMessage,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDebug) return const SizedBox.shrink();

    return Positioned(
      top: 220,
      left: 20,
      right: 20,
      bottom: 200, // 화면 아래쪽까지 확장
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🔍 Debug Log:',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기본 정보
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Nodes: ${nodeManager.nodes.length}, Anchors: ${nodeManager.anchors.length}\n'
                            'Selected: ${nodeManager.selectedNodeName ?? "없음"}\n'
                            'Move Mode: ${nodeManager.isMoveMode}\n'
                            'Rotate Mode: ${nodeManager.isRotateMode}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 상세 디버그 메시지
                    if (debugMessage.isNotEmpty) ...[
                      const Text(
                        '📋 상세 로그:',
                        style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Text(
                          debugMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontFamily: 'monospace', // 모노스페이스 폰트로 읽기 쉽게
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 컨트롤 버튼들 위젯 (회전 기능 제거)
class ControlButtonsWidget extends StatelessWidget {
  final NodeManager nodeManager;
  final bool showDebug;
  final VoidCallback onToggleDebug;
  final VoidCallback onToggleMoveMode;
  final VoidCallback onRemoveEverything;
  final VoidCallback? onRemoveSelected;

  const ControlButtonsWidget({
    super.key,
    required this.nodeManager,
    required this.showDebug,
    required this.onToggleDebug,
    required this.onToggleMoveMode,
    required this.onRemoveEverything,
    this.onRemoveSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: FractionalOffset.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 디버그 토글
              ElevatedButton.icon(
                onPressed: onToggleDebug,
                icon: Icon(showDebug ? Icons.visibility_off : Icons.bug_report, size: 16),
                label: Text(showDebug ? "Hide Debug" : "Show Debug"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800]?.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(height: 10),

              // 이동 모드 버튼 (선택된 노드가 있을 때만 표시)
              if (nodeManager.selectedNodeName != null) ...[
                ElevatedButton.icon(
                  onPressed: onToggleMoveMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (nodeManager.isMoveMode ? Colors.orange : Colors.blue).withOpacity(0.8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: Icon(
                    nodeManager.isMoveMode ? Icons.exit_to_app : Icons.open_with,
                    size: 18,
                  ),
                  label: Text(
                    nodeManager.isMoveMode ? "Exit Move" : "Move",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // 삭제 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: onRemoveEverything,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700]?.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text("Remove All"),
                  ),
                  ElevatedButton.icon(
                    onPressed: onRemoveSelected,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (nodeManager.selectedNodeName != null ? Colors.red[500] : Colors.grey)?.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text("Remove Selected"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// AR 초기화 로딩 위젯
class ARLoadingWidget extends StatelessWidget {
  final bool isARInitialized;

  const ARLoadingWidget({
    super.key,
    required this.isARInitialized,
  });

  @override
  Widget build(BuildContext context) {
    if (isARInitialized) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'AR 초기화 중...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}