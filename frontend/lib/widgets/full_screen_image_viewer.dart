import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Full-screen immersive image viewer with pinch-to-zoom, double-tap zoom,
/// pan, swipe-down to dismiss, and smooth Hero transition.
class FullScreenImageViewer extends StatefulWidget {
  /// The network URL of the image to display.
  final String imageUrl;

  /// Optional Hero tag for shared-element transition.
  final Object? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  /// Opens the viewer with a fade + Hero transition.
  static void open(
    BuildContext context, {
    required String imageUrl,
    Object? heroTag,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(imageUrl: imageUrl, heroTag: heroTag);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();
  late AnimationController _doubleTapController;
  Animation<Matrix4>? _doubleTapAnimation;

  // Swipe-to-dismiss tracking
  double _dragOffset = 0;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _doubleTapController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 250),
        )..addListener(() {
          if (_doubleTapAnimation != null) {
            _transformController.value = _doubleTapAnimation!.value;
          }
        });
    // Immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _doubleTapController.dispose();
    _transformController.dispose();
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final Matrix4 end;

    if (currentScale > 1.05) {
      // Zoom out to fit
      end = Matrix4.identity();
    } else {
      // Zoom in 2.5× centered on tap position
      const targetScale = 2.5;
      final position = details.localPosition;
      end = Matrix4.identity()
        ..translate(
          -position.dx * (targetScale - 1),
          -position.dy * (targetScale - 1),
        )
        ..scale(targetScale);
    }

    _doubleTapAnimation =
        Matrix4Tween(begin: _transformController.value, end: end).animate(
          CurvedAnimation(
            parent: _doubleTapController,
            curve: Curves.easeInOut,
          ),
        );
    _doubleTapController
      ..reset()
      ..forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    setState(() {
      _dragOffset += d.delta.dy;
      _opacity = (1 - (_dragOffset.abs() / 300)).clamp(0.4, 1.0);
    });
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > 100 || d.velocity.pixelsPerSecond.dy.abs() > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _dragOffset = 0;
        _opacity = 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = InteractiveViewer(
      transformationController: _transformController,
      minScale: 0.5,
      maxScale: 5.0,
      child: Center(
        child: Image.network(
          widget.imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: Colors.white70,
                strokeWidth: 2,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    if (widget.heroTag != null) {
      imageWidget = Hero(tag: widget.heroTag!, child: imageWidget);
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _opacity),
      body: Stack(
        children: [
          // Image with swipe-to-dismiss
          GestureDetector(
            onDoubleTapDown: _handleDoubleTap,
            onDoubleTap: () {}, // required for onDoubleTapDown
            onVerticalDragUpdate:
                _transformController.value.getMaxScaleOnAxis() <= 1.05
                ? _onVerticalDragUpdate
                : null,
            onVerticalDragEnd:
                _transformController.value.getMaxScaleOnAxis() <= 1.05
                ? _onVerticalDragEnd
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              transform: Matrix4.translationValues(0, _dragOffset, 0),
              child: SizedBox.expand(child: imageWidget),
            ),
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 12,
            child: SafeArea(
              top: false,
              child: Material(
                color: Colors.black45,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.close, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
