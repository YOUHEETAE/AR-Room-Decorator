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

import 'simplified_node_manager.dart';
import 'ar_model_factory.dart';
import 'furniture_data.dart';
import 'furniture_selector_widget.dart';
import 'gallery_manager.dart';
import 'ar_ui_widgets.dart';
import 'ar_permission_handler.dart';
import 'ar_screenshot_handler.dart';
import 'ar_navigation_handler.dart';

class SimplifiedARFurnitureScreen extends StatefulWidget {
  const SimplifiedARFurnitureScreen({super.key});

  @override
  State<SimplifiedARFurnitureScreen> createState() => _SimplifiedARFurnitureScreenState();
}

class _SimplifiedARFurnitureScreenState extends State<SimplifiedARFurnitureScreen> {
  // AR 매니저들
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  // 비즈니스 로직 매니저들
  final SimplifiedNodeManager nodeManager = SimplifiedNodeManager();
  final FurnitureDataManager furnitureManager = FurnitureDataManager();
  final GalleryManager galleryManager = GalleryManager();

  // 헬퍼 클래스들
  late ARPermissionHandler permissionHandler;
  late ARScreenshotHandler screenshotHandler;
  late ARNavigationHandler navigationHandler;

  // 상태 변수들
  bool isARInitialized = false;
  bool isPermissionGranted = false;
  FurnitureItem? selectedFurniture;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("🎬 AR 화면 초기화 시작");

    // 헬퍼 클래스들 초기화
    permissionHandler = ARPermissionHandler(
      onPermissionGranted: () => setState(() => isPermissionGranted = true),
      onPermissionDenied: () => navigationHandler.navigateBack(),
    );

    screenshotHandler = ARScreenshotHandler(
      galleryManager: galleryManager,
      onSuccess: () => _showSuccessSnackbar(),
      onError: (message) => _showErrorDialog(message),
    );

    navigationHandler = ARNavigationHandler(
      context: context,
      onDispose: _safeDisposeInBackground,
    );

