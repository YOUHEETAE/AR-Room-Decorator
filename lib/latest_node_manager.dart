// latest_node_manager.dart - 최근 노드만 조작 (회전 기능 추가)
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:vector_math/vector_math_64.dart';

class LatestNodeManager {
  // 노드 리스트 (순서 보장)
  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  final Map<String, ARAnchor> _nodeAnchorMap = {};
  final Map<String, ARNode> _nodeMap = {}; // ← 누락된 부분 추가

  // 현재 조작 가능한 노드 (가장 최근)
  ARNode? _currentActiveNode;
  ARAnchor? _currentActiveAnchor;

  // 모드 상태
  bool _isMoveMode = false;
  bool _isRotateMode = false;

  // 회전 로그 및 각도 저장
  double _currentRotationY = 0.0;
  String _lastActionLog = "";

  // Getters
  List<ARNode> get nodes => List.unmodifiable(_nodes);
  ARNode? get activeNode => _currentActiveNode;
  bool get isMoveMode => _isMoveMode;
  bool get isRotateMode => _isRotateMode;
  bool get hasActiveNode => _currentActiveNode != null;
  String get activeNodeName => _currentActiveNode?.name ?? "없음";
  int get totalNodes => _nodes.length;
  String get lastActionLog => _lastActionLog;

  // 새 노드 추가
  void addNode(ARNode node, ARAnchor anchor) {
    _nodes.add(node);
    _anchors.add(anchor);
    _nodeAnchorMap[node.name] = anchor;
    _nodeMap[node.name] = node; // ← nodeMap에도 추가

    // 새로 추가된 노드가 활성 노드가 됨
    _currentActiveNode = node;
    _currentActiveAnchor = anchor;
    _currentRotationY = 0.0; // 회전 각도 초기화

    _lastActionLog = "✅ 새 노드 추가: ${node.name} (총 ${_nodes.length}개)\n🎯 활성 노드: ${_currentActiveNode?.name}";
    print(_lastActionLog);
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
      _nodeMap.remove(_currentActiveNode!.name); // ← nodeMap에서도 제거

      // 새로운 활성 노드 설정 (가장 최근 = 리스트의 마지막)
      if (_nodes.isNotEmpty) {
        _currentActiveNode = _nodes.last;
        _currentActiveAnchor = _nodeAnchorMap[_nodes.last.name];
      } else {
        _currentActiveNode = null;
        _currentActiveAnchor = null;
      }

      _isMoveMode = false; // 삭제 후 이동 모드 해제
      _isRotateMode = false; // 삭제 후 회전 모드 해제

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
    _nodeMap.clear(); // ← nodeMap도 초기화
    _currentActiveNode = null;
    _currentActiveAnchor = null;
    _isMoveMode = false;
    _isRotateMode = false;

    print("🧹 모든 노드 삭제 완료");
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (_currentActiveNode == null) {
      _lastActionLog = "❌ 이동할 노드가 없습니다";
      print(_lastActionLog);
      return;
    }

    _isMoveMode = !_isMoveMode;
    if (_isMoveMode) {
      _isRotateMode = false; // 이동 모드 시 회전 모드 해제
    }
    _lastActionLog = "${_isMoveMode ? '🚀' : '⏹️'} 이동 모드: ${_isMoveMode ? 'ON' : 'OFF'} (${_currentActiveNode!.name})";
    print(_lastActionLog);
  }

  // 회전 모드 토글
  void toggleRotateMode() {
    if (_currentActiveNode == null) {
      _lastActionLog = "❌ 회전할 노드가 없습니다";
      print(_lastActionLog);
      return;
    }

    _isRotateMode = !_isRotateMode;
    if (_isRotateMode) {
      _isMoveMode = false; // 회전 모드 시 이동 모드 해제
    }
    _lastActionLog = "${_isRotateMode ? '🔄' : '⏹️'} 회전 모드: ${_isRotateMode ? 'ON' : 'OFF'} (${_currentActiveNode!.name})";
    print(_lastActionLog);
  }

  // 노드 회전 - 삭제 후 재생성 방식 (공식 우회법)
  Future<bool> rotateActiveNode(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, {double degrees = 45.0}) async {
    if (_currentActiveNode == null || _currentActiveAnchor == null) {
      _lastActionLog = "❌ 회전할 노드가 없습니다";
      return false;
    }

    try {
      _currentRotationY += degrees;
      _lastActionLog = "🔄 노드 회전 중...\n";
      _lastActionLog += "- 노드: ${_currentActiveNode!.name}\n";
      _lastActionLog += "- 회전각: +${degrees}도 (총 ${_currentRotationY}도)\n";

      // 1. 기존 노드 정보 저장
      ARNode oldNode = _currentActiveNode!;
      ARAnchor currentAnchor = _currentActiveAnchor!;

      // 2. 기존 노드 삭제
      _lastActionLog += "- 기존 노드 삭제 중...\n";
      await arObjectManager?.removeNode(oldNode);

      // 3. 회전 변환 적용 (Y축 기준)
      final rotationRadians = _currentRotationY * (3.141592653589793 / 180.0);
      final newRotation = Vector4(0, 1, 0, rotationRadians); // Y축 기준 회전

      // 4. 새 노드 생성 (회전 적용)
      ARNode newNode = ARNode(
        name: "rotated_${DateTime.now().millisecondsSinceEpoch}",
        type: oldNode.type,
        uri: oldNode.uri,
        position: oldNode.position,  // 동일한 위치
        scale: oldNode.scale,        // 동일한 크기
        rotation: newRotation,       // 새로운 회전값
      );

      _lastActionLog += "- 새 노드 생성 (회전 적용)\n";

      // 5. 새 노드 추가 (ARPlaneAnchor로 캐스팅)
      ARPlaneAnchor? planeAnchor = currentAnchor is ARPlaneAnchor ? currentAnchor : null;
      if (planeAnchor == null) {
        _lastActionLog += "❌ 앵커가 PlaneAnchor가 아님";
        return false;
      }

      bool? didAddNode = await arObjectManager?.addNode(newNode, planeAnchor: planeAnchor);

      if (didAddNode == true) {
        // 6. 상태 업데이트
        _nodes.remove(oldNode);
        _nodes.add(newNode);
        _nodeMap.remove(oldNode.name);
        _nodeMap[newNode.name] = newNode;
        _nodeAnchorMap.remove(oldNode.name);
        _nodeAnchorMap[newNode.name] = currentAnchor;
        _currentActiveNode = newNode;

        _lastActionLog += "✅ 회전 성공! (${_currentRotationY}도)";
        return true;
      } else {
        _lastActionLog += "❌ 새 노드 추가 실패";
        return false;
      }

    } catch (e) {
      _lastActionLog = "❌ 회전 중 오류: $e";
      return false;
    }
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
    print("회전 모드: $_isRotateMode");
    print("노드 목록:");
    for (int i = 0; i < _nodes.length; i++) {
      String marker = _nodes[i] == _currentActiveNode ? "🎯" : "  ";
      print("$marker ${i + 1}. ${_nodes[i].name}");
    }
    print("=====================");
  }
}