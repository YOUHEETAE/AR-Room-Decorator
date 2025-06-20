// main.dart - 위치 기반 노드 매핑 버전
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

import 'node_manager.dart'; // 새로운 위치 기반 매니저
import 'ar_model_factory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR Position-Based Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ObjectsOnPlanes(),
    );
  }
}

class ObjectsOnPlanes extends StatefulWidget {
  const ObjectsOnPlanes({
    super.key,
    this.width,
    this.height,
  });

  final double? width;
  final double? height;

  @override
  State<ObjectsOnPlanes> createState() => _ObjectsOnPlanesState();
}

class _ObjectsOnPlanesState extends State<ObjectsOnPlanes> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final PositionBasedNodeManager nodeManager = PositionBasedNodeManager(); // 새로운 매니저 사용
  bool isARInitialized = false;

  // 디버깅용 상태 추가
  String debugMessage = "";
  bool showDebug = false;

  // 노드 탭할 때의 히트 결과를 저장하기 위한 변수
  List<ARHitTestResult>? lastHitResults;

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Position-Based Node Selection'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Stack(children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          // AR 초기화 로딩 표시
          if (!isARInitialized)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AR 초기화 중...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          // 선택된 노드 정보 표시
          if (nodeManager.selectedNodeName != null)
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${nodeManager.selectedNodeName}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Nodes: ${nodeManager.nodeCount}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    if (nodeManager.isMoveMode)
                      const Text(
                        'MOVE MODE - 평면을 탭하여 이동',
                        style: TextStyle(color: Colors.yellow, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            ),
          // 디버그 정보 표시
          if (showDebug)
            Positioned(
              top: 200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Debug Info:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      nodeManager.getDebugInfo(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    Text(
                      debugMessage,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () => setState(() => showDebug = false),
                      child: const Text('Close', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 디버그 토글 버튼
                    ElevatedButton(
                      onPressed: () => setState(() {
                        showDebug = !showDebug;
                        debugMessage = "위치 기반 매핑 시스템 활성";
                      }),
                      child: Text(showDebug ? "Hide Debug" : "Show Debug"),
                    ),
                    const SizedBox(height: 10),
                    // Move Mode 버튼
                    if (nodeManager.selectedNodeName != null)
                      ElevatedButton(
                        onPressed: () {
                          nodeManager.toggleMoveMode();
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nodeManager.isMoveMode ? Colors.orange : Colors.blue,
                        ),
                        child: Text(nodeManager.isMoveMode ? "Exit Move Mode" : "Move Mode"),
                      ),
                    const SizedBox(height: 10),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: onRemoveEverything,
                              child: const Text("Remove Everything")),
                          ElevatedButton(
                              onPressed: onRemoveSelected,
                              child: const Text("Remove Selected")),
                        ]),
                    const SizedBox(height: 10),
                    // 위치 기반 매핑 안내
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Text(
                        "🎯 위치 기반 매핑 활성\n노드를 탭하면 가장 가까운 노드가 선택됩니다",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ]));
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
    );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onNodeTap = onNodeTapped;

    // AR 초기화 완료 표시
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          isARInitialized = true;
        });
      }
    });
  }

  Future<void> onRemoveEverything() async {
    await nodeManager.removeEverything(arObjectManager, arAnchorManager);

    if (mounted) {
      setState(() {
        debugMessage = "모든 노드 제거 완료";
      });
    }
  }

  Future<void> onRemoveSelected() async {
    String result = await nodeManager.removeSelected(arObjectManager, arAnchorManager);

    setState(() {
      debugMessage = result;
      showDebug = true;
    });
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    if (nodeNames.isNotEmpty && mounted) {
      print("\n🎯 노드 탭 이벤트 발생");
      print("탭된 ID들: $nodeNames");

      // 위치 기반 매핑 시도 (히트 결과가 있다면)
      String result = nodeManager.handleNodeTapWithPosition(nodeNames, lastHitResults);

      setState(() {
        debugMessage = result;
        showDebug = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("위치 기반 노드 선택"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("선택된 노드: ${nodeManager.selectedNodeName ?? 'None'}"),
                const SizedBox(height: 8),
                Text("탭된 노드 ID: ${nodeNames.first}"),
                const SizedBox(height: 8),
                Text("총 노드 수: ${nodeManager.nodeCount}"),
                const SizedBox(height: 8),
                Text("매핑 결과:"),
                Text(result, style: const TextStyle(fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("확인"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    // 히트 결과를 저장 (노드 탭 시 사용하기 위해)
    lastHitResults = hitTestResults;

    try {
      var singleHitTestResult = hitTestResults.firstWhere(
              (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
          orElse: () => hitTestResults.first);

      if (singleHitTestResult != null) {
        // Move Mode일 때는 선택된 노드 이동
        if (nodeManager.isMoveMode && nodeManager.selectedNodeName != null) {
          bool success = await nodeManager.moveNodeToPosition(
              arObjectManager,
              arAnchorManager,
              singleHitTestResult
          );

          if (success) {
            setState(() {
              debugMessage = "노드 이동 완료: ${nodeManager.selectedNodeName}";
            });
          } else {
            setState(() {
              debugMessage = "노드 이동 실패";
            });
          }
          return;
        }

        // 일반 모드일 때는 새 노드 생성
        var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        bool? didAddAnchor = await this.arAnchorManager?.addAnchor(newAnchor);

        if (didAddAnchor == true) {
          var newNode = ARModelFactory.createDuckNode();

          bool? didAddNodeToAnchor = await this
              .arObjectManager
              ?.addNode(newNode, planeAnchor: newAnchor);

          if (didAddNodeToAnchor == true) {
            // 위치 기반 매니저에 노드 추가 (위치 정보 포함)
            nodeManager.addNode(newNode, newAnchor, singleHitTestResult.worldTransform);

            print("Node added successfully: ${newNode.name}");

            // 디버그 정보 업데이트
            setState(() {
              debugMessage = "새 노드 추가됨: ${newNode.name}\n총 노드 수: ${nodeManager.nodeCount}";
            });
          } else {
            // 노드 추가 실패 시 앵커 제거
            await arAnchorManager?.removeAnchor(newAnchor);

            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("오류"),
                  content: const Text("앵커에 노드 추가 실패"),
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
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("오류"),
                content: const Text("앵커 추가 실패"),
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
      }
    } catch (e) {
      print("Error in onPlaneOrPointTapped: $e");
      if (mounted) {
        setState(() {
          debugMessage = "오류 발생: $e";
        });
      }
    }
  }
}