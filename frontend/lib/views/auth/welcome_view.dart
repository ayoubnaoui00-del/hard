import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../widgets/gradient_background.dart';

class WelcomeView extends ConsumerStatefulWidget {
  const WelcomeView({super.key});

  @override
  ConsumerState<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends ConsumerState<WelcomeView>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _exitController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _shimmerAnimation;

  late final Animation<double> _pulseScaleAnimation;

  late final Animation<Offset> _exitSlideAnimation;
  late final Animation<double> _exitFadeAnimation;
  late final Animation<double> _exitScaleAnimation;

  Timer? _autoAdvanceTimer;
  bool _isExiting = false;
  bool _hasNavigated = false;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();

    // 1. Smooth Entry Controller (950ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );

    // 2. Ambient Breathing Pulse Controller (2400ms) - active during the 6s display
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 3. Smooth Exit Controller (620ms) - glides right into login/main screen
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    // Smooth entry curves
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -2.4, end: 2.4).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.35, 0.95, curve: Curves.easeInOutCubic),
      ),
    );

    // Ambient breathing pulse while waiting 6 seconds
    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Smooth exit to the right (accelerates seamlessly past the right screen boundary)
    _exitSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(2.8, 0.0),
    ).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: const Interval(0.40, 1.0, curve: Curves.easeInQuad),
      ),
    );

    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _exitController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start smooth entrance
    _entryController.forward();

    // Display for 6 seconds with breathing animation, then smoothly glide right into the app
    if (!_isTestEnvironment) {
      _entryController.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted && !_isExiting) {
          _pulseController.repeat(reverse: true);
          _autoAdvanceTimer = Timer(const Duration(seconds: 6), () {
            _startExit();
          });
        }
      });
    }
  }

  void _startExit() {
    if (_isExiting || _hasNavigated || !mounted) return;
    _isExiting = true;
    _autoAdvanceTimer?.cancel();
    _pulseController.stop();

    // Make sure entry is at completion so exit starts from full resting position
    if (_entryController.status != AnimationStatus.completed) {
      _entryController.value = 1.0;
    }

    _exitController.forward().then((_) {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final session = ref.read(authSessionViewModelProvider);
    if (session.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _entryController.dispose();
    _pulseController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _startExit,
          child: SizedBox.expand(
            child: Center(
              child: AnimatedBuilder(
                animation: Listenable.merge(
                    [_entryController, _pulseController, _exitController]),
                builder: (context, child) {
                  final pulseScale = _pulseController.isAnimating
                      ? _pulseScaleAnimation.value
                      : 1.0;
                  final shimmerOffset = _shimmerAnimation.value;

                  return SlideTransition(
                    position: _exitSlideAnimation,
                    child: FadeTransition(
                      opacity: _exitFadeAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value *
                              pulseScale *
                              _exitScaleAnimation.value,
                          child: ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                begin: Alignment(shimmerOffset - 1.0, -0.6),
                                end: Alignment(shimmerOffset + 1.0, 0.6),
                                colors: [
                                  Colors.transparent,
                                  AppTheme.velocityLimeBright
                                      .withValues(alpha: 0.65),
                                  Colors.white.withValues(alpha: 0.80),
                                  AppTheme.velocityLimeBright
                                      .withValues(alpha: 0.65),
                                  Colors.transparent,
                                ],
                                stops: const [
                                  0.25,
                                  0.45,
                                  0.50,
                                  0.55,
                                  0.75
                                ],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcATop,
                            child: Image.asset(
                              'assets/images/hard_logo.png',
                              width: 140,
                              height: 140,
                              filterQuality: FilterQuality.high,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}


