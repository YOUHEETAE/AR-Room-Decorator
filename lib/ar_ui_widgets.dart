// lib/ar_ui_widgets.dart - 단순화된 회전 기능
import 'package:flutter/material.dart';
import 'furniture_data.dart';
import 'furniture_selector_widget.dart';
import 'simplified_node_manager.dart';

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

// 사용법 안내 (회전 기능 포함)
class ARUsageGuide extends StatelessWidget {
  final FurnitureItem? selectedFurniture;

  const ARUsageGuide({super.key, required this.selectedFurniture});

  @override
  Widget build(BuildContext context) {
    final bool isRotatable = selectedFurniture?.isRotatable ?? false;

    return Positioned(
      top: 200,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              selectedFurniture?.category.icon ?? Icons.touch_app,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(height: 12),
            const Text(
              '시작하기',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              '위에서 원하는 가구를 선택하고\n평면을 탭해서 배치해보세요!${isRotatable ? '\n\n회전 가능한 가구입니다 🔄' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 단순화된 고정 위치 컨트롤 (회전 파라미터 제거됨)
class ARSimpleBottomControls extends StatelessWidget {
  final SimplifiedNodeManager nodeManager;
  final bool isARInitialized;
  final VoidCallback onScreenshot;
  final VoidCallback onToggleMove;
  final VoidCallback onToggleScale;
  final VoidCallback onRotateClockwise;  // 시계방향 회전만
  final VoidCallback onScaleUp;
  final VoidCallback onScaleDown;
  final VoidCallback onRemoveAll;
  final VoidCallback onRemoveActive;

  const ARSimpleBottomControls({
    super.key,
    required this.nodeManager,
    required this.isARInitialized,
    required this.onScreenshot,
    required this.onToggleMove,
    required this.onToggleScale,
    required this.onRotateClockwise,  // 하나의 회전 콜백만
    required this.onScaleUp,
    required this.onScaleDown,
    required this.onRemoveAll,
    required this.onRemoveActive,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 모드별 컨트롤 버튼들 (화면 중앙)
        if (nodeManager.hasActiveNode && isARInitialized)
          _buildModeControls(),

        // 하단 컨트롤 바
        _buildBottomControlBar(),
      ],
    );
  }

  // 모드별 컨트롤 버튼들
  Widget _buildModeControls() {
    return Positioned(
      bottom: 200,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 이동 버튼
          _buildControlButton(
            icon: Icons.open_with,
            isActive: nodeManager.isMoveMode,
            onPressed: onToggleMove,
            label: '이동',
          ),

          // 크기 조절 영역
          _buildScaleControls(),

          // 회전 영역 - 단순화됨
          if (nodeManager.canActiveNodeRotate)
            _buildControlButton(
              icon: Icons.rotate_right,
              isActive: false, // 항상 비활성 상태로 표시 (토글 모드 없음)
              onPressed: onRotateClockwise, // 바로 회전 실행
              label: '회전',
            ),
        ],
      ),
    );
  }

  // 크기 조절 컨트롤
  Widget _buildScaleControls() {
    return Column(
      children: [
        // 확대 버튼 (크기 모드일 때만)
        if (nodeManager.isScaleMode)
          _buildSmallButton(
            icon: Icons.add,
            onPressed: onScaleUp,
          ),

        if (nodeManager.isScaleMode)
          const SizedBox(height: 12),

        // 크기 메인 버튼
        _buildControlButton(
          icon: Icons.height,
          isActive: nodeManager.isScaleMode,
          onPressed: onToggleScale,
          label: '크기',
        ),

        if (nodeManager.isScaleMode)
          const SizedBox(height: 12),

        // 축소 버튼 (크기 모드일 때만)
        if (nodeManager.isScaleMode)
          _buildSmallButton(
            icon: Icons.remove,
            onPressed: onScaleDown,
          ),
      ],
    );
  }

  // 하단 컨트롤 바
  Widget _buildBottomControlBar() {
    return Align(
      alignment: FractionalOffset.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 전체 삭제 버튼
                if (isARInitialized && nodeManager.totalNodes > 0)
                  _buildBottomButton(
                    icon: Icons.delete_sweep,
                    onPressed: onRemoveAll,
                    isDestructive: true,
                  ),

                if (isARInitialized && nodeManager.totalNodes > 0)
                  const SizedBox(width: 16),

                // 선택 삭제 버튼
                if (nodeManager.hasActiveNode && isARInitialized)
                  _buildBottomButton(
                    icon: Icons.delete_outline,
                    onPressed: onRemoveActive,
                    isDestructive: true,
                  ),

                if (nodeManager.hasActiveNode && isARInitialized)
                  const SizedBox(width: 20),

                // 카메라 버튼 (메인)
                _buildCameraButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 메인 컨트롤 버튼 (라벨 추가)
  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
              border: Border.all(
                color: isActive
                    ? Colors.white.withOpacity(0.6)
                    : Colors.white.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
                if (isActive)
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
              ],
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // 작은 +/- 버튼
  Widget _buildSmallButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }

  // 하단 일반 버튼
  Widget _buildBottomButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDestructive,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? Colors.red.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          size: 20,
        ),
      ),
    );
  }

  // 카메라 버튼 (메인)
  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: onScreenshot,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.95),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
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
            // 내부 링
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
            // 카메라 아이콘
            const Icon(
              Icons.camera_alt,
              size: 28,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}