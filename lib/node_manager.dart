// node_manager.dart
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';

class NodeManager {
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  Map<String, ARAnchor> nodeAnchorMap = {}; // 노드 이름과 앵커를 매핑
  Map<String, ARNode> nodeMap = {}; // ID와 노드를 직접 매핑
  Map<String, String> tapIdToNodeNameMap = {}; // 탭 ID와 노드 이름 매핑
  String? selectedNodeName;
  String? selectedTapId; // 실제 탭된 ID 저장
  bool isMoveMode = false; // 이동 모드 상태

  Future<void> removeEverything(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    // 순서 중요: 먼저 노드들을 제거하고 나서 앵커를 제거
    for (var node in [...nodes]) {
      try {
        await arObjectManager?.removeNode(node);
      } catch (e) {
        print("Error removing node: $e");
      }
    }

    for (var anchor in [...anchors]) {
      try {
        await arAnchorManager?.removeAnchor(anchor);
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
    selectedNodeName = null;
    selectedTapId = null;
    isMoveMode = false;
  }

  Future<String> removeSelected(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    if (selectedNodeName != null) {
      String debugMessage = "시작: $selectedNodeName 삭제 중...";

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
        debugMessage = "정확한 매칭 실패, 마지막 생성된 노드로 시도...";
        nodeToRemove = nodes.last; // 마지막 노드 사용
      }

      if (nodeToRemove != null) {
        // 해당 노드의 앵커 찾기
        anchorToRemove = nodeAnchorMap[nodeToRemove.name];

        try {
          debugMessage = "노드 제거 중... (${nodeToRemove.name})";

          await arObjectManager?.removeNode(nodeToRemove);
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

          debugMessage = "노드 제거 완료. 앵커 제거 중...";

          if (anchorToRemove != null) {
            await arAnchorManager?.removeAnchor(anchorToRemove);
            anchors.remove(anchorToRemove);
            nodeAnchorMap.remove(nodeToRemove.name);
          }

          selectedNodeName = null;
          selectedTapId = null;
          isMoveMode = false;
          debugMessage = "✅ 삭제 완료! 남은 노드: ${nodes.length}개";

        } catch (e) {
          debugMessage = "❌ 에러: $e";
        }
      } else {
        debugMessage = "❌ 노드를 찾을 수 없음: $selectedNodeName\n현재 노드들: ${nodes.map((n) => n.name).join(', ')}";
      }

      return debugMessage;
    } else {
      return "❌ 선택된 노드가 없음";
    }
  }

  String handleNodeTap(List<String> nodeNames) {
    print("Node tapped: $nodeNames");
    print("Available nodes: ${nodes.map((n) => n.name).join(', ')}");
    printNodeDebugInfo(); // 디버깅 정보 출력

    if (nodeNames.isNotEmpty) {
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

      selectedTapId = tappedNodeId;
      selectedNodeName = actualNodeName;

      return "탭된 노드: $tappedNodeId\n실제 선택: $selectedNodeName\n사용가능 노드: ${nodes.map((n) => n.name).join(', ')}\n매핑 테이블: $tapIdToNodeNameMap";
    }

    return "";
  }

  String getNodeTapDialogContent(String tappedNodeId, List<String> nodeNames) {
    return "탭된 노드 ID: $tappedNodeId\n"
        "선택된 노드: $selectedNodeName\n"
        "총 탭된 노드 수: ${nodeNames.length}\n"
        "사용가능한 노드들: ${nodes.map((n) => n.name).join(', ')}\n"
        "현재 매핑: ${tapIdToNodeNameMap.entries.map((e) => '${e.key} -> ${e.value}').join('\n')}";
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
    print("이동 모드: $isMoveMode");
    print("========================");
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (selectedNodeName != null) {
      isMoveMode = !isMoveMode;
      print("이동 모드 ${isMoveMode ? '활성화' : '비활성화'}: $selectedNodeName");
    }
  }

  Future<bool> moveNodeToPosition(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, ARHitTestResult hitResult) async {
    if (!isMoveMode || selectedNodeName == null) {
      return false;
    }

    try {
      // 현재 선택된 노드와 앵커 찾기
      ARNode? currentNode = nodeMap[selectedNodeName];
      ARAnchor? currentAnchor = nodeAnchorMap[selectedNodeName];

      if (currentNode == null || currentAnchor == null) {
        print("이동 실패: 노드 또는 앵커를 찾을 수 없음");
        return false;
      }

      // 기존 노드와 앵커 제거
      await arObjectManager?.removeNode(currentNode);
      await arAnchorManager?.removeAnchor(currentAnchor);

      // 새로운 위치에 앵커 생성
      var newAnchor = ARPlaneAnchor(transformation: hitResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        // 새로운 위치에 노드 추가 (기존 노드 정보 유지)
        bool? didAddNodeToAnchor = await arObjectManager?.addNode(currentNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor == true) {
          // 매핑 정보 업데이트
          anchors.remove(currentAnchor);
          anchors.add(newAnchor);
          nodeAnchorMap[selectedNodeName!] = newAnchor;

          print("노드 이동 성공: $selectedNodeName");
          isMoveMode = false; // 이동 완료 후 모드 해제
          return true;
        } else {
          print("새 위치에 노드 추가 실패");
          return false;
        }
      } else {
        print("새 위치에 앵커 추가 실패");
        return false;
      }
    } catch (e) {
      print("노드 이동 중 오류: $e");
      return false;
    }
  }
}