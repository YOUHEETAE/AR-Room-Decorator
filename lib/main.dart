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
            const Text(
              '나만의 공간을 디자인해보세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                '디자인 시작',
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
        title: const Text('Anchors & Objects on Planes'),
      ),
      body: Stack(children: [
        ARView(
          onARViewCreated: onARViewCreated,
          planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
        ),
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
                  ElevatedButton(
                    onPressed: () => setState(() {
                      showDebug = !showDebug;
                      debugMessage = "Nodes: ${nodeManager.nodes.map((n) => n.name).join(', ')}\nSelected: ${nodeManager.selectedNodeName}";
                    }),
                    child: Text(showDebug ? "Hide Debug" : "Show Debug"),
                  ),
                  const SizedBox(height: 10),
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
                      ElevatedButton(onPressed: onRemoveEverything, child: const Text("Remove Everything")),
                      ElevatedButton(onPressed: onRemoveSelected, child: const Text("Remove Selected")),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
      ]),
    );
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
    if (mounted) setState(() {});
  }

  Future<void> onRemoveSelected() async {
    String result = await nodeManager.removeSelected(arObjectManager, arAnchorManager);
    if (mounted) {
      setState(() {
        debugMessage = result;
        showDebug = true;
      });
    }
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
        builder: (context) => AlertDialog(
          title: const Text("노드 선택됨"),
          content: Text(nodeManager.getNodeTapDialogContent(nodeNames.first, nodeNames)),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("확인"))
          ],
        ),
      );
    }
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    try {
      var singleHitTestResult = hitTestResults.firstWhere(
              (hit) => hit.type == ARHitTestResultType.plane,
          orElse: () => hitTestResults.first);

      if (singleHitTestResult != null) {
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

        var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

        if (didAddAnchor == true) {
          nodeManager.anchors.add(newAnchor);

          var newNode = ARModelFactory.createDuckNode();

          bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

          if (didAddNodeToAnchor == true) {
            nodeManager.nodes.add(newNode);
            nodeManager.nodeAnchorMap[newNode.name] = newAnchor;
            nodeManager.nodeMap[newNode.name] = newNode;
            print("Node added successfully: ${newNode.name}");

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
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("확인"))
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
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("확인"))
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