    // 권한 체크 시작
    permissionHandler.checkPermissions();
  }

  @override
  void dispose() {
    debugPrint("🧹 AR 화면 dispose() 시작");
    _isDisposing = true;
    super.dispose();
    debugPrint("✅ AR 화면 dispose() 완료");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: navigationHandler.handleBackPress,
      child: Scaffold(
        appBar: ARAppBar(onBackPressed: navigationHandler.navigateBack),
        body: FurnitureSelectorController(
          builder: (selectedFurniture, onFurnitureSelected) {
            this.selectedFurniture = selectedFurniture;

            return Stack(
              children: [
                // AR 뷰
                if (isPermissionGranted)
                  ARView(
                    onARViewCreated: onARViewCreated,
                    planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
                  ),

                // 로딩 화면들
                if (!isPermissionGranted)
                  const ARLoadingScreen(message: 'AR 준비 중...'),

                if (isPermissionGranted && !isARInitialized)
                  const ARLoadingScreen(message: 'AR 초기화 중...'),

                // UI 컴포넌트들
                if (isPermissionGranted && isARInitialized) ...[
                  // 상단 가구 선택기
                  ARFurnitureSelectorOverlay(
                    selectedFurniture: selectedFurniture,
                    onFurnitureSelected: (furniture) {
                      onFurnitureSelected(furniture);
                      setState(() {});
                    },
                  ),

                  // 활성 노드 정보
                  if (nodeManager.hasActiveNode)
                    ARActiveNodeInfo(
                      nodeManager: nodeManager,
                      selectedFurniture: selectedFurniture,
                    ),

                  // 사용법 안내
                  if (nodeManager.totalNodes == 0)
                    ARUsageGuide(selectedFurniture: selectedFurniture),

                  // 하단 컨트롤
                  ARBottomControls(
                    nodeManager: nodeManager,
                    isARInitialized: isARInitialized,
                    onScreenshot: () => screenshotHandler.takeScreenshot(arSessionManager),
                    onToggleMove: () {
                      nodeManager.toggleMoveMode();
                      setState(() {});
                    },
                    onRemoveAll: () async {
                      await nodeManager.removeAllNodes(arObjectManager, arAnchorManager);
                      if (mounted) setState(() {});
                    },
                    onRemoveActive: () async {
                      await nodeManager.removeActiveNode(arObjectManager, arAnchorManager);
                      if (mounted) setState(() {});
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  // AR 뷰 생성 콜백
  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    if (_isDisposing) return;

    debugPrint("🎯 AR 뷰 생성됨");

    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    _initializeAR();
  }

  // AR 초기화
  Future<void> _initializeAR() async {
    if (_isDisposing) return;

    try {
      debugPrint("🔧 AR 초기화 시작");

      // 1단계: 세션 초기화
      await Future.delayed(const Duration(milliseconds: 2000));
      if (_isDisposing) return;

      await arSessionManager!.onInitialize(
        showFeaturePoints: false,
        showPlanes: true,
        showWorldOrigin: false,
        showAnimatedGuide: false,
        handleRotation: false,
      );

      // 2단계: 이벤트 핸들러 등록
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isDisposing) return;

      arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;

      // 3단계: UI 활성화
      if (mounted && !_isDisposing) {
        setState(() => isARInitialized = true);
        debugPrint("✅ AR 초기화 완료!");
      }
    } catch (e) {
      debugPrint("❌ AR 초기화 실패: $e");
      if (mounted && !_isDisposing) {
        _showErrorDialog("AR 초기화에 실패했습니다.\n기기가 AR을 지원하지 않을 수 있습니다.\n\n오류: $e");
      }
    }
  }

  // 평면 탭 이벤트 처리
  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    if (_isDisposing) return;

    try {
      var singleHitTestResult = hitTestResults.firstWhere(
            (hit) => hit.type == ARHitTestResultType.plane,
        orElse: () => hitTestResults.first,
      );

      if (singleHitTestResult != null && !_isDisposing) {
        if (nodeManager.isMoveMode && nodeManager.hasActiveNode) {
          // 이동 모드
          bool success = await nodeManager.moveActiveNode(
            arObjectManager,
            arAnchorManager,
            singleHitTestResult,
          );
          if (success && mounted && !_isDisposing) setState(() {});
        } else {
          // 배치 모드
          await _addNewNode(singleHitTestResult);
        }
      }
    } catch (e) {
      if (mounted && !_isDisposing) {
        _showErrorDialog("가구 배치 중 오류가 발생했습니다.");
      }
    }
  }

  // 새 노드 추가
  Future<void> _addNewNode(ARHitTestResult hitTestResult) async {
    if (_isDisposing) return;

    var newAnchor = ARPlaneAnchor(transformation: hitTestResult.worldTransform);
    bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);

    if (didAddAnchor == true && !_isDisposing) {
      var newNode = ARModelFactory.createSelectedFurnitureNode();
      bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

      if (didAddNodeToAnchor == true && !_isDisposing) {
        nodeManager.addNode(newNode, newAnchor);
        if (mounted) setState(() {});
      } else {
        if (mounted && !_isDisposing) _showErrorDialog("가구 배치에 실패했습니다.");
      }
    } else {
      if (mounted && !_isDisposing) _showErrorDialog("위치 설정에 실패했습니다.");
    }
  }

  // 백그라운드에서 AR 리소스 정리
  void _safeDisposeInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        debugPrint("🛡️ 백그라운드 AR 리소스 해제 시작");

        if (arObjectManager != null && arAnchorManager != null) {
          await nodeManager.removeAllNodes(arObjectManager, arAnchorManager);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        if (arSessionManager != null) {
          try {
            await arSessionManager!.dispose();
            debugPrint("✅ 백그라운드 AR 세션 정리 완료");
          } catch (e) {
            debugPrint("⚠️ 백그라운드 AR 세션 정리 중 오류 (무시됨): $e");
          }
        }

        debugPrint("✅ 백그라운드 AR 리소스 해제 완료");
      } catch (e) {
        debugPrint("⚠️ 백그라운드 dispose 중 오류 (무시됨): $e");
      }
    });
  }

  // UI 헬퍼 메서드들
  void _showSuccessSnackbar() {
    if (!mounted || _isDisposing) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('갤러리에 저장되었습니다!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted || _isDisposing) return;

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