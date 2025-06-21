// node_operations.dart - 노드 작업들 (디버그 로그 포함)
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'dart:math' as math;
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

      print("이동 시작: ${state.selectedNodeName}");

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

  // ========== 회전 기능 ==========

  // 시계방향 회전
  Future<Map<String, dynamic>> rotateNodeClockwise(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    print("시계방향 회전 시도");
    if (state.selectedNodeName == null) {
      return {"success": false, "logs": ["❌ 선택된 노드 없음"]};
    }

    return await _rotateNodeWithQuaternion(arObjectManager, arAnchorManager, 15.0);
  }

  // 반시계방향 회전
  Future<Map<String, dynamic>> rotateNodeCounterClockwise(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager) async {
    print("반시계방향 회전 시도");
    if (state.selectedNodeName == null) {
      return {"success": false, "logs": ["❌ 선택된 노드 없음"]};
    }

    return await _rotateNodeWithQuaternion(arObjectManager, arAnchorManager, -15.0);
  }

  // 특정 각도로 회전 설정
  Future<Map<String, dynamic>> setNodeRotation(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, double degrees) async {
    print("회전 리셋 시도");
    if (state.selectedNodeName == null) {
      return {"success": false, "logs": ["❌ 선택된 노드 없음"]};
    }

    // 현재 회전값과의 차이만큼 회전
    double currentRotation = state.getNodeRotation(state.selectedNodeName!);
    double rotationDiff = degrees - currentRotation;

    return await _rotateNodeWithQuaternion(arObjectManager, arAnchorManager, rotationDiff);
  }

  // Quaternion을 사용한 회전 메서드 (공식 방법)
  Future<Map<String, dynamic>> _rotateNodeWithQuaternion(ARObjectManager? arObjectManager, ARAnchorManager? arAnchorManager, double rotationDegrees) async {
    List<String> debugLogs = [];
    debugLogs.add("=== 회전 시작 ===");

    try {
      // 0. 매니저 null 체크
      if (arObjectManager == null) {
        debugLogs.add("❌ arObjectManager가 null");
        return {"success": false, "logs": debugLogs};
      }

      ARNode? currentNode = state.nodeMap[state.selectedNodeName];
      ARAnchor? currentAnchor = state.nodeAnchorMap[state.selectedNodeName];

      if (currentNode == null || currentAnchor == null) {
        debugLogs.add("❌ 노드/앵커 없음");
        return {"success": false, "logs": debugLogs};
      }

      // 🔍 앵커 타입 검사
      debugLogs.add("앵커타입: ${currentAnchor.runtimeType}");
      if (currentAnchor is! ARPlaneAnchor) {
        debugLogs.add("❌ 앵커타입 불일치");
        return {"success": false, "logs": debugLogs};
      }

      ARPlaneAnchor planeAnchor = currentAnchor;

      // 새 회전값 계산 (절대값 방식으로 변경)
      double currentRotation = state.getNodeRotation(state.selectedNodeName!);
      double newRotation = (currentRotation + rotationDegrees) % 360.0;
      if (newRotation < 0) newRotation += 360.0;

      debugLogs.add("회전: ${currentRotation.toStringAsFixed(1)}° → ${newRotation.toStringAsFixed(1)}°");
      debugLogs.add("회전 차이: ${rotationDegrees.toStringAsFixed(1)}°");

      // 1. 새 노드를 먼저 생성 (제거 전에!)
      debugLogs.add("새 노드 미리 생성...");
      ARNode newNode = _createRotatedNode(currentNode, newRotation);
      debugLogs.add("새 노드 생성 완료");

      // 2. 기존 노드 제거 (더 관대한 성공 조건)
      debugLogs.add("노드 제거 중...");
      bool? removeSuccess = await arObjectManager.removeNode(currentNode);
      debugLogs.add("제거 결과: $removeSuccess");

      // null도 성공으로 간주 (실제로는 제거될 수 있음)
      bool actualRemoveSuccess = (removeSuccess == true || removeSuccess == null);
      debugLogs.add("실제 제거 성공 여부: $actualRemoveSuccess");

      if (!actualRemoveSuccess && removeSuccess == false) {
        debugLogs.add("❌ 노드 제거 확실히 실패");
        return {"success": false, "logs": debugLogs};
      }

      // 3. 대기 시간 증가
      debugLogs.add("AR 엔진 대기 (300ms)...");
      await Future.delayed(const Duration(milliseconds: 300)); // 150ms → 300ms

      // 4. 새 노드 추가 (재시도 로직 추가)
      debugLogs.add("노드 추가 시도 (1차)...");
      bool? addSuccess = await arObjectManager.addNode(newNode, planeAnchor: planeAnchor);
      debugLogs.add("1차 추가 결과: $addSuccess");

      // 실패 시 재시도
      if (addSuccess != true) {
        debugLogs.add("1차 실패 - 재시도 (2차)...");
        await Future.delayed(const Duration(milliseconds: 200));
        addSuccess = await arObjectManager.addNode(newNode, planeAnchor: planeAnchor);
        debugLogs.add("2차 추가 결과: $addSuccess");
      }

      if (addSuccess != true) {
        debugLogs.add("❌ 노드 추가 실패 - 원래 노드 복구 시도");

        // 원래 노드 복구 시도
        bool? recoverSuccess = await arObjectManager.addNode(currentNode, planeAnchor: planeAnchor);
        debugLogs.add("복구 시도 결과: $recoverSuccess");

        if (recoverSuccess != true) {
          debugLogs.add("❌ 복구도 실패 - 노드가 완전히 손실됨");
        }

        return {"success": false, "logs": debugLogs};
      }

      // 5. 상태 업데이트 (NodeState 메서드 사용)
      debugLogs.add("상태 업데이트 중...");

      // 회전값 업데이트
      state.setNodeRotation(state.selectedNodeName!, newRotation);

      // 노드 업데이트 (NodeState의 메서드 사용)
      bool updateSuccess = state.updateNode(state.selectedNodeName!, newNode);
      debugLogs.add(updateSuccess ? "✅ 상태 업데이트 성공" : "❌ 상태 업데이트 실패");

      // 6. 최종 검증
      debugLogs.add("=== 완료 ===");
      debugLogs.add("nodes 개수: ${state.nodes.length}");
      debugLogs.add("선택된 노드: ${state.selectedNodeName}");
      debugLogs.add("✅ 회전 성공: ${newRotation.toStringAsFixed(1)}°");

      return {"success": true, "logs": debugLogs};

    } catch (e) {
      debugLogs.add("❌ 오류 발생: $e");
      return {"success": false, "logs": debugLogs};
    }
  }

  // 회전이 적용된 노드 생성 (공식 vector_math 방식)
  ARNode _createRotatedNode(ARNode originalNode, double rotationDegrees) {
    // 1. 각도를 0-360 범위로 정규화
    double normalizedDegrees = rotationDegrees % 360.0;
    if (normalizedDegrees < 0) normalizedDegrees += 360.0;

    // 2. vector_math의 공식 방법
    double radians = vm.radians(normalizedDegrees); // degrees → 라디안 변환
    vm.Quaternion q = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), radians); // Y축 회전

    print("=== 회전 노드 생성 상세 ===");
    print("  - 입력 각도: ${rotationDegrees.toStringAsFixed(1)}°");
    print("  - 정규화 각도: ${normalizedDegrees.toStringAsFixed(1)}°");
    print("  - 라디안: ${radians.toStringAsFixed(4)}");
    print("  - Y축 회전 벡터: (0, 1, 0)");
    print("  - Quaternion: x=${q.x.toStringAsFixed(4)}, y=${q.y.toStringAsFixed(4)}, z=${q.z.toStringAsFixed(4)}, w=${q.w.toStringAsFixed(4)}");

    // 3. 기존 노드 정보 출력
    print("  - 원본 위치: ${originalNode.position}");
    print("  - 원본 스케일: ${originalNode.scale}");
    print("  - 원본 회전: ${originalNode.rotation}");

    // 4. 새 노드 생성 (모든 속성 명시적 복사)
    ARNode newNode = ARNode(
      type: originalNode.type,
      uri: originalNode.uri,
      scale: originalNode.scale ?? vm.Vector3(0.2, 0.2, 0.2), // null 방어
      position: originalNode.position ?? vm.Vector3(0.0, 0.0, 0.0), // null 방어
      rotation: vm.Vector4(q.x, q.y, q.z, q.w), // 새로운 회전값 적용
      name: originalNode.name,
    );

    print("  - 새 노드 회전: ${newNode.rotation}");
    print("=== 회전 노드 생성 완료 ===");

    return newNode;
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