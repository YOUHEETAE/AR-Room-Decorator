// furniture_data.dart - 회전 기능이 완전히 통합된 가구 데이터 구조 및 관리
import 'package:flutter/material.dart';

// 가구 카테고리 열거형
enum FurnitureCategory {
  chair,    // 의자
  table,    // 테이블
  sofa,     // 소파
  bed,      // 침대
  storage,  // 수납장
  decoration, // 장식품
}

// 가구 카테고리 확장 - 한국어 이름과 아이콘
extension FurnitureCategoryExtension on FurnitureCategory {
  String get displayName {
    switch (this) {
      case FurnitureCategory.chair:
        return '의자';
      case FurnitureCategory.table:
        return '테이블';
      case FurnitureCategory.sofa:
        return '소파';
      case FurnitureCategory.bed:
        return '침대';
      case FurnitureCategory.storage:
        return '수납장';
      case FurnitureCategory.decoration:
        return '장식품';
    }
  }

  IconData get icon {
    switch (this) {
      case FurnitureCategory.chair:
        return Icons.chair;
      case FurnitureCategory.table:
        return Icons.table_restaurant;
      case FurnitureCategory.sofa:
        return Icons.weekend;
      case FurnitureCategory.bed:
        return Icons.bed;
      case FurnitureCategory.storage:
        return Icons.inventory_2;
      case FurnitureCategory.decoration:
        return Icons.auto_awesome;
    }
  }

  Color get color {
    switch (this) {
      case FurnitureCategory.chair:
        return Colors.blue;
      case FurnitureCategory.table:
        return Colors.brown;
      case FurnitureCategory.sofa:
        return Colors.green;
      case FurnitureCategory.bed:
        return Colors.purple;
      case FurnitureCategory.storage:
        return Colors.orange;
      case FurnitureCategory.decoration:
        return Colors.pink;
    }
  }
}

// 가구 회전 방향 열거형
enum FurnitureRotation {
  north,    // 북쪽 (0도)
  east,     // 동쪽 (90도)
  south,    // 남쪽 (180도)
  west,     // 서쪽 (270도)
}

extension FurnitureRotationExtension on FurnitureRotation {
  String get displayName {
    switch (this) {
      case FurnitureRotation.north:
        return '북쪽';
      case FurnitureRotation.east:
        return '동쪽';
      case FurnitureRotation.south:
        return '남쪽';
      case FurnitureRotation.west:
        return '서쪽';
    }
  }

  IconData get icon {
    switch (this) {
      case FurnitureRotation.north:
        return Icons.keyboard_arrow_up;
      case FurnitureRotation.east:
        return Icons.keyboard_arrow_right;
      case FurnitureRotation.south:
        return Icons.keyboard_arrow_down;
      case FurnitureRotation.west:
        return Icons.keyboard_arrow_left;
    }
  }

  // 각도 (디버깅용)
  double get degrees {
    switch (this) {
      case FurnitureRotation.north:
        return 0.0;
      case FurnitureRotation.east:
        return 90.0;
      case FurnitureRotation.south:
        return 180.0;
      case FurnitureRotation.west:
        return 270.0;
    }
  }
}

// 개별 가구 아이템 클래스 - 회전 기능 추가
class FurnitureItem {
  final String id;
  final Map<FurnitureRotation, String> modelPaths;  // 4방향 모델 경로
  final String thumbnailPath;    // 썸네일 이미지 경로
  final FurnitureCategory category;

  const FurnitureItem({
    required this.id,
    required this.modelPaths,
    required this.thumbnailPath,
    required this.category,
  });

  // 편의 생성자 - 단일 모델 경로 (기존 호환성)
  factory FurnitureItem.single({
    required String id,
    required String modelPath,
    required String thumbnailPath,
    required FurnitureCategory category,
  }) {
    return FurnitureItem(
      id: id,
      modelPaths: {
        FurnitureRotation.north: modelPath,
        FurnitureRotation.east: modelPath,
        FurnitureRotation.south: modelPath,
        FurnitureRotation.west: modelPath,
      },
      thumbnailPath: thumbnailPath,
      category: category,
    );
  }

