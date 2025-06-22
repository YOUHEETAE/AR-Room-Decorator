// ar_model_factory.dart - 선택된 가구에 따라 노드 생성
import 'package:ar_flutter_plugin_2/models/ar_node.dart';
import 'package:ar_flutter_plugin_2/datatypes/node_types.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:uuid/uuid.dart';
import 'furniture_data.dart';

class ARModelFactory {
  static const Uuid uuid = Uuid();
  static final FurnitureDataManager _furnitureManager = FurnitureDataManager();

  // 선택된 가구로 노드 생성
  static ARNode createSelectedFurnitureNode() {
    // 현재 선택된 가구 가져오기
    FurnitureItem? selectedFurniture = _furnitureManager.selectedFurniture;

    // 선택된 가구가 없으면 기본 의자 사용
    if (selectedFurniture == null) {
      selectedFurniture = _getDefaultChair();
    }

    return _createNodeFromFurniture(selectedFurniture);
  }

  // 특정 가구 ID로 노드 생성
  static ARNode createNodeFromFurnitureId(String furnitureId) {
    FurnitureItem? furniture = _furnitureManager.getFurnitureById(furnitureId);

    if (furniture == null) {
      furniture = _getDefaultChair();
    }

    return _createNodeFromFurniture(furniture);
  }

  // 가구 아이템으로부터 AR 노드 생성
  static ARNode _createNodeFromFurniture(FurnitureItem furniture) {
    String nodeName = "${furniture.id}_${uuid.v4()}";

    return ARNode(
      type: NodeType.localGLTF2,
      uri: furniture.modelPath,
      scale: _getScaleForCategory(furniture.category),
      position: vm.Vector3.zero(),
      rotation: vm.Vector4(1.0, 0.0, 0.0, 0.0),
      name: nodeName,
    );
  }

  // 카테고리별 기본 스케일 설정
  static vm.Vector3 _getScaleForCategory(FurnitureCategory category) {
    switch (category) {
      case FurnitureCategory.chair:
        return vm.Vector3(0.2, 0.2, 0.2);
      case FurnitureCategory.table:
        return vm.Vector3(0.15, 0.15, 0.15);
      case FurnitureCategory.sofa:
        return vm.Vector3(0.25, 0.25, 0.25);
      case FurnitureCategory.bed:
        return vm.Vector3(0.2, 0.2, 0.2);
      case FurnitureCategory.storage:
        return vm.Vector3(0.2, 0.2, 0.2);
      case FurnitureCategory.decoration:
        return vm.Vector3(0.15, 0.15, 0.15);
    }
  }

  // 기본 의자 반환 (폴백용)
  static FurnitureItem _getDefaultChair() {
    // 의자 카테고리에서 첫 번째 아이템 반환
    var chairs = _furnitureManager.getFurnitureByCategory(FurnitureCategory.chair);
    if (chairs.isNotEmpty) {
      return chairs.first;
    }

    // 의자도 없으면 전체에서 첫 번째
    var allFurniture = _furnitureManager.allFurniture;
    if (allFurniture.isNotEmpty) {
      return allFurniture.first;
    }

    // 정말 아무것도 없으면 임시 데이터 생성
    return const FurnitureItem(
      id: 'fallback_chair',
      modelPath: 'assets/models/basic_chair.glb',
      thumbnailPath: 'assets/images/thumbnails/fallback.png',
      category: FurnitureCategory.chair,
    );
  }
}