// main.dart - 2단계 완성 버전
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
import 'ar_widgets.dart';
import 'ar_dialogs.dart';

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

  final NodeManager nodeManager = NodeManager();
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
          ARLoadingWidget(isARInitialized: isARInitialized),

          // 선택된 노드 정보
          SelectedNodeInfoWidget(nodeManager: nodeManager),

          // 사용법 안내
          InstructionsWidget(
            isARInitialized: isARInitialized,
            nodeManager: nodeManager,
            showDebug: showDebug,
          ),

          // 디버그 정보
          DebugInfoWidget(
            showDebug: showDebug,
            nodeManager: nodeManager,
            debugMessage: debugMessage,
            onClose: () => setState(() => showDebug = false),
          ),

          // 회전 컨트롤 (회전 모드일 때만 표시)
          RotationControlWidget(
            nodeManager: nodeManager,
            onRotationAction: _onRotationAction,
          ),

          // 컨트롤 버튼들
          ControlButtonsWidget(
            nodeManager: nodeManager,
            showDebug: showDebug,
            onToggleDebug: _toggleDebug,
            onToggleMoveMode: _toggleMoveMode,
            onToggleRotateMode: _toggleRotateMode,
            onRemoveEverything: _onRemoveEverything,
            onRemoveSelected: nodeManager.selectedNodeName != null ? _onRemoveSelected : null,
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
    this.arObjectManager!.onNodeTap = onNodeTapped;

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isARInitialized = true);
    });
  }

  void _toggleDebug() {
    setState(() {
      showDebug = !showDebug;
      debugMessage = "Nodes: ${nodeManager.nodes.map((n) => n.name).join(', ')}\nSelected: ${nodeManager.selectedNodeName}";
    });
  }

  void _toggleMoveMode() {
    nodeManager.toggleMoveMode();
    setState(() {});
  }

  void _toggleRotateMode() {
    nodeManager.toggleRotateMode();
    setState(() {});
  }

  // 회전 액션 처리 (3단계에서 실제 구현)
  void _onRotationAction(String action) async {
    String message = "";

    switch (action) {
      case "clockwise":
        bool success = await nodeManager.rotateNodeClockwise(arObjectManager, arAnchorManager);
        message = success ? "시계방향 회전 완료" : "회전 실패 (미구현)";
        break;
      case "counter_clockwise":
        bool success = await nodeManager.rotateNodeCounterClockwise(arObjectManager, arAnchorManager);
        message = success ? "반시계방향 회전 완료" : "회전 실패 (미구현)";
        break;
      case "reset":
        bool success = await nodeManager.setNodeRotation(arObjectManager, arAnchorManager, 0.0);
        message = success ? "회전 리셋 완료" : "회전 리셋 실패 (미구현)";
        break;
    }

    setState(() {
      debugMessage = message;
    });
  }

  Future<void> _onRemoveEverything() async {
    await nodeManager.removeEverything(arObjectManager, arAnchorManager);
    if (mounted) setState(() => debugMessage = "모든 노드가 제거되었습니다.");
  }

  Future<void> _onRemoveSelected() async {
    String result = await nodeManager.removeSelected(arObjectManager, arAnchorManager);
    if (mounted) setState(() {
      debugMessage = result;
      showDebug = true;
    });
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    if (nodeNames.isNotEmpty && mounted) {
      String result = nodeManager.handleNodeTap(nodeNames);
      setState(() => debugMessage = result);

      ARDialogs.showNodeSelectedDialog(context, nodeManager, nodeNames.first, nodeNames);
    }
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    try {
      var singleHitTestResult = hitTestResults.firstWhere(
            (hit) => hit.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      if (singleHitTestResult != null) {
        // 이동 모드일 때는 노드 이동
        if (nodeManager.isMoveMode && nodeManager.selectedNodeName != null) {
          bool success = await nodeManager.moveNodeToPosition(
              arObjectManager, arAnchorManager, singleHitTestResult);

          setState(() {
            debugMessage = success
                ? "노드 이동 완료: ${nodeManager.selectedNodeName}"
                : "노드 이동 실패";
          });
          return;
        }

        // 회전 모드일 때는 평면 탭 무시
        if (nodeManager.isRotateMode) {
          setState(() {
            debugMessage = "회전 모드에서는 컨트롤 버튼을 사용하세요";
          });
          return;
        }

        // 일반 모드일 때는 새 노드 추가
        await _addNewNode(singleHitTestResult);
      }
    } catch (e) {
      print("Error in onPlaneOrPointTapped: $e");
      if (mounted) {
        ARDialogs.showErrorDialog(context, "가구 배치 중 오류 발생: $e");
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
        nodeManager.nodes.add(newNode);
        nodeManager.nodeAnchorMap[newNode.name] = newAnchor;
        nodeManager.nodeMap[newNode.name] = newNode;
        nodeManager.initializeNodeRotation(newNode.name);
        print("Node added successfully: ${newNode.name}");

        setState(() {
          debugMessage = "새 가구 추가됨: ${newNode.name}\n총 가구 수: ${nodeManager.nodes.length}";
        });
      } else {
        if (mounted) ARDialogs.showErrorDialog(context, "앵커에 노드 추가 실패");
      }
    } else {
      if (mounted) ARDialogs.showErrorDialog(context, "앵커 추가 실패");
    }
  }
}