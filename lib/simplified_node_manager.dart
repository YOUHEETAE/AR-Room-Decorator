// lib/simplified_node_manager.dart - 회전 기능 통합됨
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'furniture_data.dart';

class SimplifiedNodeManager {
  // 노드 리스트 (순서 보장)
  final List<ARNode> _nodes = [];
  final List<ARAnchor> _anchors = [];
  final Map<String, ARAnchor> _nodeAnchorMap = {};
  final Map<String, ARNode> _nodeMap = {};
  final Map<String, vm.Vector3> _nodeScales = {}; // 노드별 크기 저장
  final Map<String, String> _nodeFurnitureIds = {}; // 노드별 가구 ID 저장

  // 현재 조작 가능한 노드 (가장 최근)
  ARNode? _currentActiveNode;
  ARAnchor? _currentActiveAnchor;

  // 모드 상태
  bool _isMoveMode = false;
  bool _isScaleMode = false;
  bool _isRotationMode = false; // 회전 모드 추가

  // 매니저들
  final FurnitureDataManager _furnitureManager = FurnitureDataManager();
  final FurnitureRotationManager _rotationManager = FurnitureRotationManager();

  // Getters
  List<ARNode> get nodes => List.unmodifiable(_nodes);
  ARNode? get activeNode => _currentActiveNode;
  bool get isMoveMode => _isMoveMode;
  bool get isScaleMode => _isScaleMode;
  bool get isRotationMode => _isRotationMode;
  bool get hasActiveNode => _currentActiveNode != null;
  String get activeNodeName => _currentActiveNode?.name ?? "없음";
  int get totalNodes => _nodes.length;

  // 현재 활성 노드의 크기 가져오기
  vm.Vector3? get activeNodeScale {
    if (_currentActiveNode == null) return null;
    return _nodeScales[_currentActiveNode!.name];
  }

  // 현재 활성 노드의 회전 상태 가져오기
  FurnitureRotation? get activeNodeRotation {
    if (_currentActiveNode == null) return null;
    return _rotationManager.getNodeRotation(_currentActiveNode!.name);
  }

  // 현재 활성 노드가 회전 가능한지 확인
  bool get canActiveNodeRotate {
    if (_currentActiveNode == null) return false;
    final furnitureId = _nodeFurnitureIds[_currentActiveNode!.name];
    if (furnitureId == null) return false;
    final furniture = _furnitureManager.getFurnitureById(furnitureId);
    return furniture?.isRotatable ?? false;
  }

  // 새 노드 추가
  void addNode(ARNode node, ARAnchor anchor, {String? furnitureId}) {
    _nodes.add(node);
    _anchors.add(anchor);
    _nodeAnchorMap[node.name] = anchor;
    _nodeMap[node.name] = node;
    _nodeScales[node.name] = node.scale;

    // 가구 ID 저장 (회전을 위해 필요)
    if (furnitureId != null) {
      _nodeFurnitureIds[node.name] = furnitureId;
    }

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
      _nodeScales.remove(_currentActiveNode!.name);
      _nodeFurnitureIds.remove(_currentActiveNode!.name);

      // 회전 정보도 삭제
      _rotationManager.removeNodeRotation(_currentActiveNode!.name);

      // 새로운 활성 노드 설정
      if (_nodes.isNotEmpty) {
        _currentActiveNode = _nodes.last;
        _currentActiveAnchor = _nodeAnchorMap[_nodes.last.name];
      } else {
        _currentActiveNode = null;
        _currentActiveAnchor = null;
      }

      _resetAllModes();

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
    _nodeScales.clear();
    _nodeFurnitureIds.clear();
    _currentActiveNode = null;
    _currentActiveAnchor = null;
    _resetAllModes();

    // 모든 회전 정보 삭제
    _rotationManager.clearAllRotations();
  }

  // 모든 모드 해제
  void _resetAllModes() {
    _isMoveMode = false;
    _isScaleMode = false;
    _isRotationMode = false;
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (_currentActiveNode == null) return;
    _isMoveMode = !_isMoveMode;
    if (_isMoveMode) {
      _isScaleMode = false;
      _isRotationMode = false;
    }
  }

  // 크기 조절 모드 토글
  void toggleScaleMode() {
    if (_currentActiveNode == null) return;
    _isScaleMode = !_isScaleMode;
    if (_isScaleMode) {
      _isMoveMode = false;
      _isRotationMode = false;
    }
  }

