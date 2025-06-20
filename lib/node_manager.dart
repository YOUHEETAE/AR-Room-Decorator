// position_based_node_manager.dart
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class NodePositionData {
  final ARNode node;
  final ARAnchor anchor;
  final vm.Vector3 worldPosition;
  final DateTime createdAt;

  NodePositionData({
    required this.node,
    required this.anchor,
    required this.worldPosition,
    required this.createdAt,
  });
}

class PositionBasedNodeManager {
  Map<String, NodePositionData> nodePositions = {}; // 노드 이름 -> 위치 데이터
  String? selectedNodeName;
  bool isMoveMode = false;

  // 노드 추가 시 위치 정보 저장
  void addNode(ARNode node, ARAnchor anchor, vm.Matrix4 worldTransform) {
    // 월드 변환 매트릭스에서 위치 추출
    vm.Vector3 worldPosition = vm.Vector3(
      worldTransform.getTranslation().x,
      worldTransform.getTranslation().y,
      worldTransform.getTranslation().z,
    );

    nodePositions[node.name] = NodePositionData(
      node: node,
      anchor: anchor,
      worldPosition: worldPosition,
      createdAt: DateTime.now(),
    );

    print("📍 노드 위치 저장: ${node.name}");
    print("   월드 좌표: (${worldPosition.x.toStringAsFixed(3)}, ${worldPosition.y.toStringAsFixed(3)}, ${worldPosition.z.toStringAsFixed(3)})");
  }

  // 탭 위치를 기반으로 가장 가까운 노드 찾기
  String? findNodeByTapPosition(List<ARHitTestResult> hitResults) {
    if (hitResults.isEmpty || nodePositions.isEmpty) {
      return null;
    }

    // 첫 번째 히트 결과의 월드 위치 사용
    vm.Matrix4 tapTransform = hitResults.first.worldTransform;
    vm.Vector3 tapPosition = vm.Vector3(
      tapTransform.getTranslation().x,
      tapTransform.getTranslation().y,
      tapTransform.getTranslation().z,
    );

    print("🎯 탭 위치: (${tapPosition.x.toStringAsFixed(3)}, ${tapPosition.y.toStringAsFixed(3)}, ${tapPosition.z.toStringAsFixed(3)})");

    String? closestNodeName;
    double minDistance = double.infinity;
    const double maxTapDistance = 0.5; // 50cm 이내에서만 선택

    // 모든 노드와 거리 계산
    for (var entry in nodePositions.entries) {
      String nodeName = entry.key;
      vm.Vector3 nodePosition = entry.value.worldPosition;

      double distance = tapPosition.distanceTo(nodePosition);

      print("   ${nodeName}: 거리 ${distance.toStringAsFixed(3)}m");

      if (distance < minDistance && distance < maxTapDistance) {
        minDistance = distance;
        closestNodeName = nodeName;
      }
    }

    if (closestNodeName != null) {
      print("✅ 가장 가까운 노드: $closestNodeName (거리: ${minDistance.toStringAsFixed(3)}m)");
      selectedNodeName = closestNodeName;
    } else {
      print("❌ 탭 범위 내에 노드 없음 (최대 거리: ${maxTapDistance}m)");
    }

    return closestNodeName;
  }

  // 노드 탭 이벤트 처리 (위치 기반)
  String handleNodeTapWithPosition(List<String> tappedNodeNames, List<ARHitTestResult>? hitResults) {
    print("\n=== 위치 기반 노드 선택 ===");

    if (hitResults != null && hitResults.isNotEmpty) {
      // 위치 기반 매핑 시도
      String? foundNode = findNodeByTapPosition(hitResults);
      if (foundNode != null) {
        return "✅ 위치 기반 선택 성공: $foundNode";
      }
    }

    // 위치 기반 실패 시 기존 방식으로 fallback
    if (tappedNodeNames.isNotEmpty && nodePositions.isNotEmpty) {
      // 가장 최근 노드 선택
      var sortedNodes = nodePositions.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      selectedNodeName = sortedNodes.first.node.name;
      return "⚠️ 위치 매핑 실패, 최근 노드 선택: $selectedNodeName";
    }

    return "❌ 선택 가능한 노드 없음";
  }

