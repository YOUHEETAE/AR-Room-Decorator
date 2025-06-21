// main.dart - 최신 노드 조작 방식으로 업데이트
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

import 'latest_node_manager.dart'; // 새로운 매니저 import
import 'ar_model_factory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR 방꾸미기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InitialARScreen(),
    );
  }
}

class InitialARScreen extends StatelessWidget {
  const InitialARScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_in_ar, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              'AR 방꾸미기',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              '나만의 공간을 디자인해보세요',
              style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ObjectsOnPlanes()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 5,
              ),
              child: const Text(
                '디자인 시작하기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectsOnPlanes extends StatefulWidget {
  const ObjectsOnPlanes({super.key});

  @override
  State<ObjectsOnPlanes> createState() => _ObjectsOnPlanesState();
}

class _ObjectsOnPlanesState extends State<ObjectsOnPlanes> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final LatestNodeManager nodeManager = LatestNodeManager(); // 새로운 매니저 사용
  bool isARInitialized = false;
  String debugMessage = "";
  bool showDebug = false;

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
      body: Stack(
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

          // 활성 노드 정보 표시
          if (nodeManager.hasActiveNode)
            Positioned(
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
                      '🎯 활성 노드: ${nodeManager.activeNodeName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '총 ${nodeManager.totalNodes}개 노드',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    const SizedBox(height: 8),

                    // 이동 모드 표시
                    if (nodeManager.isMoveMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '🚀 이동 모드 - 평면을 탭하세요',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // 사용법 안내
          if (isARInitialized && nodeManager.totalNodes == 0 && !showDebug)
            Positioned(
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
                      '평면을 탭해서 가구를 배치해보세요!\n가장 최근에 추가한 가구를 조작할 수 있습니다.',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // 디버그 정보
          if (showDebug)
            Positioned(
              top: 220,
              left: 20,
              right: 20,
              bottom: 200,
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
                          onPressed: () => setState(() => showDebug = false),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Total Nodes: ${nodeManager.totalNodes}\n'
                                    'Active Node: ${nodeManager.activeNodeName}\n'
                                    'Move Mode: ${nodeManager.isMoveMode}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
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
                                    fontFamily: 'monospace',
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
                    // 디버그 토글
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showDebug = !showDebug;
                          nodeManager.printStatus();
                        });
                      },
                      icon: Icon(showDebug ? Icons.visibility_off : Icons.bug_report, size: 16),
                      label: Text(showDebug ? "Hide Debug" : "Show Debug"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800]?.withOpacity(0.7),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 10),

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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        icon: Icon(
                          nodeManager.isMoveMode ? Icons.exit_to_app : Icons.open_with,
                          size: 18,
                        ),
                        label: Text(
                          nodeManager.isMoveMode ? "Exit Move" : "Move Active",
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
                            setState(() {
                              debugMessage = "모든 노드 삭제 완료";
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700]?.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text("Remove All"),
                        ),
                        ElevatedButton.icon(
                          onPressed: nodeManager.hasActiveNode ? () async {
                            String result = await nodeManager.removeActiveNode(arObjectManager, arAnchorManager);
                            setState(() {
                              debugMessage = result;
                              showDebug = true;
                            });
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (nodeManager.hasActiveNode ? Colors.red[500] : Colors.grey)?.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.delete, size: 18),
                          label: const Text("Remove Active"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    // onNodeTap은 더 이상 사용하지 않음 (매핑 문제로 인해)

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

          setState(() {
            debugMessage = success
                ? "✅ 노드 이동 완료: ${nodeManager.activeNodeName}"
                : "❌ 노드 이동 실패";
          });
          return;
        }

        // 일반 모드일 때는 새 노드 추가
        await _addNewNode(singleHitTestResult);
      }
    } catch (e) {
      print("Error in onPlaneOrPointTapped: $e");
      if (mounted) {
        _showErrorDialog("가구 배치 중 오류 발생: $e");
      }
    }
  }

  Future<void> _addNewNode(ARHitTestResult hitTestResult) async {
    var newAnchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      var newNode = ARModelFactory.createDuckNode();
      bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

      if (didAddNodeToAnchor == true) {
        nodeManager.addNode(newNode, newAnchor);

        setState(() {
          debugMessage = "✅ 새 가구 추가: ${newNode.name}\n🎯 활성 노드: ${nodeManager.activeNodeName}\n총 ${nodeManager.totalNodes}개";
        });
      } else {
        if (mounted) _showErrorDialog("앵커에 노드 추가 실패");
      }
    } else {
      if (mounted) _showErrorDialog("앵커 추가 실패");
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