  // 4방향 모델 생성자
  factory FurnitureItem.rotatable({
    required String id,
    required String baseModelPath,  // 기본 경로 (확장자 제외)
    required String thumbnailPath,
    required FurnitureCategory category,
  }) {
    return FurnitureItem(
      id: id,
      modelPaths: {
        FurnitureRotation.north: '${baseModelPath}_north.glb',
        FurnitureRotation.east: '${baseModelPath}_east.glb',
        FurnitureRotation.south: '${baseModelPath}_south.glb',
        FurnitureRotation.west: '${baseModelPath}_west.glb',
      },
      thumbnailPath: thumbnailPath,
      category: category,
    );
  }

  // 커스텀 경로 생성자 (각 방향별로 다른 경로 지정 가능)
  factory FurnitureItem.custom({
    required String id,
    required String northPath,
    required String eastPath,
    required String southPath,
    required String westPath,
    required String thumbnailPath,
    required FurnitureCategory category,
  }) {
    return FurnitureItem(
      id: id,
      modelPaths: {
        FurnitureRotation.north: northPath,
        FurnitureRotation.east: eastPath,
        FurnitureRotation.south: southPath,
        FurnitureRotation.west: westPath,
      },
      thumbnailPath: thumbnailPath,
      category: category,
    );
  }

  // 특정 방향의 모델 경로 가져오기
  String getModelPath(FurnitureRotation rotation) {
    return modelPaths[rotation] ?? modelPaths[FurnitureRotation.north]!;
  }

  // 회전 가능한 가구인지 확인
  bool get isRotatable {
    return modelPaths.values.toSet().length > 1;
  }

  // 기본 모델 경로 (북쪽 방향)
  String get defaultModelPath => getModelPath(FurnitureRotation.north);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FurnitureItem &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FurnitureItem{id: $id, category: $category, rotatable: $isRotatable}';
  }
}

// 회전 매니저
class FurnitureRotationManager {
  // 싱글톤 패턴
  static final FurnitureRotationManager _instance = FurnitureRotationManager._internal();
  factory FurnitureRotationManager() => _instance;
  FurnitureRotationManager._internal();

  // 노드별 현재 회전 상태 저장
  final Map<String, FurnitureRotation> _nodeRotations = {};

  // 노드의 현재 회전 상태 가져오기
  FurnitureRotation getNodeRotation(String nodeName) {
    return _nodeRotations[nodeName] ?? FurnitureRotation.north;
  }

  // 노드 회전 상태 설정
  void setNodeRotation(String nodeName, FurnitureRotation rotation) {
    _nodeRotations[nodeName] = rotation;
  }

  // 시계방향 회전
  FurnitureRotation rotateClockwise(String nodeName) {
    final currentRotation = getNodeRotation(nodeName);
    final newRotation = _getNextRotation(currentRotation);
    setNodeRotation(nodeName, newRotation);
    return newRotation;
  }

  // 반시계방향 회전
  FurnitureRotation rotateCounterClockwise(String nodeName) {
    final currentRotation = getNodeRotation(nodeName);
    final newRotation = _getPrevRotation(currentRotation);
    setNodeRotation(nodeName, newRotation);
    return newRotation;
  }

  // 특정 방향으로 설정
  void setRotation(String nodeName, FurnitureRotation rotation) {
    setNodeRotation(nodeName, rotation);
  }

  // 다음 회전 방향 계산
  FurnitureRotation _getNextRotation(FurnitureRotation current) {
    switch (current) {
      case FurnitureRotation.north:
        return FurnitureRotation.east;
      case FurnitureRotation.east:
        return FurnitureRotation.south;
      case FurnitureRotation.south:
        return FurnitureRotation.west;
      case FurnitureRotation.west:
        return FurnitureRotation.north;
    }
  }

  // 이전 회전 방향 계산
  FurnitureRotation _getPrevRotation(FurnitureRotation current) {
    switch (current) {
      case FurnitureRotation.north:
        return FurnitureRotation.west;
      case FurnitureRotation.east:
        return FurnitureRotation.north;
      case FurnitureRotation.south:
        return FurnitureRotation.east;
      case FurnitureRotation.west:
        return FurnitureRotation.south;
    }
  }

  // 노드 삭제 시 회전 정보도 제거
  void removeNodeRotation(String nodeName) {
    _nodeRotations.remove(nodeName);
  }

  // 모든 회전 정보 초기화
  void clearAllRotations() {
    _nodeRotations.clear();
  }

