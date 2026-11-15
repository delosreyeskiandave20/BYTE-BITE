import 'package:flutter/material.dart';

/// Wraps a thumbnail so tapping it opens [imageAsset] full screen, where it
/// can be pinched or double-tapped to zoom.
class ZoomableImage extends StatelessWidget {
  const ZoomableImage({
    required this.imageAsset,
    required this.title,
    required this.child,
    super.key,
  });

  final String imageAsset;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Zoom photo of $title',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showImageViewer(context, imageAsset, title),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            child,
            Positioned(
              right: 6,
              bottom: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen, zoomable view of a bundled photo.
Future<void> showImageViewer(
  BuildContext context,
  String imageAsset,
  String title,
) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, _, _) =>
          _ImageViewer(imageAsset: imageAsset, title: title),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class _ImageViewer extends StatefulWidget {
  const _ImageViewer({required this.imageAsset, required this.title});

  final String imageAsset;
  final String title;

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  final _controller = TransformationController();
  TapDownDetails? _doubleTap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Double-tap toggles between fit and 2.5x around the tapped point.
  void _toggleZoom() {
    if (_controller.value.getMaxScaleOnAxis() > 1.01) {
      _controller.value = Matrix4.identity();
      return;
    }
    final point = _doubleTap?.localPosition ?? Offset.zero;
    const scale = 2.5;
    _controller.value = Matrix4.identity()
      ..translateByDouble(
        -point.dx * (scale - 1),
        -point.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          tooltip: 'Close zoomed image',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: GestureDetector(
        onDoubleTapDown: (details) => _doubleTap = details,
        onDoubleTap: _toggleZoom,
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1,
          maxScale: 5,
          child: SizedBox.expand(
            child: Image.asset(
              widget.imageAsset,
              key: const ValueKey('zoomed-image'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            'Pinch or double-tap to zoom',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
