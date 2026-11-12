import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import 'camera_capture_page.dart';

typedef IdentifyImagePicker = Future<XFile?> Function(ImageSource source);

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({super.key, this.pickImage, this.onSearchParts});

  /// Lets tests supply a fake picker instead of opening the device camera.
  final IdentifyImagePicker? pickImage;

  /// Opens the parts library so shoppers can identify a part manually while
  /// AI recognition is not connected.
  final VoidCallback? onSearchParts;

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isPicking = false;

  Future<void> _takePhoto() async {
    if (_isPicking) return;

    final injectedPicker = widget.pickImage;
    if (injectedPicker != null) {
      await _runPicker(() => injectedPicker(ImageSource.camera));
      return;
    }

    setState(() => _isPicking = true);
    try {
      final file = await Navigator.of(context).push<XFile>(
        MaterialPageRoute<XFile>(builder: (_) => const CameraCapturePage()),
      );
      await _usePhoto(file);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not open the camera. Please try again.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _uploadPhoto() {
    return _runPicker(() {
      final injectedPicker = widget.pickImage;
      if (injectedPicker != null) {
        return injectedPicker(ImageSource.gallery);
      }
      return _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2048,
      );
    });
  }

  Future<void> _runPicker(Future<XFile?> Function() pick) async {
    if (_isPicking) return;
    setState(() => _isPicking = true);
    try {
      final file = await pick();
      await _usePhoto(file);
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showMessage(_pickerErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not open the photo picker. Please try again.');
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _usePhoto(XFile? file) async {
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name.trim().isEmpty ? null : file.name;
    });
    _showMessage(
      'Photo preview ready. AI part recognition is not connected yet.',
    );
  }

  String _pickerErrorMessage(PlatformException error) {
    switch (error.code) {
      case 'camera_access_denied':
        return 'Camera access is blocked. Allow camera access in your device settings and try again.';
      case 'photo_access_denied':
        return 'Photo access is blocked. Allow photo access in your device settings and try again.';
      default:
        return 'The photo could not be opened (${error.code}). Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _removePhoto() {
    if (_isPicking) return;
    setState(() {
      _photoBytes = null;
      _photoName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 340;
    final hasPhoto = _photoBytes != null;

    Widget takePhotoButton() => FilledButton.icon(
      key: const ValueKey('identify-take-photo'),
      onPressed: _isPicking ? null : _takePhoto,
      icon: _isPicking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.photo_camera_outlined, size: 18),
      label: Text(
        hasPhoto ? 'Retake photo' : 'Take a photo',
        maxLines: 1,
        softWrap: false,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
      ),
    );

    Widget uploadButton() => OutlinedButton.icon(
      key: const ValueKey('identify-upload-photo'),
      onPressed: _isPicking ? null : _uploadPhoto,
      icon: const Icon(Icons.upload_file, size: 18),
      label: const Text('Upload', maxLines: 1, softWrap: false),
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.teal,
        minimumSize: const Size.fromHeight(46),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
      ),
    );

    Widget photoPlaceholder() => Container(
      width: isCompact ? 96 : 132,
      height: isCompact ? 96 : 132,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.tealSoft,
      ),
      child: const Center(
        child: Icon(Icons.center_focus_strong, size: 48, color: AppColors.teal),
      ),
    );

    Widget photoPreview() => Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            _photoBytes!,
            key: const ValueKey('identify-photo-preview'),
            width: double.infinity,
            height: isCompact ? 180 : 220,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                _photoName ?? 'Selected photo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
            TextButton.icon(
              key: const ValueKey('identify-remove-photo'),
              onPressed: _isPicking ? null : _removePhoto,
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Identify a part')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 12 : 20,
          12,
          isCompact ? 12 : 20,
          24,
        ),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'MOTOSCAN / INTELLIGENCE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.teal,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Preview only',
                      style: TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Identify a part',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: isCompact ? 26 : 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Don’t know the name? A clear view of the component can help you identify it.',
            style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.tealBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.teal, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Photo preview works here. AI part recognition still needs a service connection.',
                    style: TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(isCompact ? 14 : 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: hasPhoto
                        ? KeyedSubtree(
                            key: const ValueKey('identify-preview-step'),
                            child: photoPreview(),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('identify-empty-step'),
                            child: photoPlaceholder(),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    hasPhoto
                        ? 'Photo ready to review'
                        : 'Start with a clear photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  hasPhoto
                      ? 'Your photo stays on this device. AI part recognition still needs a service connection.'
                      : 'Place the part on a plain surface. Avoid glare and keep its full shape in frame.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                if (isCompact) ...[
                  takePhotoButton(),
                  const SizedBox(height: 8),
                  uploadButton(),
                ] else
                  Row(
                    children: [
                      Expanded(child: takePhotoButton()),
                      const SizedBox(width: 9),
                      Expanded(child: uploadButton()),
                    ],
                  ),
                if (widget.onSearchParts != null) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    key: const ValueKey('identify-search-parts'),
                    onPressed: _isPicking ? null : widget.onSearchParts,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search the parts library'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.route_outlined, color: AppColors.teal, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'How preview works',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StepChip(number: '1', label: 'Frame the part'),
                    _StepChip(number: '2', label: 'Capture or upload'),
                    _StepChip(number: '3', label: 'Review the preview'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb, color: AppColors.teal),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Better input, better match',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Photograph labels, bolt holes, connectors, and the full silhouette when possible.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 10, 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.tealSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.teal,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.inkSoft,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
