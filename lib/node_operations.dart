// node_operations.dart - 노드 작업들
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'node_state.dart';

class NodeOperations {
  final NodeState state;

  NodeOperations(this.state);

  // 모든 노드 제거
  Future<void> removeEverything(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    for (var node in [...state.nodes]) {
      try {
        await arObjectManager?.removeNode(node);
      } catch (e) {
        print("Error removing node: $e");
      }
    }

    for (var anchor in [...state.anchors]) {
      try {
        await arAnchorManager?.removeAnchor(anchor);
      } catch (e) {
        print("Error removing anchor: $e");
      }
    }

    state.clearAll();
  }

  // 선택된 노드 제거
  Future<String> removeSelected(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    if (state.selectedNodeName == null) {
      return "❌ 선택된 노드가 없음";
    }

    String debugMessage = "시작: ${state.selectedNodeName} 삭제 중...";
    ARNode? nodeToRemove = _findNodeToRemove();

    if (nodeToRemove != null) {
      try {
        debugMessage = "노드 제거 중... (${nodeToRemove.name})";

        await arObjectManager?.removeNode(nodeToRemove);

        ARAnchor? anchorToRemove = state.nodeAnchorMap[nodeToRemove.name];
        if (anchorToRemove != null) {
          await arAnchorManager?.removeAnchor(anchorToRemove);
        }

        state.removeNode(nodeToRemove);
        debugMessage = "✅ 삭제 완료! 남은 노드: ${state.nodes.length}개";

      } catch (e) {
        debugMessage = "❌ 에러: $e";
      }
    } else {
      debugMessage = "❌ 노드를 찾을 수 없음: ${state.selectedNodeName}\n현재 노드들: ${state.nodes.map((n) => n.name).join(', ')}";
    }

    return debugMessage;
  }

  // 노드 이동
  Future<bool> moveNodeToPosition(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, ARHitTestResult hitResult) async {
    if (!state.isMoveMode || state.selectedNodeName == null) {
      return false;
    }

    try {
      ARNode? currentNode = state.nodeMap[state.selectedNodeName];
      ARAnchor? currentAnchor = state.nodeAnchorMap[state.selectedNodeName];

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
        bool? didAddNodeToAnchor = await arObjectManager?.addNode(currentNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor == true) {
          // 상태 업데이트
          state.anchors.remove(currentAnchor);
          state.anchors.add(newAnchor);
          state.nodeAnchorMap[state.selectedNodeName!] = newAnchor;

          print("노드 이동 성공: ${state.selectedNodeName}");
          state.isMoveMode = false;
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

  // 제거할 노드 찾기
  ARNode? _findNodeToRemove() {
    // 선택된 노드 찾기
    for (var node in [...state.nodes]) {
      if (node.name == state.selectedNodeName) {
        return node;
      }
    }

    // nodeMap에서 시도
    ARNode? nodeToRemove = state.nodeMap[state.selectedNodeName];
    if (nodeToRemove != null) return nodeToRemove;

    // 마지막 노드로 시도 (임시 해결책)
    if (state.nodes.isNotEmpty) {
      return state.nodes.last;
    }

    return null;
  }
}