// furniture_data.dart - 가구 데이터 구조 및 관리
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

// 개별 가구 아이템 클래스
class FurnitureItem {
  final String id;
  final String modelPath;        // .glb 파일 경로
  final String thumbnailPath;    // 썸네일 이미지 경로
  final FurnitureCategory category;

  const FurnitureItem({
    required this.id,
    required this.modelPath,
    required this.thumbnailPath,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FurnitureItem &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// 가구 데이터 관리자
class FurnitureDataManager {
  // 싱글톤 패턴
  static final FurnitureDataManager _instance = FurnitureDataManager._internal();
  factory FurnitureDataManager() => _instance;
  FurnitureDataManager._internal();

  // 현재 선택된 가구
  FurnitureItem? _selectedFurniture;

  // 현재 선택된 가구 getter/setter
  FurnitureItem? get selectedFurniture => _selectedFurniture;
  set selectedFurniture(FurnitureItem? furniture) {
    _selectedFurniture = furniture;
  }

  // 기본 가구 데이터 (나중에 에셋 추가하면 실제 경로로 변경)
  static const List<FurnitureItem> _furnitureList = [
    // 의자 카테고리
    FurnitureItem(
      id: 'chair_01',
      modelPath: 'assets/models/basic_chair.glb',
      thumbnailPath: 'assets/images/thumbnails/chair_01.png',
      category: FurnitureCategory.chair,
    ),
    FurnitureItem(
      id: 'chair_02',
      modelPath: 'assets/models/comfort_chair.glb',
      thumbnailPath: 'assets/images/thumbnails/comfort_chair.png',
      category: FurnitureCategory.chair,
    ),
    FurnitureItem(
      id: 'chair_03',
      modelPath: 'assets/models/hightech_chair.glb',
      thumbnailPath: 'assets/images/thumbnails/chair_03.png',
      category: FurnitureCategory.chair,
    ),
    // 테이블 카테고리
    FurnitureItem(
      id: 'table_01',
      modelPath: 'assets/models/coffee_table.glb',
      thumbnailPath: 'assets/images/thumbnails/table_01.png',
      category: FurnitureCategory.table,
    ),
    FurnitureItem(
      id: 'table_02',
      modelPath: 'assets/models/dining_table.glb',
      thumbnailPath: 'assets/images/thumbnails/table_02.png',
      category: FurnitureCategory.table,
    ),

    // 소파 카테고리
    FurnitureItem(
      id: 'sofa_01',
      modelPath: 'assets/models/sofa_2seat.glb',
      thumbnailPath: 'assets/images/thumbnails/sofa_01.png',
      category: FurnitureCategory.sofa,
    ),
    FurnitureItem(
      id: 'sofa_02',
      modelPath: 'assets/models/sofa_3seat.glb',
      thumbnailPath: 'assets/images/thumbnails/sofa_02.png',
      category: FurnitureCategory.sofa,
    ),

    // 침대 카테고리
    FurnitureItem(
      id: 'bed_01',
      modelPath: 'assets/models/single_bed.glb',
      thumbnailPath: 'assets/images/thumbnails/bed_01.png',
      category: FurnitureCategory.bed,
    ),
    FurnitureItem(
      id: 'bed_02',
      modelPath: 'assets/models/double_bed.glb',
      thumbnailPath: 'assets/images/thumbnails/bed_02.png',
      category: FurnitureCategory.bed,
    ),

    // 수납장 카테고리
    FurnitureItem(
      id: 'storage_01',
      modelPath: 'assets/models/bookshelf.glb',
      thumbnailPath: 'assets/images/thumbnails/storage_01.png',
      category: FurnitureCategory.storage,
    ),
    FurnitureItem(
      id: 'storage_02',
      modelPath: 'assets/models/wardrobe.glb',
      thumbnailPath: 'assets/images/thumbnails/storage_02.png',
      category: FurnitureCategory.storage,
    ),

    // 장식품 카테고리
    FurnitureItem(
      id: 'deco_01',
      modelPath: 'assets/models/plant_pot.glb',
      thumbnailPath: 'assets/images/thumbnails/deco_01.png',
      category: FurnitureCategory.decoration,
    ),
    FurnitureItem(
      id: 'deco_02',
      modelPath: 'assets/models/floor_lamp.glb',
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
}