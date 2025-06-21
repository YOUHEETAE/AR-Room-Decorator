// latest_node_manager.dart - 최근 노드만 조작
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';

class LatestNodeManager {
  // 노드 리스트 (순서 보장)
  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  final Map<String, ARAnchor> _nodeAnchorMap = {};

  // 현재 조작 가능한 노드 (가장 최근)
  ARNode? _currentActiveNode;
  ARAnchor? _currentActiveAnchor;

  // 모드 상태
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

    // 새로 추가된 노드가 활성 노드가 됨
    _currentActiveNode = node;
    _currentActiveAnchor = anchor;

    print("✅ 새 노드 추가: ${node.name} (총 ${_nodes.length}개)");
    print("🎯 활성 노드: ${_currentActiveNode?.name}");
  }

  // 활성 노드 삭제
  Future<String> removeActiveNode(
      ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager
      ) async {
    if (_currentActiveNode == null) {
      return "❌ 삭제할 노드가 없습니다";
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

      // 새로운 활성 노드 설정 (가장 최근 = 리스트의 마지막)
      if (_nodes.isNotEmpty) {
        _currentActiveNode = _nodes.last;
        _currentActiveAnchor = _nodeAnchorMap[_nodes.last.name];
      } else {
        _currentActiveNode = null;
        _currentActiveAnchor = null;
      }

      _isMoveMode = false; // 삭제 후 이동 모드 해제

      String result = "✅ '$removedName' 삭제 완료!";
      if (_currentActiveNode != null) {
        result += "\n🎯 새 활성 노드: ${_currentActiveNode!.name}";
      } else {
        result += "\n📝 모든 노드가 삭제되었습니다";
      }

      print(result);
      return result;

    } catch (e) {
      return "❌ 삭제 실패: $e";
    }
  }

  // 모든 노드 삭제
  Future<void> removeAllNodes(
      ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager
      ) async {
    for (var node in [..._nodes]) {
      try {
        await arObjectManager?.removeNode(node);
      } catch (e) {
        print("노드 삭제 오류: $e");
      }
    }

    for (var anchor in [..._anchors]) {
      try {
        await arAnchorManager?.removeAnchor(anchor);
      } catch (e) {
        print("앵커 삭제 오류: $e");
      }
    }

    _nodes.clear();
    _anchors.clear();
    _nodeAnchorMap.clear();
    _currentActiveNode = null;
    _currentActiveAnchor = null;
    _isMoveMode = false;

    print("🧹 모든 노드 삭제 완료");
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (_currentActiveNode == null) {
      print("❌ 이동할 노드가 없습니다");
      return;
    }

    _isMoveMode = !_isMoveMode;
    print("${_isMoveMode ? '🚀' : '⏹️'} 이동 모드: ${_isMoveMode ? 'ON' : 'OFF'} (${_currentActiveNode!.name})");
  }

  // 활성 노드 이동
  Future<bool> moveActiveNode(
      ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager,
      ARHitTestResult hitResult,
      ) async {
    if (!_isMoveMode || _currentActiveNode == null || _currentActiveAnchor == null) {
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
          print("✅ 노드 이동 완료: ${_currentActiveNode!.name}");
          return true;
        }
      }

      print("❌ 노드 이동 실패");
      return false;
    } catch (e) {
      print("❌ 이동 중 오류: $e");
      return false;
    }
  }

  // 이전/다음 노드로 전환 (보너스 기능)
  void switchToPreviousNode() {
    if (_nodes.length < 2) return;

    int currentIndex = _nodes.indexOf(_currentActiveNode!);
    if (currentIndex > 0) {
      _currentActiveNode = _nodes[currentIndex - 1];
      _currentActiveAnchor = _nodeAnchorMap[_currentActiveNode!.name];
      print("⬅️ 이전 노드로: ${_currentActiveNode!.name}");
    }
  }

  void switchToNextNode() {
    if (_nodes.length < 2) return;

    int currentIndex = _nodes.indexOf(_currentActiveNode!);
    if (currentIndex < _nodes.length - 1) {
      _currentActiveNode = _nodes[currentIndex + 1];
      _currentActiveAnchor = _nodeAnchorMap[_currentActiveNode!.name];
      print("➡️ 다음 노드로: ${_currentActiveNode!.name}");
    }
  }

  // 디버그 정보
  void printStatus() {
    print("=== 노드 매니저 상태 ===");
    print("총 노드 수: ${_nodes.length}");
    print("활성 노드: ${_currentActiveNode?.name ?? '없음'}");
    print("이동 모드: $_isMoveMode");
    print("노드 목록:");
    for (int i = 0; i < _nodes.length; i++) {
      String marker = _nodes[i] == _currentActiveNode ? "🎯" : "  ";
      print("$marker ${i + 1}. ${_nodes[i].name}");
    }
    print("=====================");
  }
}