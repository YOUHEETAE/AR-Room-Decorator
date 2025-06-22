// gallery_manager.dart - AR 스크린샷 갤러리 관리
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GalleryItem {
  final String id;
  final String filePath;
  final DateTime timestamp;
  final String title;

  GalleryItem({
    required this.id,
    required this.filePath,
    required this.timestamp,
    required this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
    };
  }

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'],
      filePath: json['filePath'],
      timestamp: DateTime.parse(json['timestamp']),
      title: json['title'],
    );
  }
}

class GalleryManager {
  static const String _prefsKey = 'ar_gallery_items';
  static const String _folderName = 'AR_Furniture_Gallery';

  // 스크린샷 저장
  Future<bool> saveScreenshot(Uint8List imageData) async {
    try {
      // 앱 문서 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final galleryDir = Directory('${directory.path}/$_folderName');

      // 갤러리 폴더 생성
      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }

      // 파일명 생성 (타임스탬프 기반)
      final timestamp = DateTime.now();
      final fileName = 'AR_${timestamp.millisecondsSinceEpoch}.png';
      final filePath = '${galleryDir.path}/$fileName';

      // 이미지 파일 저장
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // 갤러리 아이템 생성
      final galleryItem = GalleryItem(
        id: timestamp.millisecondsSinceEpoch.toString(),
        filePath: filePath,
        timestamp: timestamp,
        title: _generateTitle(timestamp),
      );

      // SharedPreferences에 메타데이터 저장
      await _saveGalleryItemMetadata(galleryItem);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('갤러리 저장 오류: $e');
      }
      return false;
    }
  }

  // 갤러리 아이템 목록 가져오기
  Future<List<GalleryItem>> getGalleryItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = prefs.getStringList(_prefsKey) ?? [];

      List<GalleryItem> items = [];

      for (String itemJson in itemsJson) {
        try {
          final item = GalleryItem.fromJson(json.decode(itemJson));
          // 파일이 실제로 존재하는지 확인
          if (await File(item.filePath).exists()) {
            items.add(item);
          }
        } catch (e) {
          // 손상된 데이터는 무시
        }
      }

      // 최신순으로 정렬
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return items;
    } catch (e) {
      return [];
    }
  }

  // 갤러리 아이템 삭제
  Future<bool> deleteGalleryItem(String itemId) async {
    try {
      final items = await getGalleryItems();
      final itemToDelete = items.firstWhere((item) => item.id == itemId);

      // 파일 삭제
      final file = File(itemToDelete.filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // 메타데이터에서 제거
      await _removeGalleryItemMetadata(itemId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // 전체 갤러리 삭제
  Future<void> clearGallery() async {
    try {
      final items = await getGalleryItems();

      // 모든 파일 삭제
      for (var item in items) {
        final file = File(item.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // SharedPreferences 초기화
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);

    } catch (e) {
      if (kDebugMode) {
        print('갤러리 초기화 오류: $e');
      }
    }
  }

  // 갤러리 아이템 메타데이터 저장
  Future<void> _saveGalleryItemMetadata(GalleryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_prefsKey) ?? [];

    itemsJson.add(json.encode(item.toJson()));
    await prefs.setStringList(_prefsKey, itemsJson);
  }

  // 갤러리 아이템 메타데이터 제거
  Future<void> _removeGalleryItemMetadata(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getStringList(_prefsKey) ?? [];

    itemsJson.removeWhere((itemJson) {
      try {
        final item = GalleryItem.fromJson(json.decode(itemJson));
        return item.id == itemId;
      } catch (e) {
        return false;
      }
    });

    await prefs.setStringList(_prefsKey, itemsJson);
  }

  // 제목 생성
  String _generateTitle(DateTime timestamp) {
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    return 'AR 방꾸미기 ${month}.${day} ${hour}:${minute}';
  }

  // 갤러리 통계
  Future<Map<String, dynamic>> getGalleryStats() async {
    final items = await getGalleryItems();

    return {
      'totalItems': items.length,
      'oldestDate': items.isNotEmpty ? items.last.timestamp : null,
      'newestDate': items.isNotEmpty ? items.first.timestamp : null,
    };
  }
}