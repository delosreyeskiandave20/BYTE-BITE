import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/offline_part_matcher.dart';
import '../data/part_identifier.dart';
import '../firebase_bootstrap.dart';
import '../theme/app_theme.dart';
import 'camera_capture_page.dart';

typedef IdentifyImagePicker = Future<XFile?> Function(ImageSource source);

class IdentifyPage extends StatefulWidget {
  const IdentifyPage({
    super.key,
    this.pickImage,
    this.onSearchParts,
    this.onSearchQuery,
    this.identifyPart,
    this.offlineMatcher,
  });

  /// Lets tests supply a fake picker instead of opening the device camera.
  final IdentifyImagePicker? pickImage;

  /// Opens the parts library so shoppers can identify a part manually.
  final VoidCallback? onSearchParts;

  /// Opens the parts library pre-filled with the part the AI recognized.
  final ValueChanged<String>? onSearchQuery;

  /// AI recognizer. Defaults to Gemini when Firebase is configured; when
  /// neither is available the page works as a photo preview only.
  final PartIdentifier? identifyPart;

  /// Recognizes parts without internet when the online AI cannot be
  /// reached. Defaults to [OfflinePartMatcher.shared]; tests inject a fake.
  final OfflinePartMatcher? offlineMatcher;

  @override
  State<IdentifyPage> createState() => _IdentifyPageState();
}

class _IdentifyPageState extends State<IdentifyPage> {
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _photoBytes;
  String? _photoName;
  bool _isPicking = false;

  late final PartIdentifier? _identifier =
      widget.identifyPart ??
      (FirebaseBootstrap.isInitialized ? GeminiPartIdentifier().call : null);
  late final OfflinePartMatcher _offline =
      widget.offlineMatcher ?? OfflinePartMatcher.shared;
  bool _isIdentifying = false;
  PartIdentification? _result;
  String? _identifyError;
  String _photoMimeType = 'image/jpeg';

