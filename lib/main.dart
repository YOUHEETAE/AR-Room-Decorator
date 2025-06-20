// main.dart
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

import 'node_manager.dart';
import 'ar_model_factory.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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

  final NodeManager nodeManager = NodeManager();
  bool isARInitialized = false;

  // 디버깅용 상태 추가
  String debugMessage = "";
  bool showDebug = false;

  @override
  void dispose() {
    super.dispose();
    arSessionManager?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Anchors & Objects on Planes'),
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
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (nodeManager.selectedTapId != null)
                      Text(
                        'Tap ID: ${nodeManager.selectedTapId}',
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
              top: 150,
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
                      'Nodes: ${nodeManager.nodes.length}, Anchors: ${nodeManager.anchors.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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
                        debugMessage = "Nodes: ${nodeManager.nodes.map((n) => n.name).join(', ')}\nSelected: ${nodeManager.selectedNodeName}";
                      }),
                      child: Text(showDebug ? "Hide Debug" : "Show Debug"),
                    ),
                    const SizedBox(height: 10),
                    // Move Mode 버튼 추가
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

    // UI 업데이트를 위한 setState 호출
    if (mounted) {
      setState(() {});
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
      String result = nodeManager.handleNodeTap(nodeNames);

      setState(() {
        debugMessage = result;
        showDebug = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("노드 선택됨"),
            content: Text(nodeManager.getNodeTapDialogContent(nodeNames.first, nodeNames)),
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

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
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
        var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        bool? didAddAnchor = await this.arAnchorManager?.addAnchor(newAnchor);

        if (didAddAnchor == true) {
          nodeManager.anchors.add(newAnchor);

          var newNode = ARModelFactory.createDuckNode();

          bool? didAddNodeToAnchor = await this
              .arObjectManager
              ?.addNode(newNode, planeAnchor: newAnchor);

          if (didAddNodeToAnchor == true) {
            nodeManager.nodes.add(newNode);
            nodeManager.nodeAnchorMap[newNode.name] = newAnchor; // 노드와 앵커 매핑 저장
            nodeManager.nodeMap[newNode.name] = newNode; // 노드 직접 매핑도 저장
            print("Node added successfully: ${newNode.name}");

            // 디버그 정보 업데이트
            setState(() {
              debugMessage = "새 노드 추가됨: ${newNode.name}\n총 노드 수: ${nodeManager.nodes.length}";
            });
          } else {
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
    }
  }
}