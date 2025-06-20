import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

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

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  Map<String, ARAnchor> nodeAnchorMap = {}; // 노드 이름과 앵커를 매핑
  Map<String, ARNode> nodeMap = {}; // ID와 노드를 직접 매핑
  Map<String, String> tapIdToNodeNameMap = {}; // 탭 ID와 노드 이름 매핑
  String? selectedNodeName;
  String? selectedTapId; // 실제 탭된 ID 저장
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
          if (selectedNodeName != null)
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
                      'Selected: $selectedNodeName',
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (selectedTapId != null)
                      Text(
                        'Tap ID: $selectedTapId',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      'Nodes: ${nodes.length}, Anchors: ${anchors.length}',
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
                        debugMessage = "Nodes: ${nodes.map((n) => n.name).join(', ')}\nSelected: $selectedNodeName";
                      }),
                      child: Text(showDebug ? "Hide Debug" : "Show Debug"),
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
    // 순서 중요: 먼저 노드들을 제거하고 나서 앵커를 제거
    for (var node in [...nodes]) {
      try {
        await this.arObjectManager?.removeNode(node);
      } catch (e) {
        print("Error removing node: $e");
      }
    }

    for (var anchor in [...anchors]) {
      try {
        await this.arAnchorManager?.removeAnchor(anchor);
      } catch (e) {
        print("Error removing anchor: $e");
      }
    }

    // 상태 초기화
    nodes.clear();
    anchors.clear();
    nodeAnchorMap.clear(); // 매핑도 클리어
    nodeMap.clear(); // 새로 추가된 매핑도 클리어
    tapIdToNodeNameMap.clear(); // 탭 ID 매핑도 클리어

    // UI 업데이트를 위한 setState 호출
    if (mounted) {
      setState(() {
        selectedNodeName = null;
        selectedTapId = null;
      });
    }
  }

  Future<void> onRemoveSelected() async {
    if (selectedNodeName != null) {
      setState(() {
        debugMessage = "시작: $selectedNodeName 삭제 중...";
        showDebug = true;
      });

      ARNode? nodeToRemove;
      ARAnchor? anchorToRemove;

      // 선택된 노드 찾기 - 더 정확한 매칭
      for (var node in [...nodes]) {
        if (node.name == selectedNodeName) {
          nodeToRemove = node;
          break;
        }
      }

      // 노드를 찾지 못한 경우 nodeMap에서 시도
      if (nodeToRemove == null) {
        nodeToRemove = nodeMap[selectedNodeName];
      }

      // 여전히 찾지 못한 경우 마지막 노드로 시도 (임시 해결책)
      if (nodeToRemove == null && nodes.isNotEmpty) {
        setState(() {
          debugMessage = "정확한 매칭 실패, 마지막 생성된 노드로 시도...";
        });
        nodeToRemove = nodes.last; // 마지막 노드 사용
      }

      if (nodeToRemove != null) {
        // 해당 노드의 앵커 찾기
        anchorToRemove = nodeAnchorMap[nodeToRemove.name];

        try {
          setState(() {
            debugMessage = "노드 제거 중... (${nodeToRemove!.name})";
          });

          await this.arObjectManager?.removeNode(nodeToRemove);
          nodes.remove(nodeToRemove);
          nodeMap.remove(nodeToRemove.name); // 매핑에서도 제거

          // 탭 ID 매핑에서도 제거
          String? tapIdToRemove;
          tapIdToNodeNameMap.forEach((tapId, nodeName) {
            if (nodeName == nodeToRemove?.name) {
              tapIdToRemove = tapId;
            }
          });
          if (tapIdToRemove != null) {
            tapIdToNodeNameMap.remove(tapIdToRemove);
          }

          setState(() {
            debugMessage = "노드 제거 완료. 앵커 제거 중...";
          });

          if (anchorToRemove != null) {
            await this.arAnchorManager?.removeAnchor(anchorToRemove);
            anchors.remove(anchorToRemove);
            nodeAnchorMap.remove(nodeToRemove.name);
          }

          setState(() {
            selectedNodeName = null;
            selectedTapId = null;
            debugMessage = "✅ 삭제 완료! 남은 노드: ${nodes.length}개";
          });

        } catch (e) {
          setState(() {
            debugMessage = "❌ 에러: $e";
          });
        }
      } else {
        setState(() {
          debugMessage = "❌ 노드를 찾을 수 없음: $selectedNodeName\n현재 노드들: ${nodes.map((n) => n.name).join(', ')}";
        });
      }
    } else {
      setState(() {
        debugMessage = "❌ 선택된 노드가 없음";
        showDebug = true;
      });
    }
  }

  Future<void> onNodeTapped(List<String> nodeNames) async {
    print("Node tapped: $nodeNames");
    print("Available nodes: ${nodes.map((n) => n.name).join(', ')}");
    printNodeDebugInfo(); // 디버깅 정보 출력

    if (nodeNames.isNotEmpty && mounted) {
      String tappedNodeId = nodeNames.first;

      // 매핑 테이블에서 실제 노드 이름 찾기
      String? actualNodeName = tapIdToNodeNameMap[tappedNodeId];

      // 매핑이 없으면 순서대로 매핑 시도 (노드 추가 순서 기준)
      if (actualNodeName == null && nodes.isNotEmpty) {
        // 현재 탭 ID 목록에서 인덱스 찾기
        List<String> allTapIds = tapIdToNodeNameMap.keys.toList();

        // 새로운 탭 ID인 경우, 가장 최근 노드와 매핑
        if (!allTapIds.contains(tappedNodeId)) {
          // 아직 매핑되지 않은 노드 찾기
          for (var node in nodes.reversed) {
            if (!tapIdToNodeNameMap.containsValue(node.name)) {
              actualNodeName = node.name;
              tapIdToNodeNameMap[tappedNodeId] = actualNodeName;
              print("새로운 매핑 생성: $tappedNodeId -> $actualNodeName");
              break;
            }
          }
        }
      }

      // 여전히 찾지 못한 경우 마지막 노드 선택
      if (actualNodeName == null && nodes.isNotEmpty) {
        actualNodeName = nodes.last.name;
        tapIdToNodeNameMap[tappedNodeId] = actualNodeName;
      }

      setState(() {
        selectedTapId = tappedNodeId;
        selectedNodeName = actualNodeName;
        debugMessage = "탭된 노드: $tappedNodeId\n실제 선택: $selectedNodeName\n사용가능 노드: ${nodes.map((n) => n.name).join(', ')}\n매핑 테이블: $tapIdToNodeNameMap";
        showDebug = true;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("노드 선택됨"),
            content: Text(
                "탭된 노드 ID: $tappedNodeId\n"
                    "선택된 노드: $selectedNodeName\n"
                    "총 탭된 노드 수: ${nodeNames.length}\n"
                    "사용가능한 노드들: ${nodes.map((n) => n.name).join(', ')}\n"
                    "현재 매핑: ${tapIdToNodeNameMap.entries.map((e) => '${e.key} -> ${e.value}').join('\n')}"
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

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    try {
      var singleHitTestResult = hitTestResults.firstWhere(
              (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane,
          orElse: () => hitTestResults.first);

      if (singleHitTestResult != null) {
        var newAnchor =
        ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        bool? didAddAnchor = await this.arAnchorManager?.addAnchor(newAnchor);

        if (didAddAnchor == true) {
          anchors.add(newAnchor);

          // 고유한 노드 이름 생성 (타임스탬프 포함)
          String nodeName = "duck_${DateTime.now().millisecondsSinceEpoch}";

          var newNode = ARNode(
              type: NodeType.webGLB,
              uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Duck/glTF-Binary/Duck.glb",
              scale: vm.Vector3(0.2, 0.2, 0.2),
              position: vm.Vector3(0.0, 0.0, 0.0),
              rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
              name: nodeName);

          bool? didAddNodeToAnchor = await this
              .arObjectManager
              ?.addNode(newNode, planeAnchor: newAnchor);

          if (didAddNodeToAnchor == true) {
            nodes.add(newNode);
            nodeAnchorMap[nodeName] = newAnchor; // 노드와 앵커 매핑 저장
            nodeMap[nodeName] = newNode; // 노드 직접 매핑도 저장
            print("Node added successfully: $nodeName");

            // 디버그 정보 업데이트
            setState(() {
              debugMessage = "새 노드 추가됨: $nodeName\n총 노드 수: ${nodes.length}";
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

  // 추가적인 디버깅을 위한 메서드
  void printNodeDebugInfo() {
    print("=== 노드 디버그 정보 ===");
    print("총 노드 수: ${nodes.length}");
    print("총 앵커 수: ${anchors.length}");
    print("선택된 노드: $selectedNodeName");

    for (int i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      print("노드 $i: 이름=${node.name}, 타입=${node.type}");
    }

    print("노드-앵커 매핑: $nodeAnchorMap");
    print("노드 직접 매핑: ${nodeMap.keys.toList()}");
    print("탭 ID 매핑: $tapIdToNodeNameMap");
    print("선택된 탭 ID: $selectedTapId");
    print("========================");
  }
}