  /// Bumped for every new photo so a slow answer for an old photo is ignored.
  int _requestId = 0;

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
      _photoMimeType = _mimeTypeFor(file);
      _result = null;
      _identifyError = null;
    });
    if (_identifier == null && !_offline.isSupported) {
      _showMessage(
        'Photo preview ready. AI part recognition is not connected yet.',
      );
      return;
    }
    await _identify();
  }

  Future<void> _identify() async {
    final identifier = _identifier;
    final bytes = _photoBytes;
    if (bytes == null) return;
    if (identifier == null && !_offline.isSupported) return;

    final requestId = ++_requestId;
    setState(() {
      _isIdentifying = true;
      _result = null;
      _identifyError = null;
    });
    try {
      if (identifier == null) {
        throw const PartIdentificationException(
          'AI part recognition is not connected yet.',
        );
      }
      final result = await identifier(bytes, _photoMimeType);
      if (!mounted || requestId != _requestId) return;
      setState(() => _result = result);
    } catch (error) {
      // No internet (or the AI is unavailable): match offline instead.
      final offline = await _matchOffline(bytes);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        if (offline != null) {
          _result = offline;
        } else {
          _identifyError = error is PartIdentificationException
              ? error.message
              : 'Could not identify the part. Please try again.';
        }
      });
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _isIdentifying = false);
      }
    }
  }

  /// The closest bundled part photos, or null when offline matching is not
  /// available on this platform or fails.
  Future<PartIdentification?> _matchOffline(Uint8List bytes) async {
    if (!_offline.isSupported) return null;
    try {
      final matches = await _offline.match(bytes);
      return matches.isEmpty ? null : PartIdentification.offline(matches);
    } catch (error) {
      debugPrint('Offline matching failed: $error');
      return null;
    }
  }

  static String _mimeTypeFor(XFile file) {
    final declared = file.mimeType;
    if (declared != null && declared.startsWith('image/')) return declared;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.heic')) return 'image/heic';
    return 'image/jpeg';
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
      _requestId++;
      _photoBytes = null;
      _photoName = null;
      _result = null;
      _identifyError = null;
      _isIdentifying = false;
    });
  }

  /// "Search the parts library": after a successful scan, opens the library
  /// with the scanned part name so its matches are listed first; otherwise
  /// opens the full library.
  void _searchLibrary() {
    final result = _result;
    if (result != null &&
        result.isMotorcyclePart &&
        result.partName.isNotEmpty) {
      _searchFor(result.partName);
    } else {
      widget.onSearchParts?.call();
    }
  }

  void _searchFor(String term) {
    final onSearchQuery = widget.onSearchQuery;
    if (onSearchQuery != null) {
      onSearchQuery(term);
    } else {
      widget.onSearchParts?.call();
    }
  }

  Widget _buildAiCard() {
    final Widget child;
    if (_isIdentifying) {
      child = const Row(
        key: ValueKey('identify-ai-loading'),
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Identifying the part…',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    } else if (_identifyError != null) {
      child = Column(
        key: const ValueKey('identify-ai-error'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _identifyError!,
                  style: const TextStyle(color: AppColors.ink, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            key: const ValueKey('identify-ai-retry'),
            onPressed: _identify,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Try again'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      );
    } else {
      final result = _result!;
      if (!result.isMotorcyclePart || result.partName.isEmpty) {
        child = const Row(
          key: ValueKey('identify-ai-not-part'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'This doesn\'t look like a motorcycle part. Try another photo '
                'with the part filling most of the frame.',
                style: TextStyle(color: AppColors.ink, height: 1.4),
              ),
            ),
          ],
        );
      } else {
        // Search with the full part name ("Rear shock absorber"); search
        // ranks the closest names first and still lists partial matches.
        final term = result.partName;
        child = Column(
          key: const ValueKey('identify-ai-result'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isOffline ? Icons.wifi_off : Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  result.isOffline ? 'Offline match' : 'AI match',
                  key: const ValueKey('identify-ai-source'),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              result.partName,
              key: const ValueKey('identify-ai-part-name'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${result.categoryName} · ${result.confidence} confidence',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (result.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                result.description,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
            if (result.confidence == 'low') ...[
              const SizedBox(height: 6),
              const Text(
                'Not sure? Retake the photo closer, or search the library.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
            if (result.alternatives.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Also could be',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final alternative in result.alternatives)
                    ActionChip(
                      key: ValueKey('identify-alternative-$alternative'),
                      label: Text(alternative),
                      onPressed: () => _searchFor(alternative),
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.line),
                      labelStyle: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('identify-ai-find'),
              onPressed: () => _searchFor(term),
              icon: const Icon(Icons.storefront_outlined, size: 18),
              label: Text(
                'Find "$term" in shops',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ],
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.line),
      ),
      child: Semantics(liveRegion: true, child: child),
    );
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
        foregroundColor: AppColors.primary,
        minimumSize: const Size.fromHeight(46),
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
      ),
    );

    Widget photoPlaceholder() => Container(
      width: isCompact ? 96 : 132,
      height: isCompact ? 96 : 132,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
      ),
      child: const Center(
        child: Icon(
          Icons.center_focus_strong,
          size: 48,
          color: AppColors.primary,
        ),
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
                foregroundColor: AppColors.primary,
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
                if (!hasPhoto) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Start with a clear photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: isCompact ? 18 : 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Place the part on a plain surface. Avoid glare and keep its full shape in frame.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
                SizedBox(height: hasPhoto ? 8 : 18),
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
                    onPressed: _isPicking ? null : _searchLibrary,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search the parts library'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hasPhoto &&
              (_isIdentifying ||
                  _result != null ||
                  _identifyError != null)) ...[
            const SizedBox(height: 14),
            _buildAiCard(),
          ],
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
                Icon(Icons.lightbulb, color: AppColors.primary),
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
