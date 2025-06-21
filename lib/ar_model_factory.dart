// ar_model_factory.dart - UUID 기반 고유 이름 부여
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:uuid/uuid.dart';

class ARModelFactory {
  static const Uuid uuid = Uuid();

  static ARNode createUniqueNode() {
    // 1단계: UUID 기반 고유 이름 부여
    String nodeName = "node_${uuid.v4()}";

    return ARNode(
      type: NodeType.webGLB,
      uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Duck/glTF-Binary/Duck.glb",
      scale: vm.Vector3(0.2, 0.2, 0.2),
      position: vm.Vector3.zero(),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      name: nodeName, // 직접 이름 지정 - 자동 생성 의존 금지!
    );
  }

  // 호환성을 위한 기존 메서드 유지
  static ARNode createDuckNode() {
    return createUniqueNode();
  }
}