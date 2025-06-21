// node_manager.dart - 실제 회전 기능 구현된 버전 (반환 타입 수정)
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';

import 'node_state.dart';
import 'node_operations.dart';
import 'node_selection_handler.dart';

class NodeManager {
  late final NodeState _state;
  late final NodeOperations _operations;
  late final NodeSelectionHandler _selectionHandler;

  NodeManager() {
    _state = NodeState();
    _operations = NodeOperations(_state);
    _selectionHandler = NodeSelectionHandler(_state);
  }

  // State 접근자들
  List<ARNode> get nodes => _state.nodes;
  List<ARAnchor> get anchors => _state.anchors;
  Map<String, ARAnchor> get nodeAnchorMap => _state.nodeAnchorMap;
  Map<String, ARNode> get nodeMap => _state.nodeMap;
  Map<String, String> get tapIdToNodeNameMap => _state.tapIdToNodeNameMap;
  String? get selectedNodeName => _state.selectedNodeName;
  String? get selectedTapId => _state.selectedTapId;
  bool get isMoveMode => _state.isMoveMode;
  bool get isRotateMode => _state.isRotateMode;

  // 노드 관리
  Future<void> removeEverything(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    return _operations.removeEverything(arObjectManager, arAnchorManager);
  }

  Future<String> removeSelected(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    return _operations.removeSelected(arObjectManager, arAnchorManager);
  }

  Future<bool> moveNodeToPosition(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, ARHitTestResult hitResult) async {
    return _operations.moveNodeToPosition(arObjectManager, arAnchorManager, hitResult);
  }

  // 노드 선택
  String handleNodeTap(List<String> nodeNames) {
    return _selectionHandler.handleNodeTap(nodeNames);
  }

  String getNodeTapDialogContent(String tappedNodeId, List<String> nodeNames) {
    return _selectionHandler.getNodeTapDialogContent(tappedNodeId, nodeNames);
  }

  void toggleMoveMode() {
    _selectionHandler.toggleMoveMode();
  }

  void toggleRotateMode() {
    _selectionHandler.toggleRotateMode();
  }

  // 회전 관련
  double getSelectedNodeRotation() {
    return _state.getSelectedNodeRotation();
  }

  void initializeNodeRotation(String nodeName) {
    _state.setNodeRotation(nodeName, 0.0);
    print("노드 회전값 초기화: $nodeName = 0.0°");
  }

  // 회전 기능 - 업데이트된 반환 타입 (Map<String, dynamic>)
  Future<Map<String, dynamic>> rotateNodeClockwise(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    return await _operations.rotateNodeClockwise(arObjectManager, arAnchorManager);
  }

  Future<Map<String, dynamic>> rotateNodeCounterClockwise(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    return await _operations.rotateNodeCounterClockwise(arObjectManager, arAnchorManager);
  }

  Future<Map<String, dynamic>> setNodeRotation(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, double degrees) async {
    return await _operations.setNodeRotation(arObjectManager, arAnchorManager, degrees);
  }

  // 디버그
  void printNodeDebugInfo() {
    _state.printDebugInfo();
  }
}