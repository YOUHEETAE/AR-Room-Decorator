// node_selection_handler.dart - 노드 선택 처리
import 'node_state.dart';

class NodeSelectionHandler {
  final NodeState state;

  NodeSelectionHandler(this.state);

  // 노드 탭 처리
  String handleNodeTap(List<String> nodeNames) {
    print("Node tapped: $nodeNames");
    print("Available nodes: ${state.nodes.map((n) => n.name).join(', ')}");
    state.printDebugInfo();

    if (nodeNames.isNotEmpty) {
      String tappedNodeId = nodeNames.first;
      String? actualNodeName = _findActualNodeName(tappedNodeId);

      state.selectNode(actualNodeName, tappedNodeId);

      return "탭된 노드: $tappedNodeId\n실제 선택: $actualNodeName\n사용가능 노드: ${state.nodes.map((n) => n.name).join(', ')}\n매핑 테이블: ${state.tapIdToNodeNameMap}";
    }

    return "";
  }

  // 노드 탭 다이얼로그 내용
  String getNodeTapDialogContent(String tappedNodeId, List<String> nodeNames) {
    double currentRotation = state.getSelectedNodeRotation();
    return "탭된 노드 ID: $tappedNodeId\n"
        "선택된 노드: ${state.selectedNodeName}\n"
        "현재 회전: ${currentRotation.toStringAsFixed(1)}°\n"
        "총 탭된 노드 수: ${nodeNames.length}\n"
        "사용가능한 노드들: ${state.nodes.map((n) => n.name).join(', ')}\n"
        "현재 매핑: ${state.tapIdToNodeNameMap.entries.map((e) => '${e.key} -> ${e.value}').join('\n')}";
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (state.selectedNodeName != null) {
      state.isMoveMode = !state.isMoveMode;
      if (state.isMoveMode) {
        state.isRotateMode = false; // 이동 모드 시 회전 모드 해제
      }
      print("이동 모드 ${state.isMoveMode ? '활성화' : '비활성화'}: ${state.selectedNodeName}");
    }
  }

  // 회전 모드 토글
  void toggleRotateMode() {
    if (state.selectedNodeName != null) {
      state.isRotateMode = !state.isRotateMode;
      if (state.isRotateMode) {
        state.isMoveMode = false; // 회전 모드 시 이동 모드 해제
      }
      print("회전 모드 ${state.isRotateMode ? '활성화' : '비활성화'}: ${state.selectedNodeName}");
    }
  }

  // 실제 노드 이름 찾기
  String? _findActualNodeName(String tappedNodeId) {
    // 매핑 테이블에서 실제 노드 이름 찾기
    String? actualNodeName = state.tapIdToNodeNameMap[tappedNodeId];

    // 매핑이 없으면 순서대로 매핑 시도
    if (actualNodeName == null && state.nodes.isNotEmpty) {
      List<String> allTapIds = state.tapIdToNodeNameMap.keys.toList();

      // 새로운 탭 ID인 경우, 가장 최근 노드와 매핑
      if (!allTapIds.contains(tappedNodeId)) {
        // 아직 매핑되지 않은 노드 찾기
        for (var node in state.nodes.reversed) {
          if (!state.tapIdToNodeNameMap.containsValue(node.name)) {
            actualNodeName = node.name;
            state.tapIdToNodeNameMap[tappedNodeId] = actualNodeName;
            print("새로운 매핑 생성: $tappedNodeId -> $actualNodeName");
            break;
          }
        }
      }
    }

    // 여전히 찾지 못한 경우 마지막 노드 선택
    if (actualNodeName == null && state.nodes.isNotEmpty) {
      actualNodeName = state.nodes.last.name;
      state.tapIdToNodeNameMap[tappedNodeId] = actualNodeName;
    }

    return actualNodeName;
  }
}