  // 회전 모드 토글
  void toggleRotationMode() {
    if (_currentActiveNode == null || !canActiveNodeRotate) return;
    _isRotationMode = !_isRotationMode;
    if (_isRotationMode) {
      _isMoveMode = false;
      _isScaleMode = false;
    }
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

  // 활성 노드 회전 (시계방향)
  Future<bool> rotateActiveNodeClockwise(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    if (_currentActiveNode == null || !canActiveNodeRotate) return false;

    final furnitureId = _nodeFurnitureIds[_currentActiveNode!.name];
    if (furnitureId == null) return false;

    try {
      // 새로운 회전 상태 계산
      final newRotation = _rotationManager.rotateClockwise(_currentActiveNode!.name);

      // 가구 정보 가져오기
      final furniture = _furnitureManager.getFurnitureById(furnitureId);
      if (furniture == null) return false;

      // 새로운 모델 경로
      final newModelPath = furniture.getModelPath(newRotation);

      // 모델 교체
      return await _replaceNodeModel(
          arObjectManager,
          arAnchorManager,
          newModelPath
      );
    } catch (e) {
      return false;
    }
  }

  // 활성 노드 회전 (반시계방향)
  Future<bool> rotateActiveNodeCounterClockwise(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    if (_currentActiveNode == null || !canActiveNodeRotate) return false;

    final furnitureId = _nodeFurnitureIds[_currentActiveNode!.name];
    if (furnitureId == null) return false;

    try {
      // 새로운 회전 상태 계산
      final newRotation = _rotationManager.rotateCounterClockwise(_currentActiveNode!.name);

      // 가구 정보 가져오기
      final furniture = _furnitureManager.getFurnitureById(furnitureId);
      if (furniture == null) return false;

      // 새로운 모델 경로
      final newModelPath = furniture.getModelPath(newRotation);

      // 모델 교체
      return await _replaceNodeModel(
          arObjectManager,
          arAnchorManager,
          newModelPath
      );
    } catch (e) {
      return false;
    }
  }

  // 노드 모델 교체 (회전과 크기 조절에서 공통 사용)
  Future<bool> _replaceNodeModel(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager,
      String newModelPath) async {
    if (_currentActiveNode == null || _currentActiveAnchor == null) {
      return false;
    }

    try {
      // 현재 노드 정보 저장
      String nodeName = _currentActiveNode!.name;
      vm.Vector3 currentScale = _nodeScales[nodeName] ?? _currentActiveNode!.scale;
      vm.Vector4 nodeRotation = vm.Vector4(1.0, 0.0, 0.0, 0.0);
      vm.Vector3 nodePosition = _currentActiveNode!.position;

      // 1. 기존 노드 삭제
      await arObjectManager?.removeNode(_currentActiveNode!);
      await arAnchorManager?.removeAnchor(_currentActiveAnchor!);

      // 2. 새로운 모델로 노드 생성
      var newNode = ARNode(
        type: _currentActiveNode!.type,
        uri: newModelPath,
        scale: currentScale,
        position: nodePosition,
        rotation: nodeRotation,
        name: nodeName,
      );

      // 3. 새 앵커 생성
      var newAnchor = ARPlaneAnchor(transformation: _currentActiveAnchor!.transformation);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        // 4. 새 앵커에 노드 추가
        bool? didAddNode = await arObjectManager?.addNode(
            newNode,
            planeAnchor: newAnchor
        );

        if (didAddNode == true) {
          // 5. 노드 정보 업데이트
          int nodeIndex = _nodes.indexOf(_currentActiveNode!);
          _nodes[nodeIndex] = newNode;
          _nodeMap[nodeName] = newNode;
          _nodeScales[nodeName] = currentScale;
          _currentActiveNode = newNode;

          // 6. 앵커 정보 업데이트
          _anchors.remove(_currentActiveAnchor);
          _anchors.add(newAnchor);
          _nodeAnchorMap[nodeName] = newAnchor;
          _currentActiveAnchor = newAnchor;

          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // 활성 노드 크기 변경 (기존 로직 유지, _replaceNodeModel 사용)
  Future<bool> scaleActiveNode(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager,
      double scaleFactor) async {
    if (_currentActiveNode == null || _currentActiveAnchor == null) {
      return false;
    }

    try {
      // 현재 크기 가져오기
      vm.Vector3 currentScale = _nodeScales[_currentActiveNode!.name] ?? _currentActiveNode!.scale;

      // 새로운 크기 계산 (0.05 ~ 1.5 범위로 제한)
      vm.Vector3 newScale = vm.Vector3(
        (currentScale.x * scaleFactor).clamp(0.05, 1.5),
        (currentScale.y * scaleFactor).clamp(0.05, 1.5),
        (currentScale.z * scaleFactor).clamp(0.05, 1.5),
      );

      // 크기 업데이트
      _nodeScales[_currentActiveNode!.name] = newScale;

      // 현재 모델 경로 가져오기 (회전 상태 고려)
      String currentModelPath = _currentActiveNode!.uri!;
      final furnitureId = _nodeFurnitureIds[_currentActiveNode!.name];

      if (furnitureId != null) {
        final furniture = _furnitureManager.getFurnitureById(furnitureId);
        if (furniture != null && furniture.isRotatable) {
          final currentRotation = _rotationManager.getNodeRotation(_currentActiveNode!.name);
          currentModelPath = furniture.getModelPath(currentRotation);
        }
      }

      // 모델 교체 (새로운 크기 적용)
      return await _replaceNodeModel(
          arObjectManager,
          arAnchorManager,
          currentModelPath
      );
    } catch (e) {
      return false;
    }
  }

  // 크기 조절 단계별 메서드들
  Future<bool> scaleUp(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    return await scaleActiveNode(arObjectManager, arAnchorManager, 1.2);
  }

  Future<bool> scaleDown(ARObjectManager? arObjectManager,
      ARAnchorManager? arAnchorManager) async {
    return await scaleActiveNode(arObjectManager, arAnchorManager, 0.8);
  }
}