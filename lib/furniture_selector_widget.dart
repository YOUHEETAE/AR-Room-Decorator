// lib/furniture_selector_widget.dart - 동그라미 아이콘만 남긴 깔끔한 가구 선택기
import 'package:flutter/material.dart';
import 'furniture_data.dart';

class FurnitureSelectorWidget extends StatefulWidget {
  final Function(FurnitureItem) onFurnitureSelected;
  final FurnitureItem? selectedFurniture;

  const FurnitureSelectorWidget({
    super.key,
    required this.onFurnitureSelected,
    this.selectedFurniture,
  });

  @override
  State<FurnitureSelectorWidget> createState() => _FurnitureSelectorWidgetState();
}

class _FurnitureSelectorWidgetState extends State<FurnitureSelectorWidget> {
  final FurnitureDataManager _furnitureManager = FurnitureDataManager();
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allFurniture = _furnitureManager.allFurniture;
    final totalPages = (allFurniture.length / 5).ceil();

    return Container(
      height: 100, // 높이 줄임 (사각형 배경 제거했으므로)
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 페이지 인디케이터 (위쪽으로 이동)
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                    ),
                  );
                }),
              ),
            ),

          // 가구 아이콘들 (동그라미만)
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: totalPages,
              itemBuilder: (context, pageIndex) {
                return _buildFurniturePage(allFurniture, pageIndex);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFurniturePage(List<FurnitureItem> allFurniture, int pageIndex) {
    const itemsPerPage = 5;
    final startIndex = pageIndex * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, allFurniture.length);
    final pageItems = allFurniture.sublist(startIndex, endIndex);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...pageItems.map((furniture) => _buildFurnitureItem(furniture)),
          // 빈 공간 채우기 (5개 미만일 때)
          ...List.generate(
            itemsPerPage - pageItems.length,
                (index) => const SizedBox(width: 60),
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureItem(FurnitureItem furniture) {
    final isSelected = widget.selectedFurniture?.id == furniture.id;

    return GestureDetector(
      onTap: () {
        widget.onFurnitureSelected(furniture);
        setState(() {});
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 사각형 배경 제거, 동그라미만 유지
          color: isSelected
              ? furniture.category.color.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          border: Border.all(
            color: isSelected
                ? furniture.category.color
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: furniture.category.color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: _buildFurnitureIcon(furniture, isSelected),
        ),
      ),
    );
  }

  Widget _buildFurnitureIcon(FurnitureItem furniture, bool isSelected) {
    // 실제 썸네일 이미지가 있다면 사용, 없으면 아이콘 사용
    return FutureBuilder<bool>(
      future: _checkThumbnailExists(furniture.thumbnailPath),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          // 실제 썸네일 이미지 사용
          return ClipOval(
            child: Image.asset(
              furniture.thumbnailPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildFallbackIcon(furniture, isSelected);
              },
            ),
          );
        } else {
          // 아이콘 폴백
          return _buildFallbackIcon(furniture, isSelected);
        }
      },
    );
  }

  Widget _buildFallbackIcon(FurnitureItem furniture, bool isSelected) {
    return Icon(
      furniture.category.icon,
      size: 28,
      color: isSelected
          ? furniture.category.color
          : Colors.white.withOpacity(0.9),
    );
  }

  Future<bool> _checkThumbnailExists(String assetPath) async {
    try {
      // AssetBundle에서 에셋 존재 여부 확인
      await DefaultAssetBundle.of(context).load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}

// 가구 선택 상태를 관리하는 StatefulWidget
class FurnitureSelectorController extends StatefulWidget {
  final Widget Function(FurnitureItem? selectedFurniture, Function(FurnitureItem) onSelect) builder;

  const FurnitureSelectorController({
    super.key,
    required this.builder,
  });

  @override
  State<FurnitureSelectorController> createState() => _FurnitureSelectorControllerState();
}

class _FurnitureSelectorControllerState extends State<FurnitureSelectorController> {
  final FurnitureDataManager _furnitureManager = FurnitureDataManager();
  FurnitureItem? _selectedFurniture;

  @override
  void initState() {
    super.initState();
    // 기본으로 첫 번째 가구 선택
    if (_furnitureManager.allFurniture.isNotEmpty) {
      _selectedFurniture = _furnitureManager.allFurniture.first;
      _furnitureManager.selectedFurniture = _selectedFurniture;
    }
  }

  void _onFurnitureSelected(FurnitureItem furniture) {
    setState(() {
      _selectedFurniture = furniture;
      _furnitureManager.selectedFurniture = furniture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_selectedFurniture, _onFurnitureSelected);
  }
}