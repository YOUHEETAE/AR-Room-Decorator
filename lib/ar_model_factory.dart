// ar_model_factory.dart
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class ARModelFactory {
  static ARNode createDuckNode() {
    String nodeName = "duck_${DateTime.now().millisecondsSinceEpoch}";

    return ARNode(
      type: NodeType.webGLB,
      uri: "https://github.com/KhronosGroup/glTF-Sample-Models/raw/refs/heads/main/2.0/Duck/glTF-Binary/Duck.glb",
      scale: vm.Vector3(0.2, 0.2, 0.2),
      position: vm.Vector3(0.0, 0.0, 0.0),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      name: nodeName,
    );
  }
}