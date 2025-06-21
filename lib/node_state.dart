// node_state.dart - 노드 상태 관리
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';

class NodeState {
  // 노드 데이터
  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  Map<String, ARAnchor> nodeAnchorMap = {};
  Map<String, ARNode> nodeMap = {};
  Map<String, String> tapIdToNodeNameMap = {};

  // 선택 상태
  String? selectedNodeName;
  String? selectedTapId;

  // 모드 상태
  bool isMoveMode = false;
  bool isRotateMode = false; // 회전 모드 추가

  // 회전 데이터
  Map<String, double> nodeRotations = {};

  // 모든 상태 초기화
  void clearAll() {
    nodes.clear();
    anchors.clear();
    nodeAnchorMap.clear();
    nodeMap.clear();
    tapIdToNodeNameMap.clear();
    nodeRotations.clear();
    selectedNodeName = null;
    selectedTapId = null;
    isMoveMode = false;
    isRotateMode = false; // 회전 모드도 초기화
  }

  // 노드 추가
  void addNode(ARNode node, ARAnchor anchor) {
    nodes.add(node);
    anchors.add(anchor);
    nodeAnchorMap[node.name] = anchor;
    nodeMap[node.name] = node;
    nodeRotations[node.name] = 0.0;
  }

  // 노드 제거
  void removeNode(ARNode node) {
    nodes.remove(node);
    nodeMap.remove(node.name);
    nodeRotations.remove(node.name);

    // 해당 노드의 앵커도 제거
    ARAnchor? anchor = nodeAnchorMap[node.name];
    if (anchor != null) {
      anchors.remove(anchor);
      nodeAnchorMap.remove(node.name);
    }

    // 탭 ID 매핑에서도 제거
    String? tapIdToRemove;
    tapIdToNodeNameMap.forEach((tapId, nodeName) {
      if (nodeName == node.name) {
        tapIdToRemove = tapId;
      }
    });
    if (tapIdToRemove != null) {
      tapIdToNodeNameMap.remove(tapIdToRemove);
    }

    // 선택된 노드였다면 선택 해제
    if (selectedNodeName == node.name) {
      selectedNodeName = null;
      selectedTapId = null;
      isMoveMode = false;
      isRotateMode = false; // 회전 모드도 해제
    }
  }

  // 노드 선택
  void selectNode(String? nodeName, String? tapId) {
    selectedNodeName = nodeName;
    selectedTapId = tapId;
  }

  // 선택 해제
  void clearSelection() {
    selectedNodeName = null;
    selectedTapId = null;
    isMoveMode = false;
    isRotateMode = false; // 회전 모드도 해제
  }

  // 회전값 설정
  void setNodeRotation(String nodeName, double rotation) {
    nodeRotations[nodeName] = rotation;
  }

  // 회전값 조회
  double getNodeRotation(String nodeName) {
    return nodeRotations[nodeName] ?? 0.0;
  }

  // 선택된 노드의 회전값
  double getSelectedNodeRotation() {
    if (selectedNodeName == null) return 0.0;
    return nodeRotations[selectedNodeName] ?? 0.0;
  }

  // 디버그 정보
  void printDebugInfo() {
    print("=== 노드 상태 디버그 정보 ===");
    print("총 노드 수: ${nodes.length}");
    print("총 앵커 수: ${anchors.length}");
    print("선택된 노드: $selectedNodeName");
    print("이동 모드: $isMoveMode");
    print("회전 모드: $isRotateMode"); // 회전 모드 정보 추가

    for (int i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      double rotation = nodeRotations[node.name] ?? 0.0;
      print("노드 $i: 이름=${node.name}, 회전=${rotation}°");
    }
    print("================================");
  }
}