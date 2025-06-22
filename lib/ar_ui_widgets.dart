import 'package:flutter/material.dart';
import 'furniture_data.dart';
import 'furniture_selector_widget.dart';
import 'simplified_node_manager.dart';

// AR 앱바
class ARAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBackPressed;

  const ARAppBar({super.key, required this.onBackPressed});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('AR 가구 배치'),
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.5),
        ),
        child: IconButton(
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          padding: EdgeInsets.zero,
        ),
      ),
      automaticallyImplyLeading: false,
    );
  }
}

// AR 로딩 화면
class ARLoadingScreen extends StatelessWidget {
  final String message;

  const ARLoadingScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// 상단 가구 선택기 오버레이
class ARFurnitureSelectorOverlay extends StatelessWidget {
  final FurnitureItem? selectedFurniture;
  final Function(FurnitureItem) onFurnitureSelected;

  const ARFurnitureSelectorOverlay({
    super.key,
    required this.selectedFurniture,
    required this.onFurnitureSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: FurnitureSelectorWidget(
          selectedFurniture: selectedFurniture,
          onFurnitureSelected: onFurnitureSelected,
        ),
      ),
    );
  }
}

// 활성 노드 정보
class ARActiveNodeInfo extends StatelessWidget {
  final SimplifiedNodeManager nodeManager;
  final FurnitureItem? selectedFurniture;

  const ARActiveNodeInfo({
    super.key,
    required this.nodeManager,
    required this.selectedFurniture,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 160,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black87.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selectedFurniture?.category.icon ?? Icons.chair,
                  color: selectedFurniture?.category.color ?? Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '활성 가구: ${selectedFurniture?.id ?? "없음"}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              '총 ${nodeManager.totalNodes}개 배치됨',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            if (nodeManager.isMoveMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '이동 모드 - 평면을 탭하세요',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// 사용법 안내
class ARUsageGuide extends StatelessWidget {
  final FurnitureItem? selectedFurniture;

  const ARUsageGuide({super.key, required this.selectedFurniture});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            Icon(
              selectedFurniture?.category.icon ?? Icons.touch_app,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              '시작하기',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              '위에서 원하는 가구를 선택하고\n평면을 탭해서 배치해보세요!',
              style: TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 하단 컨트롤
class ARBottomControls extends StatelessWidget {
  final SimplifiedNodeManager nodeManager;
  final bool isARInitialized;
  final VoidCallback onScreenshot;
  final VoidCallback onToggleMove;
  final VoidCallback onRemoveAll;
  final VoidCallback onRemoveActive;

  const ARBottomControls({
    super.key,
    required this.nodeManager,
    required this.isARInitialized,
    required this.onScreenshot,
    required this.onToggleMove,
    required this.onRemoveAll,
    required this.onRemoveActive,
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
              // 카메라 버튼
              _buildCameraButton(),
              const SizedBox(height: 16),

              // 이동 버튼
              if (nodeManager.hasActiveNode && isARInitialized) ...[
                _buildMoveButton(),
                const SizedBox(height: 10),
              ],

              // 삭제 버튼들
              if (isARInitialized) _buildDeleteButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: onScreenshot,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
              ),
            ),
            const Icon(Icons.camera_alt, size: 28, color: Colors.black87),
          ],
        ),
      ),
    );
  }

  Widget _buildMoveButton() {
    return ElevatedButton.icon(
      onPressed: onToggleMove,
      style: ElevatedButton.styleFrom(
        backgroundColor: (nodeManager.isMoveMode ? Colors.orange : Colors.blue).withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(
        nodeManager.isMoveMode ? Icons.exit_to_app : Icons.open_with,
        size: 18,
      ),
      label: Text(
        nodeManager.isMoveMode ? "이동 완료" : "가구 이동",
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildDeleteButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: onRemoveAll,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700]?.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.clear_all, size: 18),
          label: const Text("전체 삭제"),
        ),
        ElevatedButton.icon(
          onPressed: nodeManager.hasActiveNode ? onRemoveActive : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: (nodeManager.hasActiveNode ? Colors.red[500] : Colors.grey)?.withOpacity(0.8),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.delete, size: 18),
          label: const Text("선택 삭제"),
        ),
      ],
    );
  }
}
