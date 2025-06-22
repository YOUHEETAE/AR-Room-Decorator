// ar_furniture_screen.dart - 깔끔한 AR 가구 배치 화면
import 'package:ar_flutter_plugin_2/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_2/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_2/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_2/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_2/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_2/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_2/widgets/ar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:permission_handler/permission_handler.dart';

import '../latest_node_manager.dart';
import '../ar_model_factory.dart';
import '../furniture_data.dart';
import '../furniture_selector_widget.dart';
import '../gallery_manager.dart';
import '../initial_ar_screen.dart';

class SimplifiedARFurnitureScreen extends StatefulWidget {
  const SimplifiedARFurnitureScreen({super.key});

  @override
  State<SimplifiedARFurnitureScreen> createState() => _SimplifiedARFurnitureScreenState();
}

class _SimplifiedARFurnitureScreenState extends State<SimplifiedARFurnitureScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  final SimplifiedNodeManager nodeManager = SimplifiedNodeManager();
  final FurnitureDataManager furnitureManager = FurnitureDataManager();
  final GalleryManager galleryManager = GalleryManager();

  bool isARInitialized = false;
  bool isPermissionGranted = false;
  FurnitureItem? selectedFurniture;

  @override
  void initState() {
    super.initState();
    // 권한 체크를 단순화
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          isPermissionGranted = true;
        });
      }
    });
  }

  @override
  void dispose() {
    debugPrint("🧹 dispose() 호출됨");

    // ARObjectManager를 초기화하지 않았으므로 dispose도 안 함
    try {
      arSessionManager?.dispose();
      // arObjectManager는 초기화 안 했으므로 dispose 안 함
      // arAnchorManager도 ARObjectManager와 연결되어 있어서 스킵
    } catch (e) {
      debugPrint("⚠️ dispose 중 오류: $e");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR 가구 배치'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: IconButton(
            onPressed: () {
              // 간단하게 뒤로가기만
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: FurnitureSelectorController(
        builder: (selectedFurniture, onFurnitureSelected) {
          this.selectedFurniture = selectedFurniture;

          return Stack(
            children: [
              // AR 뷰 (권한 승인 후에만 렌더링)
              if (isPermissionGranted)
                ARView(
                  onARViewCreated: onARViewCreated,
                  planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                ),

              // AR 권한 체크 및 초기화 로딩
              if (!isPermissionGranted)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'AR 준비 중...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              // AR 초기화 로딩
              if (isPermissionGranted && !isARInitialized)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'AR 초기화 중...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

              // 가구 선택 UI (상단)
              if (isPermissionGranted && isARInitialized)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: FurnitureSelectorWidget(
                      selectedFurniture: selectedFurniture,
                      onFurnitureSelected: (furniture) {
                        onFurnitureSelected(furniture);
                        setState(() {});
                      },
                    ),
                  ),
                ),

              // 활성 노드 정보 표시
              if (nodeManager.hasActiveNode && isPermissionGranted && isARInitialized)
                Positioned(
                  top: 160,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              selectedFurniture?.category.icon ?? Icons.chair,
                              color: selectedFurniture?.category.color ?? Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '활성 가구: ${selectedFurniture?.id ?? "없음"}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '총 ${nodeManager.totalNodes}개 배치됨',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),

                        // 이동 모드 표시
                        if (nodeManager.isMoveMode) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '이동 모드 - 평면을 탭하세요',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // 사용법 안내
              if (isPermissionGranted && isARInitialized && nodeManager.totalNodes == 0)
                Positioned(
                  top: 200,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          selectedFurniture?.category.icon ?? Icons.touch_app,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '시작하기',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '위에서 원하는 가구를 선택하고\n평면을 탭해서 배치해보세요!',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // 컨트롤 버튼들
              Align(
                alignment: FractionalOffset.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 카메라 버튼 (스크린샷)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: _takeScreenshot,
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.95),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // 외곽 링
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // 카메라 아이콘
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 28,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 이동 버튼 (활성 노드가 있을 때만)
                        if (nodeManager.hasActiveNode) ...[
                          ElevatedButton.icon(
                            onPressed: () {
                              nodeManager.toggleMoveMode();
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (nodeManager.isMoveMode ? Colors.orange : Colors.blue).withOpacity(0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: Icon(
                              nodeManager.isMoveMode ? Icons.exit_to_app : Icons.open_with,
                              size: 18,
                            ),
                            label: Text(
                              nodeManager.isMoveMode ? "이동 완료" : "가구 이동",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // 삭제 버튼들
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await nodeManager.removeAllNodes(arObjectManager, arAnchorManager);
                                setState(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700]?.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.clear_all, size: 18),
                              label: const Text("전체 삭제"),
                            ),
                            ElevatedButton.icon(
                              onPressed: nodeManager.hasActiveNode ? () async {
                                await nodeManager.removeActiveNode(arObjectManager, arAnchorManager);
                                setState(() {});
                              } : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (nodeManager.hasActiveNode ? Colors.red[500] : Colors.grey)?.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              icon: const Icon(Icons.delete, size: 18),
                              label: const Text("선택 삭제"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // AR 권한 체크
  Future<void> _checkARPermissions() async {
    try {
      // 플러그인 초기화 대기
      await Future.delayed(const Duration(milliseconds: 500));

      // 카메라 권한 체크
      var status = await Permission.camera.status;

      if (status.isDenied) {
        // 권한 요청
        status = await Permission.camera.request();
      }

      if (status.isGranted) {
        setState(() {
          isPermissionGranted = true;
        });
      } else {
        // 권한 거부됨
        _showPermissionDialog();
      }
    } catch (e) {
      // 권한 체크 실패 시에도 진행 (단, 더 긴 대기)
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        isPermissionGranted = true;
      });
    }
  }

  // 권한 거부 시 다이얼로그
  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('카메라 권한 필요'),
        content: const Text('AR 기능을 사용하려면 카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // AR 화면도 닫기
            },
            child: const Text('뒤로가기'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings(); // 설정 앱 열기
            },
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );
  }

  // 스크린샷 촬영 기능
  Future<void> _takeScreenshot() async {
    try {
      if (arSessionManager == null) return;

      // AR 화면 캡처 (ImageProvider 타입)
      var screenshotProvider = await arSessionManager!.snapshot();

      if (screenshotProvider != null) {
        // ImageProvider를 Uint8List로 변환
        Uint8List? imageData = await _convertImageProviderToBytes(screenshotProvider);

        if (imageData != null) {
          // 갤러리에 저장
          await galleryManager.saveScreenshot(imageData);

          // 성공 피드백
          _showSuccessSnackbar();
        } else {
          _showErrorDialog("이미지 변환에 실패했습니다.");
        }
      } else {
        _showErrorDialog("스크린샷 촬영에 실패했습니다.");
      }
    } catch (e) {
      _showErrorDialog("스크린샷 저장 중 오류가 발생했습니다.");
    }
  }

  // ImageProvider를 Uint8List로 변환
  Future<Uint8List?> _convertImageProviderToBytes(ImageProvider imageProvider) async {
    try {
      final ImageStream stream = imageProvider.resolve(const ImageConfiguration());
      final Completer<Uint8List> completer = Completer<Uint8List>();

      late ImageStreamListener listener;
      listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        info.image.toByteData(format: ui.ImageByteFormat.png).then((byteData) {
          if (byteData != null) {
            completer.complete(byteData.buffer.asUint8List());
          } else {
            completer.complete(null);
          }
        });
        stream.removeListener(listener);
      });

      stream.addListener(listener);
      return await completer.future;
    } catch (e) {
      return null;
    }
  }

  // 성공 스낵바 표시
  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text('갤러리에 저장되었습니다!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    debugPrint("🎯 AR 뷰 생성됨");

    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    // AR 초기화를 단계별로 매우 천천히
    Future.delayed(const Duration(milliseconds: 2000), () async {
      try {
        debugPrint("🔧 1단계: AR 세션 초기화 시작");

        await this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          showAnimatedGuide: false,
          handleRotation: false,
        );

        debugPrint("✅ 1단계 완료");

        // 2단계: Object Manager 초기화 (임시 스킵)
        await Future.delayed(const Duration(milliseconds: 1500));

        debugPrint("🔧 2단계: AR 오브젝트 매니저 초기화 (임시 스킵)");

        // TODO: Object Manager 문제 해결될 때까지 스킵
        // await this.arObjectManager!.onInitialize();

        debugPrint("✅ 2단계 완료 (Object Manager 스킵됨)");

        // 3단계: 이벤트 핸들러 등록 (안전하게)
        await Future.delayed(const Duration(milliseconds: 500));

        debugPrint("🔧 3단계: 이벤트 핸들러 등록");

        try {
          this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
          debugPrint("✅ 3단계 완료 - 이벤트 핸들러 등록됨");
        } catch (e) {
          debugPrint("⚠️ 3단계 실패 - 이벤트 핸들러 등록 실패: $e");
          // 이벤트 핸들러 등록 실패해도 계속 진행
        }

        debugPrint("✅ 전체 AR 초기화 완료!");

        // UI 활성화
        if (mounted) {
          setState(() => isARInitialized = true);
          debugPrint("🎨 UI 활성화 완료");

          // UI 활성화 후 이벤트 핸들러 등록 시도
          Future.delayed(const Duration(milliseconds: 1000), () {
            try {
              if (this.arSessionManager != null) {
                this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
                debugPrint("🎯 지연된 이벤트 핸들러 등록 성공");
              }
            } catch (e) {
              debugPrint("⚠️ 지연된 이벤트 핸들러 등록도 실패: $e");
            }
          });
        }
      } catch (e) {
        debugPrint("❌ AR 초기화 실패: $e");
        if (mounted) {
          _showErrorDialog("AR 초기화에 실패했습니다.\n기기가 AR을 지원하지 않을 수 있습니다.\n\n오류: $e");
        }
      }
    });
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    try {
      var singleHitTestResult = hitTestResults.firstWhere(
            (hit) => hit.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      if (singleHitTestResult != null) {
        // 이동 모드일 때는 활성 노드 이동
        if (nodeManager.isMoveMode && nodeManager.hasActiveNode) {
          bool success = await nodeManager.moveActiveNode(
              arObjectManager,
              arAnchorManager,
              singleHitTestResult
          );

          if (success) {
            setState(() {});
          }
          return;
        }

        // 일반 모드일 때는 새 노드 추가 (선택된 가구로)
        await _addNewNode(singleHitTestResult);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog("가구 배치 중 오류가 발생했습니다.");
      }
    }
  }

  Future<void> _addNewNode(ARHitTestResult hitTestResult) async {
    var newAnchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true) {
      // 선택된 가구로 노드 생성
      var newNode = ARModelFactory.createSelectedFurnitureNode();
      bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

      if (didAddNodeToAnchor == true) {
        nodeManager.addNode(newNode, newAnchor);
        setState(() {});
      } else {
        if (mounted) _showErrorDialog("가구 배치에 실패했습니다.");
      }
    } else {
      if (mounted) _showErrorDialog("위치 설정에 실패했습니다.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text("오류"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}