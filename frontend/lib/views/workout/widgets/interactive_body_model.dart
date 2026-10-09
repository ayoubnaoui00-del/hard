import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../config/theme.dart';
import '../../../services/local_model_server.dart';
import 'body_map_models.dart';
import 'body_map_painter.dart';

/// Reusable 3D Human Muscular Anatomy Model component.
///
/// Features:
/// - Real 3D GLB muscular anatomy loaded locally from assets/models/anatomy.glb
/// - 360° touch rotation and pinch-zoom via WebGL OrbitControls
/// - Granular sub-mesh highlighting for individual muscle groups (Chest, Back, Shoulders, Arms, Legs, Core)
/// - Bi-directional Flutter <-> WebGL JavaScript channel
/// - Transparent dark studio lighting aligned with Velocity design system
/// - Seamless fallback for test environments or legacy platforms
class InteractiveBodyModel extends StatefulWidget {
  final MuscleGroupType selectedMuscle;
  final String? selectedCategory;
  final ValueChanged<MuscleGroupType> onMuscleSelected;
  final bool isFrontView;
  final VoidCallback? onToggleView;

  const InteractiveBodyModel({
    super.key,
    required this.selectedMuscle,
    this.selectedCategory,
    required this.onMuscleSelected,
    this.isFrontView = true,
    this.onToggleView,
  });

  @override
  State<InteractiveBodyModel> createState() => _InteractiveBodyModelState();
}

class _InteractiveBodyModelState extends State<InteractiveBodyModel> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _init3DViewer();
  }

  Future<void> _init3DViewer() async {
    try {
      if (WebViewPlatform.instance == null) {
        // Headless / test environment fallback
        if (mounted) {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
        return;
      }

      final port = await LocalModelServer.start();
      if (!mounted) return;

      if (port == 0) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..addJavaScriptChannel(
          'FlutterBodyModel',
          onMessageReceived: (JavaScriptMessage msg) {
            final muscleGroup = MuscleGroupType.fromString(msg.message);
            widget.onMuscleSelected(muscleGroup);
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (url) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              _updateMuscleHighlight(widget.selectedMuscle);
              _updateCameraOrientation(widget.isFrontView);
            },
            onWebResourceError: (err) {
              // Try fallback to backend if local loopback has error
              _controller?.loadRequest(Uri.parse('http://10.0.2.2:3000/models/'));
            },
          ),
        );

      await controller.loadRequest(Uri.parse('http://127.0.0.1:$port/'));
      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e, stack) {
      debugPrint('InteractiveBodyModel initialization error: $e\n$stack');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant InteractiveBodyModel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedMuscle != oldWidget.selectedMuscle) {
      _updateMuscleHighlight(widget.selectedMuscle);
    } else if (widget.selectedCategory != oldWidget.selectedCategory && widget.selectedCategory != null) {
      _updateCategoryHighlight(widget.selectedCategory!);
    }
    if (widget.isFrontView != oldWidget.isFrontView) {
      _updateCameraOrientation(widget.isFrontView);
    }
  }

  void _updateMuscleHighlight(MuscleGroupType muscle) {
    final groupName = muscle.name.toLowerCase();
    _controller?.runJavaScript("if (window.selectMuscleGroup) window.selectMuscleGroup('$groupName');");
  }

  void _updateCategoryHighlight(String category) {
    final catName = category.toLowerCase();
    _controller?.runJavaScript("if (window.selectMuscleGroup) window.selectMuscleGroup('$catName');");
  }

  void _updateCameraOrientation(bool isFront) {
    _controller?.runJavaScript("if (window.setCameraView) window.setCameraView($isFront);");
  }

  void _handleFallbackTap(Offset tapPos, Size size) {
    final relX = tapPos.dx / size.width;
    final relY = tapPos.dy / size.height;

    if (widget.isFrontView) {
      if (relY >= 0.18 && relY <= 0.32 && relX >= 0.28 && relX <= 0.72) {
        widget.onMuscleSelected(MuscleGroupType.chest);
      } else if (relY >= 0.16 && relY <= 0.30 && (relX < 0.28 || relX > 0.72)) {
        widget.onMuscleSelected(MuscleGroupType.shoulders);
      } else if (relY > 0.30 && relY <= 0.52 && (relX < 0.26 || relX > 0.74)) {
        widget.onMuscleSelected(MuscleGroupType.arms);
      } else if (relY > 0.32 && relY <= 0.50 && relX >= 0.30 && relX <= 0.70) {
        widget.onMuscleSelected(MuscleGroupType.core);
      } else if (relY > 0.50) {
        widget.onMuscleSelected(MuscleGroupType.legs);
      }
    } else {
      if (relY >= 0.16 && relY <= 0.44 && relX >= 0.24 && relX <= 0.76) {
        widget.onMuscleSelected(MuscleGroupType.back);
      } else if (relY >= 0.16 && relY <= 0.28 && (relX < 0.24 || relX > 0.76)) {
        widget.onMuscleSelected(MuscleGroupType.shoulders);
      } else if (relY > 0.28 && relY <= 0.52 && (relX < 0.24 || relX > 0.76)) {
        widget.onMuscleSelected(MuscleGroupType.arms);
      } else if (relY > 0.50) {
        widget.onMuscleSelected(MuscleGroupType.legs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If WebGL or platform WebView is unavailable (e.g. tests or legacy), provide seamless 2D fallback
    if (_hasError) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 130,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.selectedMuscle.color.withValues(alpha: 0.12),
              boxShadow: [
                BoxShadow(
                  color: widget.selectedMuscle.color.withValues(alpha: 0.22),
                  blurRadius: 36,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTapUp: (details) {
              _handleFallbackTap(details.localPosition, const Size(180, 195));
            },
            child: CustomPaint(
              size: const Size(180, 195),
              painter: BodyMapPainter(
                selectedMuscle: widget.selectedMuscle,
                isFront: widget.isFrontView,
              ),
            ),
          ),
          if (widget.onToggleView != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: FloatingActionButton.small(
                heroTag: null,
                backgroundColor: AppTheme.velocityDarkSurface,
                foregroundColor: AppTheme.velocityLime,
                elevation: 2,
                onPressed: widget.onToggleView,
                tooltip: 'Rotate View',
                child: const Icon(Icons.sync_rounded, size: 18),
              ),
            ),
        ],
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient Neon Backdrop Glow matching current muscle color
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: 140,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.selectedMuscle.color.withValues(alpha: 0.10),
            boxShadow: [
              BoxShadow(
                color: widget.selectedMuscle.color.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
        ),

        // Interactive 3D WebGL Canvas
        if (_controller != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: WebViewWidget(controller: _controller!),
          ),

        // Initial Loading State
        if (_isLoading)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.velocityDark.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.velocityLime,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Loading 3D Anatomy...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.velocityTextSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // View Orientation Controls Hint / Rotate View Button
        if (widget.onToggleView != null)
          Positioned(
            right: 4,
            bottom: 4,
            child: FloatingActionButton.small(
              heroTag: null,
              backgroundColor: AppTheme.velocityDarkSurface,
              foregroundColor: AppTheme.velocityLime,
              elevation: 2,
              onPressed: () {
                widget.onToggleView?.call();
                _updateCameraOrientation(!widget.isFrontView);
              },
              tooltip: 'Rotate View',
              child: const Icon(Icons.sync_rounded, size: 18),
            ),
          ),
      ],
    );
  }
}
