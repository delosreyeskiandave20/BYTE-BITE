import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key, this.cameraLister});

  /// Lets tests provide a camera list without touching platform channels.
  final Future<List<CameraDescription>> Function()? cameraLister;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _starting = true;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera({int? cameraIndex}) async {
    if (!mounted) return;
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      var cameras = _cameras;
      if (cameras.isEmpty) {
        cameras = await (widget.cameraLister ?? availableCameras)();
        if (!mounted) return;
        _cameras = cameras;
      }
      if (cameras.isEmpty) {
        throw CameraException(
          'cameraNotFound',
          'No camera was found on this device.',
        );
      }

      final index = (cameraIndex ?? _cameraIndex) % cameras.length;
      final controller = CameraController(
        cameras[index],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _cameraIndex = index;
        _starting = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _controller = null;
        _starting = false;
        _error = _messageFor(error);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _controller = null;
        _starting = false;
        _error = 'The camera could not be started. $error';
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _starting || _capturing) return;
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    final controller = _controller;
    _controller = null;
    await controller?.dispose();
    await _initializeCamera(cameraIndex: nextIndex);
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } on CameraException catch (error) {
      if (!mounted) return;
      _showMessage(_messageFor(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('The photo could not be captured. Please try again.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _useDeviceCameraApp() async {
    if (_capturing) return;
    setState(() => _capturing = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
        maxWidth: 2048,
      );
      if (!mounted || file == null) return;
      Navigator.of(context).pop(file);
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(_pickerErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not open the camera app. Please try again.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  String _messageFor(CameraException error) {
    switch (error.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
      case 'NotAllowedError':
      case 'PermissionDeniedError':
      case 'SecurityError':
        return 'Camera access is blocked. Allow camera access in your browser or device settings, then try again.';
      case 'cameraNotFound':
      case 'CameraNotFound':
      case 'NotFoundError':
      case 'DevicesNotFoundError':
        return 'No camera was found on this device.';
      default:
        return error.description ??
            'The camera could not be started (${error.code}).';
    }
  }

  String _pickerErrorMessage(PlatformException error) {
    if (error.code == 'camera_access_denied') {
      return 'Camera access is blocked. Allow camera access in your device settings, then try again.';
    }
    return 'Could not open the camera app (${error.code}). Please try again.';
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Take a photo'),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final controller = _controller;
    if (_error != null) return _buildError();
    if (_starting || controller == null || !controller.value.isInitialized) {
      return _buildStarting();
    }
    return _buildPreview(controller);
  }

  Widget _buildStarting() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Starting camera…',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(CameraController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: Center(
            child: Semantics(
              image: true,
              label: 'Camera preview',
              child: CameraPreview(controller),
            ),
          ),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _FramingGridPainter()),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fit the part inside the frame',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 52, height: 52),
                    _captureButton(),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: _cameras.length > 1
                          ? IconButton(
                              key: const ValueKey('camera-switch-button'),
                              tooltip: 'Switch camera',
                              onPressed: _starting || _capturing
                                  ? null
                                  : _switchCamera,
                              icon: const Icon(
                                Icons.cameraswitch_outlined,
                                color: Colors.white,
                                size: 26,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _captureButton() {
    return Tooltip(
      message: 'Capture photo',
      child: InkResponse(
        key: const ValueKey('camera-capture-button'),
        onTap: _capturing ? null : _capturePhoto,
        radius: 42,
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white24,
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _capturing ? Colors.white54 : Colors.white,
              ),
              child: _capturing
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              key: const ValueKey('camera-retry-button'),
              onPressed: () => _initializeCamera(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try again'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('camera-fallback-button'),
              onPressed: _capturing ? null : _useDeviceCameraApp,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Open camera app instead'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'You can also close the camera and upload a photo from the Scan tab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rule-of-thirds guide shown over the camera preview. Purely decorative, so
/// screen readers ignore it.
class _FramingGridPainter extends CustomPainter {
  const _FramingGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1;
    for (var i = 1; i <= 2; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