  // 현재 회전 상태들 가져오기 (디버깅용)
  Map<String, FurnitureRotation> get allRotations => Map.from(_nodeRotations);

  // 회전 정보 개수
  int get totalRotationNodes => _nodeRotations.length;
}

// 가구 데이터 관리자
class FurnitureDataManager {
  // 싱글톤 패턴
  static final FurnitureDataManager _instance = FurnitureDataManager._internal();
  factory FurnitureDataManager() => _instance;
  FurnitureDataManager._internal();

  // 현재 선택된 가구
  FurnitureItem? _selectedFurniture;

  // 회전 매니저
  final FurnitureRotationManager _rotationManager = FurnitureRotationManager();

  // 현재 선택된 가구 getter/setter
  FurnitureItem? get selectedFurniture => _selectedFurniture;
  FurnitureRotationManager get rotationManager => _rotationManager;

  set selectedFurniture(FurnitureItem? furniture) {
    _selectedFurniture = furniture;
  }

  // 업데이트된 가구 데이터 (회전 기능 포함)
  static const List<FurnitureItem> _furnitureList = [
    // 의자 카테고리 - 회전 가능
    FurnitureItem(
      id: 'chair_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/basic_chair_north.glb',
        FurnitureRotation.east: 'assets/models/basic_chair_east.glb',
        FurnitureRotation.south: 'assets/models/basic_chair_south.glb',
        FurnitureRotation.west: 'assets/models/basic_chair_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/chair_01.png',
      category: FurnitureCategory.chair,
    ),
    FurnitureItem(
      id: 'chair_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/comfort_chair_north.glb',
        FurnitureRotation.east: 'assets/models/comfort_chair_east.glb',
        FurnitureRotation.south: 'assets/models/comfort_chair_south.glb',
        FurnitureRotation.west: 'assets/models/comfort_chair_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/comfort_chair.png',
      category: FurnitureCategory.chair,
    ),
    FurnitureItem(
      id: 'chair_03',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/hightech_chair_north.glb',
        FurnitureRotation.east: 'assets/models/hightech_chair_east.glb',
        FurnitureRotation.south: 'assets/models/hightech_chair_south.glb',
        FurnitureRotation.west: 'assets/models/hightech_chair_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/chair_03.png',
      category: FurnitureCategory.chair,
    ),

    // 테이블 카테고리 - 일부만 회전 가능
    FurnitureItem(
      id: 'table_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/coffee_table_north.glb',
        FurnitureRotation.east: 'assets/models/coffee_table_east.glb',
        FurnitureRotation.south: 'assets/models/coffee_table_south.glb',
        FurnitureRotation.west: 'assets/models/coffee_table_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/table_01.png',
      category: FurnitureCategory.table,
    ),
    // 원형 테이블은 회전 불필요 (단일 모델)
    FurnitureItem(
      id: 'table_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/dining_table.glb',
        FurnitureRotation.east: 'assets/models/dining_table.glb',
        FurnitureRotation.south: 'assets/models/dining_table.glb',
        FurnitureRotation.west: 'assets/models/dining_table.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/table_02.png',
      category: FurnitureCategory.table,
    ),

    // 소파 카테고리 - 회전 가능
    FurnitureItem(
      id: 'sofa_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/sofa_2seat_north.glb',
        FurnitureRotation.east: 'assets/models/sofa_2seat_east.glb',
        FurnitureRotation.south: 'assets/models/sofa_2seat_south.glb',
        FurnitureRotation.west: 'assets/models/sofa_2seat_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/sofa_01.png',
      category: FurnitureCategory.sofa,
    ),
    FurnitureItem(
      id: 'sofa_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/sofa_3seat_north.glb',
        FurnitureRotation.east: 'assets/models/sofa_3seat_east.glb',
        FurnitureRotation.south: 'assets/models/sofa_3seat_south.glb',
        FurnitureRotation.west: 'assets/models/sofa_3seat_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/sofa_02.png',
      category: FurnitureCategory.sofa,
    ),

    // 침대 카테고리 - 회전 가능
    FurnitureItem(
      id: 'bed_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/single_bed_north.glb',
        FurnitureRotation.east: 'assets/models/single_bed_east.glb',
        FurnitureRotation.south: 'assets/models/single_bed_south.glb',
        FurnitureRotation.west: 'assets/models/single_bed_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/bed_01.png',
      category: FurnitureCategory.bed,
    ),
    FurnitureItem(
      id: 'bed_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/double_bed_north.glb',
        FurnitureRotation.east: 'assets/models/double_bed_east.glb',
        FurnitureRotation.south: 'assets/models/double_bed_south.glb',
        FurnitureRotation.west: 'assets/models/double_bed_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/bed_02.png',
      category: FurnitureCategory.bed,
    ),

    // 수납장 카테고리 - 회전 가능
    FurnitureItem(
      id: 'storage_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/bookshelf_north.glb',
        FurnitureRotation.east: 'assets/models/bookshelf_east.glb',
        FurnitureRotation.south: 'assets/models/bookshelf_south.glb',
        FurnitureRotation.west: 'assets/models/bookshelf_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/storage_01.png',
      category: FurnitureCategory.storage,
    ),
    FurnitureItem(
      id: 'storage_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/wardrobe_north.glb',
        FurnitureRotation.east: 'assets/models/wardrobe_east.glb',
        FurnitureRotation.south: 'assets/models/wardrobe_south.glb',
        FurnitureRotation.west: 'assets/models/wardrobe_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/storage_02.png',
      category: FurnitureCategory.storage,
    ),

    // 장식품 카테고리 - 일부만 회전 가능
    // 화분은 원형이므로 회전 불필요 (단일 모델)
    FurnitureItem(
      id: 'deco_01',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/plant_pot.glb',
        FurnitureRotation.east: 'assets/models/plant_pot.glb',
        FurnitureRotation.south: 'assets/models/plant_pot.glb',
        FurnitureRotation.west: 'assets/models/plant_pot.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/deco_01.png',
      category: FurnitureCategory.decoration,
    ),
    // 플로어 램프는 회전 가능
    FurnitureItem(
      id: 'deco_02',
      modelPaths: {
        FurnitureRotation.north: 'assets/models/floor_lamp_north.glb',
        FurnitureRotation.east: 'assets/models/floor_lamp_east.glb',
        FurnitureRotation.south: 'assets/models/floor_lamp_south.glb',
        FurnitureRotation.west: 'assets/models/floor_lamp_west.glb',
      },
      thumbnailPath: 'assets/images/thumbnails/deco_02.png',
      category: FurnitureCategory.decoration,
    ),
  ];

