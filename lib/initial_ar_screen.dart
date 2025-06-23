// initial_ar_screen.dart - 설정 버튼 제거됨
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'ar_furniture_screen.dart';

import 'gallery_screen.dart';

class ModernInitialARScreen extends StatefulWidget {
  const ModernInitialARScreen({super.key});

  @override
  State<ModernInitialARScreen> createState() => _ModernInitialARScreenState();
}

class _ModernInitialARScreenState extends State<ModernInitialARScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool _isVideoInitialized = false;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack)
      ),
    );

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/background.mp4');
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0.0);
      await _videoController.play();

      setState(() {
        _isVideoInitialized = true;
      });

      Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {
          _showContent = true;
        });
        _animationController.forward();
      });

    } catch (e) {
      print('비디오 로드 실패: $e');
      setState(() {
        _showContent = true;
      });
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 비디오 배경
          if (_isVideoInitialized)
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              ),
            ),

          // 기본 배경 (비디오 로드 실패시)
          if (!_isVideoInitialized)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a1a),
                    Color(0xFF2d2d2d),
                    Color(0xFF1a1a1a),
                  ],
                ),
              ),
            ),

          // 그라디언트 오버레이
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 메인 컨텐츠
          if (_showContent)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            children: [
                              // 상단 여백
                              const Spacer(flex: 2),

                              // 로고 및 타이틀 영역
                              Column(
                                children: [
                                  // 모던한 AR 아이콘
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.2),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.view_in_ar_outlined,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // 메인 타이틀
                                  const Text(
                                    'AR Home Design',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 1.5,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 서브타이틀
                                  Text(
                                    '공간을 새롭게 상상하고\n현실로 만들어보세요',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              const Spacer(flex: 3),

                              // 버튼 영역
                              Column(
                                children: [
                                  // 메인 시작 버튼 (글래스 스타일)
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white.withOpacity(0.1),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.pushReplacement(
                                            context,
                                            PageRouteBuilder(
                                              pageBuilder: (context, animation, secondaryAnimation) =>
                                              const SimplifiedARFurnitureScreen(),
                                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                                return SlideTransition(
                                                  position: Tween<Offset>(
                                                    begin: const Offset(1.0, 0.0),
                                                    end: Offset.zero,
                                                  ).animate(CurvedAnimation(
                                                    parent: animation,
                                                    curve: Curves.easeOutCubic,
                                                  )),
                                                  child: child,
                                                );
                                              },
                                              transitionDuration: const Duration(milliseconds: 600),
                                            ),
                                          );
                                        },
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt_outlined,
                                                color: Colors.white.withOpacity(0.9),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'AR 시작하기',
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // 갤러리 버튼만 (설정 버튼 제거됨)
                                  _buildSecondaryButton(
                                    icon: Icons.photo_library_outlined,
                                    label: '갤러리',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ModernGalleryScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // 안내 메시지
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '카메라 접근을 허용해주세요',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // 로딩 상태
          if (!_showContent)
            Container(
              color: Colors.black.withOpacity(0.8),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      '준비 중...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}