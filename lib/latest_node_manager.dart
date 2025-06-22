// simplified_node_manager.dart - 깔끔한 노드 관리자
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class SimplifiedNodeManager {
  // 노드 리스트 (순서 보장)
  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  final Map<String, ARAnchor> _nodeAnchorMap = {};
  final Map<String, ARNode> _nodeMap = {};

  // 현재 조작 가능한 노드 (가장 최근)
  ARNode? _currentActiveNode;
  ARAnchor? _currentActiveAnchor;

  // 모드 상태 (이동만)
  bool _isMoveMode = false;

  // Getters
  List<ARNode> get nodes => List.unmodifiable(_nodes);

  ARNode? get activeNode => _currentActiveNode;

  bool get isMoveMode => _isMoveMode;

  bool get hasActiveNode => _currentActiveNode != null;

  String get activeNodeName => _currentActiveNode?.name ?? "없음";

  int get totalNodes => _nodes.length;

  // 새 노드 추가
  void addNode(ARNode node, ARAnchor anchor) {
    _nodes.add(node);
    _anchors.add(anchor);
    _nodeAnchorMap[node.name] = anchor;
    _nodeMap[node.name] = node;

    // 새로 추가된 노드가 활성 노드가 됨
    _currentActiveNode = node;
    _currentActiveAnchor = anchor;
  }

  // 활성 노드 삭제
  Future<String> removeActiveNode(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    if (_currentActiveNode == null) {
      return "삭제할 노드가 없습니다";
    }

    try {
      // AR에서 제거
      await arObjectManager?.removeNode(_currentActiveNode!);
      if (_currentActiveAnchor != null) {
        await arAnchorManager?.removeAnchor(_currentActiveAnchor!);
      }

      // 리스트에서 제거
      String removedName = _currentActiveNode!.name;
      _nodes.remove(_currentActiveNode);
      _anchors.remove(_currentActiveAnchor);
      _nodeAnchorMap.remove(_currentActiveNode!.name);
      _nodeMap.remove(_currentActiveNode!.name);

      // 새로운 활성 노드 설정 (가장 최근 = 리스트의 마지막)
      if (_nodes.isNotEmpty) {
        _currentActiveNode = _nodes.last;
        _currentActiveAnchor = _nodeAnchorMap[_nodes.last.name];
      } else {
        _currentActiveNode = null;
        _currentActiveAnchor = null;
      }

      _isMoveMode = false; // 삭제 후 이동 모드 해제

      String result = "'$removedName' 삭제 완료!";
      if (_currentActiveNode != null) {
        result += "\n새 활성 노드: ${_currentActiveNode!.name}";
      } else {
        result += "\n모든 노드가 삭제되었습니다";
      }

      return result;
    } catch (e) {
      return "삭제 실패: $e";
    }
  }

  // 모든 노드 삭제
  Future<void> removeAllNodes(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    for (var node in [..._nodes]) {
      try {
        await arObjectManager?.removeNode(node);
      } catch (e) {
        // 에러 무시하고 계속 진행
      }
    }

    for (var anchor in [..._anchors]) {
      try {
        await arAnchorManager?.removeAnchor(anchor);
      } catch (e) {
        // 에러 무시하고 계속 진행
      }
    }

    _nodes.clear();
    _anchors.clear();
    _nodeAnchorMap.clear();
    _nodeMap.clear();
    _currentActiveNode = null;
    _currentActiveAnchor = null;
    _isMoveMode = false;
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (_currentActiveNode == null) {
      return;
    }

    _isMoveMode = !_isMoveMode;
  }

  // 활성 노드 이동
  Future<bool> moveActiveNode(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager,
      ARHitTestResult hitResult,) async {
    if (!_isMoveMode || _currentActiveNode == null ||
        _currentActiveAnchor == null) {
      return false;
    }

    try {
      // 기존 노드와 앵커 제거
      await arObjectManager?.removeNode(_currentActiveNode!);
      await arAnchorManager?.removeAnchor(_currentActiveAnchor!);

      // 새 위치에 앵커 생성
      var newAnchor = ARPlaneAnchor(transformation: hitResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        // 노드를 새 앵커에 추가
        bool? didAddNode = await arObjectManager?.addNode(
            _currentActiveNode!,
            planeAnchor: newAnchor
        );

        if (didAddNode == true) {
          // 상태 업데이트
          _anchors.remove(_currentActiveAnchor);
          _anchors.add(newAnchor);
          _nodeAnchorMap[_currentActiveNode!.name] = newAnchor;
          _currentActiveAnchor = newAnchor;

          _isMoveMode = false;
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}