  // 전체 가구 리스트 반환
  List<FurnitureItem> get allFurniture => _furnitureList;

  // 카테고리별 가구 리스트 반환
  List<FurnitureItem> getFurnitureByCategory(FurnitureCategory category) {
    return _furnitureList.where((item) => item.category == category).toList();
  }

  // ID로 가구 찾기
  FurnitureItem? getFurnitureById(String id) {
    try {
      return _furnitureList.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // 전체 카테고리 리스트
  List<FurnitureCategory> get allCategories => FurnitureCategory.values;

  // 카테고리별 가구 개수
  int getFurnitureCountByCategory(FurnitureCategory category) {
    return getFurnitureByCategory(category).length;
  }

  // 회전 가능한 가구 리스트
  List<FurnitureItem> get rotatableFurniture {
    return _furnitureList.where((item) => item.isRotatable).toList();
  }

  // 회전 불가능한 가구 리스트
  List<FurnitureItem> get nonRotatableFurniture {
    return _furnitureList.where((item) => !item.isRotatable).toList();
  }

  // 통계 정보
  Map<String, dynamic> get statistics {
    return {
      'totalFurniture': _furnitureList.length,
      'rotatableCount': rotatableFurniture.length,
      'nonRotatableCount': nonRotatableFurniture.length,
      'categoriesCount': allCategories.length,
      'activeRotations': _rotationManager.totalRotationNodes,
    };
  }

  // 디버그 정보 출력
  void printDebugInfo() {
    print('=== Furniture Data Manager Debug Info ===');
    print('Total furniture: ${_furnitureList.length}');
    print('Selected: ${_selectedFurniture?.id ?? "None"}');
    print('Rotatable items: ${rotatableFurniture.length}');
    print('Active rotations: ${_rotationManager.totalRotationNodes}');
    print('==========================================');
  }
}