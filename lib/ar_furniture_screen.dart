// ar_furniture_screen.dart - 깔끔한 AR 가구 배치 화면
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';

import '../latest_node_manager.dart';
import '../ar_model_factory.dart';
import '../furniture_data.dart';
import '../furniture_selector_widget.dart';

class SimplifiedARFurnitureScreen extends StatefulWidget {
  const SimplifiedARFurnitureScreen({super.key});

  @override
  State<SimplifiedARFurnitureScreen> createState() => _SimplifiedARFurnitureScreenState();
}

class _SimplifiedARFurnitureScreenState extends State<SimplifiedARFurnitureScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final SimplifiedNodeManager nodeManager = SimplifiedNodeManager();
  final FurnitureDataManager furnitureManager = FurnitureDataManager();

  bool isARInitialized = false;
  FurnitureItem? selectedFurniture;

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 가구 배치'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FurnitureSelectorController(
        builder: (selectedFurniture, onFurnitureSelected) {
          this.selectedFurniture = selectedFurniture;

          return Stack(
            children: [
              // AR 뷰
              ARView(
                onARViewCreated: onARViewCreated,
                planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
              ),

              // AR 초기화 로딩
              if (!isARInitialized)
                Container(
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
                ),

              // 가구 선택 UI (상단)
              if (isARInitialized)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: FurnitureSelectorWidget(
                      selectedFurniture: selectedFurniture,
                      onFurnitureSelected: (furniture) {
                        onFurnitureSelected(furniture);
                        setState(() {});
                      },
                    ),
                  ),
                ),

              // 활성 노드 정보 표시
              if (nodeManager.hasActiveNode && isARInitialized)
                Positioned(
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

                        // 이동 모드 표시
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
                ),

              // 사용법 안내
              if (isARInitialized && nodeManager.totalNodes == 0)
                Positioned(
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
                ),

              // 컨트롤 버튼들
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 이동 버튼 (활성 노드가 있을 때만)
                        if (nodeManager.hasActiveNode) ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              nodeManager.toggleMoveMode();
                              setState(() {});
                            },
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
                          ),
                          const SizedBox(height: 10),
                        ],

                        // 삭제 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await nodeManager.removeAllNodes(arObjectManager, arAnchorManager);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700]?.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text("전체 삭제"),
                            ),
                            ElevatedButton.icon(
                              onPressed: nodeManager.hasActiveNode ? () async {
                                await nodeManager.removeActiveNode(arObjectManager, arAnchorManager);
                                setState(() {});
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (nodeManager.hasActiveNode ? Colors.red[500] : Colors.grey)?.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text("선택 삭제"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
      showAnimatedGuide: false,
      handleRotation: true,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isARInitialized = true);
    });
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    try {
      var singleHitTestResult = hitTestResults.firstWhere(
            (hit) => hit.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      if (singleHitTestResult != null) {
        // 이동 모드일 때는 활성 노드 이동
        if (nodeManager.isMoveMode && nodeManager.hasActiveNode) {
          bool success = await nodeManager.moveActiveNode(
              arObjectManager,
              arAnchorManager,
              singleHitTestResult
          );

          if (success) {
            setState(() {});
          }
          return;
        }

        // 일반 모드일 때는 새 노드 추가 (선택된 가구로)
        await _addNewNode(singleHitTestResult);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("가구 배치 중 오류가 발생했습니다.");
      }
    }
  }

  Future<void> _addNewNode(ARHitTestResult hitTestResult) async {
    var newAnchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      // 선택된 가구로 노드 생성
      var newNode = ARModelFactory.createSelectedFurnitureNode();
      bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

      if (didAddNodeToAnchor == true) {
        nodeManager.addNode(newNode, newAnchor);
        setState(() {});
      } else {
        if (mounted) _showErrorDialog("가구 배치에 실패했습니다.");
      }
    } else {
      if (mounted) _showErrorDialog("위치 설정에 실패했습니다.");
    }
  }

  void _showErrorDialog(String message) {
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