  // 선택된 노드 제거
  Future<String> removeSelected(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    if (selectedNodeName == null) {
      return "❌ 선택된 노드가 없음";
    }

    NodePositionData? nodeData = nodePositions[selectedNodeName];
    if (nodeData == null) {
      return "❌ 노드 데이터를 찾을 수 없음: $selectedNodeName";
    }

    try {
      await arObjectManager?.removeNode(nodeData.node);
      await arAnchorManager?.removeAnchor(nodeData.anchor);

      nodePositions.remove(selectedNodeName);
      selectedNodeName = null;
      isMoveMode = false;

      return "✅ 노드 삭제 완료! 남은 노드: ${nodePositions.length}개";
    } catch (e) {
      return "❌ 삭제 중 오류: $e";
    }
  }

  // 모든 노드 제거
  Future<void> removeEverything(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    for (var nodeData in nodePositions.values) {
      try {
        await arObjectManager?.removeNode(nodeData.node);
        await arAnchorManager?.removeAnchor(nodeData.anchor);
      } catch (e) {
        print("노드 제거 중 오류: $e");
      }
    }

    nodePositions.clear();
    selectedNodeName = null;
    isMoveMode = false;
  }

  // 이동 모드 토글
  void toggleMoveMode() {
    if (selectedNodeName != null) {
      isMoveMode = !isMoveMode;
      print("이동 모드 ${isMoveMode ? '활성화' : '비활성화'}: $selectedNodeName");
    }
  }

  // 노드 이동
  Future<bool> moveNodeToPosition(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, ARHitTestResult hitResult) async {
    if (!isMoveMode || selectedNodeName == null) {
      return false;
    }

    NodePositionData? nodeData = nodePositions[selectedNodeName];
    if (nodeData == null) {
      return false;
    }

    try {
      // 기존 노드/앵커 제거
      await arObjectManager?.removeNode(nodeData.node);
      await arAnchorManager?.removeAnchor(nodeData.anchor);

      // 새 위치에 앵커 생성
      var newAnchor = ARPlaneAnchor(transformation: hitResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

      if (didAddAnchor == true) {
        bool? didAddNode = await arObjectManager?.addNode(nodeData.node, planeAnchor: newAnchor);

        if (didAddNode == true) {
          // 위치 정보 업데이트
          vm.Vector3 newPosition = vm.Vector3(
            hitResult.worldTransform.getTranslation().x,
            hitResult.worldTransform.getTranslation().y,
            hitResult.worldTransform.getTranslation().z,
          );

          nodePositions[selectedNodeName!] = NodePositionData(
            node: nodeData.node,
            anchor: newAnchor,
            worldPosition: newPosition,
            createdAt: nodeData.createdAt,
          );

          print("📍 노드 이동 완료: $selectedNodeName");
          print("   새 위치: (${newPosition.x.toStringAsFixed(3)}, ${newPosition.y.toStringAsFixed(3)}, ${newPosition.z.toStringAsFixed(3)})");

          isMoveMode = false;
          return true;
        }
      }

      return false;
    } catch (e) {
      print("노드 이동 중 오류: $e");
      return false;
    }
  }

  // 디버그 정보
  String getDebugInfo() {
    StringBuffer info = StringBuffer();
    info.writeln("=== 위치 기반 노드 매니저 ===");
    info.writeln("총 노드 수: ${nodePositions.length}");
    info.writeln("선택된 노드: ${selectedNodeName ?? 'None'}");
    info.writeln("이동 모드: $isMoveMode");
    info.writeln("");

    nodePositions.forEach((name, data) {
      vm.Vector3 pos = data.worldPosition;
      info.writeln("$name:");
      info.writeln("  위치: (${pos.x.toStringAsFixed(3)}, ${pos.y.toStringAsFixed(3)}, ${pos.z.toStringAsFixed(3)})");
      info.writeln("  생성: ${data.createdAt.toString().substring(11, 19)}");
    });

    info.writeln("========================");
    return info.toString();
  }

  // getter들
  bool get hasNodes => nodePositions.isNotEmpty;
  int get nodeCount => nodePositions.length;
  List<String> get nodeNames => nodePositions.keys.toList();
}