import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/item_parts.dart';
import '../data/item_specs.dart';
import '../data/product_photo_storage.dart';
import '../models/shop.dart' show FitSpec;
import '../theme/app_theme.dart';
import '../widgets/motorcycle_checklist.dart';

/// Most photos (uploads and links together) a seller can add to one item.
const maxItemPhotos = 8;

/// Largest photo a seller can upload.
const maxPhotoBytes = 10 * 1024 * 1024;

/// Shortest and longest name a seller can type for their own part.
const minCustomPartLength = 2;
const maxCustomPartLength = 60;

const _allowedPhotoTypes = {'jpg', 'jpeg', 'png', 'webp'};

/// Shown when a pasted link does not load as an image.
const notAnImageMessage =
    'This link is not an image. Please check the URL or upload a photo '
    'instead.';

/// Picks photos from the camera or gallery. Swappable for tests.
typedef ItemPhotoPicker = Future<List<PickedPhoto>> Function(
  ImageSource source,
  int limit,
);

/// Builds the image for a pasted link. Swappable for tests.
typedef UrlImageBuilder = ImageProvider Function(String url);

/// One photo of the item: either picked on the device or a pasted link.
class ItemPhoto {
  ItemPhoto.upload(PickedPhoto this.upload) : url = null;
  ItemPhoto.link(String this.url) : upload = null;

  final PickedPhoto? upload;
  final String? url;
}

/// What the seller posted.
class AddItemResult {
  const AddItemResult({
    required this.category,
    required this.part,
    required this.isCustomPart,
    required this.name,
    required this.brand,
    required this.condition,
    required this.price,
    required this.quantity,
    required this.photos,
    required this.motorcycles,
    required this.fitsAll,
    required this.specLabel,
    required this.specs,
    required this.description,
  });

  final String category;
  final String part;

  /// True when the seller typed their own part; tagged "Custom" for review.
  final bool isCustomPart;
  final String name;
  final String brand;
  final String condition;
  final double price;
  final int quantity;

  /// Photos in the seller's order. The first is the cover.
  final List<ItemPhoto> photos;
  final List<String> motorcycles;
  final bool fitsAll;
  final String specLabel;
  final List<FitSpec> specs;
  final String description;
}

Future<List<PickedPhoto>> _defaultPhotoPicker(
  ImageSource source,
  int limit,
) async {
  final picker = ImagePicker();
  final files = source == ImageSource.camera
      ? [
          ?await picker.pickImage(
            source: source,
            maxWidth: 2000,
            imageQuality: 88,
          ),
        ]
      : await picker.pickMultiImage(
          maxWidth: 2000,
          imageQuality: 88,
          limit: limit > 1 ? limit : null,
        );
  return [
    for (final file in files.take(limit))
      PickedPhoto(
        bytes: await file.readAsBytes(),
        extension: file.name.contains('.')
            ? file.name.split('.').last.toLowerCase()
            : 'jpg',
      ),
  ];
}

IconData categoryIcon(String category) => switch (category) {
  'Engine' => Icons.settings_outlined,
  'Electrical' => Icons.electrical_services,
  'Suspension' => Icons.compress,
  'Wheels and Tires' => Icons.tire_repair,
  'Body Parts' => Icons.two_wheeler,
  'Accessories' => Icons.shopping_bag_outlined,
  'Maintenance' => Icons.build_outlined,
  'Designs' => Icons.palette_outlined,
  _ => Icons.category_outlined,
};

/// "Label *" with a red star, for required fields.
Widget requiredLabel(String text) => Text.rich(
  TextSpan(
    text: text,
    children: const [
      TextSpan(
        text: ' *',
        style: TextStyle(color: AppColors.danger),
      ),
    ],
  ),
);

/// Add Item for a signed-in seller, in three steps:
/// 1 Category → 2 Part → 3 Details.
class AddItemPage extends StatefulWidget {
  const AddItemPage({
    this.pickPhotos,
    this.imageForUrl,
    this.canUploadPhotos = true,
    this.specRows,
    super.key,
  });

  final ItemPhotoPicker? pickPhotos;
  final UrlImageBuilder? imageForUrl;

  /// False hides camera/gallery; sellers can still paste image links.
  final bool canUploadPhotos;

  /// The motorcycle master table; loaded from the CSV when null.
  final List<ItemSpecRow>? specRows;

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  // Step 1 and 2.
  int _step = 0;
  String? _category;
  String? _listedPart;
  bool _typingCustom = false;
  bool _isCustom = false;
  String _partQuery = '';
  final _customPart = TextEditingController();

  // Step 3.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController();
  final _description = TextEditingController();
  final _url = TextEditingController();
  String? _prefilledName;
  String? _condition;
  MotorcycleFit _fit = const MotorcycleFit();
  final List<ItemPhoto> _photos = [];
  final Map<String, TextEditingController> _specValues = {};
  bool _urlOpen = false;
  bool _checkingUrl = false;
  String? _urlError;
  bool _triedToPost = false;

  final _photosKey = GlobalKey();
  final _nameKey = GlobalKey();
  final _conditionKey = GlobalKey();
  final _priceKey = GlobalKey();
  final _fitKey = GlobalKey();

  List<ItemSpecRow> _rows = const [];

  @override
  void initState() {
    super.initState();
    final rows = widget.specRows;
    if (rows != null) {
      _rows = rows;
    } else {
      loadItemSpecs().then((rows) {
        if (mounted) setState(() => _rows = rows);
      }, onError: (_) {});
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _customPart,
      _name,
      _brand,
      _price,
      _quantity,
      _description,
      _url,
      ..._specValues.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------ navigation

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
    }
  }

  void _chooseCategory(String category) {
    setState(() {
      if (category != _category) {
        _listedPart = null;
        _partQuery = '';
      }
      _category = category;
      _step = 1;
    });
  }

  void _chooseListedPart(String part) {
    FocusScope.of(context).unfocus();
    setState(() {
      _listedPart = part;
      _typingCustom = false;
    });
  }

  String? get _customPartError {
    final length = _customPart.text.trim().length;
    if (length == 0) return null;
    if (length < minCustomPartLength) {
      return 'Please type at least $minCustomPartLength letters.';
    }
    if (length > maxCustomPartLength) {
      return 'Please keep it to $maxCustomPartLength characters or less.';
    }
    return null;
  }

  bool get _customPartValid =>
      _customPart.text.trim().isNotEmpty && _customPartError == null;

  bool get _canProceed =>
      _typingCustom ? _customPartValid : _listedPart != null;

  /// The part being sold, once step 2 is done.
  String get _part => _isCustom ? _customPart.text.trim() : _listedPart ?? '';

  Future<void> _proceed() async {
    if (!_canProceed) return;
    var custom = _typingCustom;
    if (custom) {
      final typed = _customPart.text.trim();
      final match = closestPart(typed, _category!);
      if (match != null) {
        final useIt = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Did you mean ${match.part}?'),
            content: Text(
              '"${match.part}" is already on our list'
              '${match.category == _category ? '' : ' under ${match.category}'}.',
            ),
            actions: [
              TextButton(
                key: const ValueKey('did-you-mean-no'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No, keep mine'),
              ),
              FilledButton(
                key: const ValueKey('did-you-mean-yes'),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, use it'),
              ),
            ],
          ),
        );
        if (!mounted || useIt == null) return;
        if (useIt) {
          custom = false;
          _category = match.category;
          _listedPart = match.part;
          _typingCustom = false;
        }
      }
    }
    setState(() {
      _isCustom = custom;
      // Prefill the product name with the part, unless the seller already
      // typed their own.
      final name = _name.text.trim();
      if (name.isEmpty || name == _prefilledName) {
        _name.text = _part;
        _prefilledName = _part;
      }
      _step = 2;
    });
  }

  // ----------------------------------------------------------------- photos

  Future<void> _addPhotos() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final room = maxItemPhotos - _photos.length;
    List<PickedPhoto> picked;
    try {
      picked = await (widget.pickPhotos ?? _defaultPhotoPicker)(source, room);
    } catch (_) {
      _toast(
        'Could not open your photos. You can paste an image link instead.',
      );
      return;
    }
    if (!mounted || picked.isEmpty) return;
    final accepted = [
      for (final photo in picked)
        if (_allowedPhotoTypes.contains(photo.extension) &&
            photo.bytes.length <= maxPhotoBytes)
          ItemPhoto.upload(photo),
    ];
    setState(() => _photos.addAll(accepted.take(room)));
    if (accepted.length < picked.length) {
      _toast('Some photos were skipped. Use JPG, PNG or WEBP, 10 MB or less.');
    }
  }

  ImageProvider _imageForUrl(String url) =>
      widget.imageForUrl?.call(url) ?? NetworkImage(url);

  /// True when [provider] decodes as an image within 15 seconds.
  Future<bool> _loadsAsImage(ImageProvider provider) {
    final done = Completer<bool>();
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, _) {
        if (!done.isCompleted) done.complete(true);
      },
      onError: (_, _) {
        if (!done.isCompleted) done.complete(false);
      },
    );
    stream.addListener(listener);
    return done.future
        .timeout(const Duration(seconds: 15), onTimeout: () => false)
        .whenComplete(() => stream.removeListener(listener));
  }

  Future<void> _addUrl() async {
    final url = _url.text.trim();
    final uri = Uri.tryParse(url);
    if (!url.startsWith('https://') || uri == null || uri.host.isEmpty) {
      setState(() => _urlError = 'The link must start with https://');
      return;
    }
    if (_photos.any((photo) => photo.url == url)) {
      setState(() => _urlError = 'This link is already added.');
      return;
    }
    setState(() {
      _checkingUrl = true;
      _urlError = null;
    });
    final ok = await _loadsAsImage(_imageForUrl(url));
    if (!mounted) return;
    setState(() {
      _checkingUrl = false;
      if (!ok) {
        _urlError = notAnImageMessage;
      } else if (_photos.length < maxItemPhotos) {
        _photos.add(ItemPhoto.link(url));
        _url.clear();
        _urlOpen = false;
      }
    });
  }

  void _setCover(int index) {
    setState(() => _photos.insert(0, _photos.removeAt(index)));
  }

  void _reorderPhotos(int oldIndex, int newIndex) {
    setState(() => _photos.insert(newIndex, _photos.removeAt(oldIndex)));
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------------ specs

  /// The spec column auto-filled for this part; never for custom parts.
  ItemSpecField? get _specField => _isCustom ? null : specFieldForPart(_part);

  ItemSpecRow? _rowFor(String motorcycle) {
    for (final row in _rows) {
      if (row.motorcycle == motorcycle) return row;
    }
    return null;
  }

  TextEditingController _specController(String motorcycle) =>
      _specValues.putIfAbsent(motorcycle, () {
        final field = _specField;
        final value = field == null
            ? null
            : _rowFor(motorcycle)?.valueOf(field)?.value;
        return TextEditingController(text: value ?? '');
      });

  // --------------------------------------------------------------- validity

  String? _nameError(String? value) =>
      (value?.trim().isEmpty ?? true) ? 'Please type a product name.' : null;

  String? _priceError(String? value) {
    final price = double.tryParse(value?.trim() ?? '');
    return price == null || !price.isFinite || price <= 0
        ? 'Please enter a price above 0.'
        : null;
  }

  String? _quantityError(String? value) {
    final quantity = int.tryParse(value?.trim() ?? '');
    return quantity == null || quantity < 1
        ? 'Please enter a whole number, 1 or more.'
        : null;
  }

  bool get _isComplete =>
      _photos.isNotEmpty &&
      _nameError(_name.text) == null &&
      _condition != null &&
      _priceError(_price.text) == null &&
      _quantityError(_quantity.text) == null &&
      _fit.isValid;

  /// The first section with a problem, in form order.
  GlobalKey? get _firstError {
    if (_nameError(_name.text) != null) return _nameKey;
    if (_condition == null) return _conditionKey;
    if (_priceError(_price.text) != null ||
        _quantityError(_quantity.text) != null) {
      return _priceKey;
    }
    if (_photos.isEmpty) return _photosKey;
    if (!_fit.isValid) return _fitKey;
    return null;
  }

  Future<void> _post() async {
    setState(() => _triedToPost = true);
    _formKey.currentState?.validate();
    final problem = _firstError;
    if (problem != null) {
      final target = problem.currentContext;
      if (target != null) {
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          alignment: 0.1,
        );
      }
      return;
    }
    final field = _specField;
    final motorcycles = _fit.universal ? const <String>[] : _fit.motorcycles;
    final specs = field == null
        ? const <FitSpec>[]
        : [
            for (final motorcycle in motorcycles)
              if (_specController(motorcycle).text.trim() case final value
                  when value.isNotEmpty)
                FitSpec(motorcycle: motorcycle, value: value),
          ];
    Navigator.of(context).pop(
      AddItemResult(
        category: _category!,
        part: _part,
        isCustomPart: _isCustom,
        name: _name.text.trim(),
        brand: _brand.text.trim(),
        condition: _condition!,
        price: double.parse(_price.text.trim()),
        quantity: int.parse(_quantity.text.trim()),
        photos: List.unmodifiable(_photos),
        motorcycles: List.unmodifiable(motorcycles),
        fitsAll: _fit.universal,
        specLabel: field == null ? '' : _part,
        specs: List.unmodifiable(specs),
        description: _description.text.trim(),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        appBar: AppBar(
          leading: IconButton(
            tooltip: _step == 0 ? 'Cancel' : 'Back',
            onPressed: _back,
            icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          ),
          title: const Text('Add Item'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: _StepBar(step: _step),
          ),
        ),
        body: switch (_step) {
          0 => _categoryStep(),
          1 => _partStep(),
          _ => _detailsStep(),
        },
      ),
    );
  }

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: AppType.section,
        fontWeight: FontWeight.w900,
      ),
    ),
  );

  Widget _categoryStep() {
    return ListView(
      key: const ValueKey('step-category'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _title('What kind of part are you selling?'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            for (final category in itemCategories)
              _CategoryCard(
                key: ValueKey('category-$category'),
                category: category,
                selected: category == _category,
                onTap: () => _chooseCategory(category),
              ),
          ],
        ),
      ],
    );
  }

  Widget _partStep() {
    final parts = partsByCategory[_category] ?? const <String>[];
    final needle = _partQuery.trim().toLowerCase();
    final shown = [
      for (final part in parts)
        if (part.toLowerCase().contains(needle)) part,
    ];
    final customError = _customPartError;
    return Column(
      key: const ValueKey('step-part'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _title('Which part is it?'),
              TextField(
                key: const ValueKey('part-search'),
                decoration: InputDecoration(
                  hintText: 'Search ${_category ?? ''} parts…',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (text) => setState(() => _partQuery = text),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No part matches your search.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              for (final part in shown)
                _PartTile(
                  key: ValueKey('part-$part'),
                  name: part,
                  selected: !_typingCustom && _listedPart == part,
                  onTap: () => _chooseListedPart(part),
                ),
              const SizedBox(height: 8),
              if (!_typingCustom)
                OutlinedButton.icon(
                  key: const ValueKey('part-custom-open'),
                  onPressed: () => setState(() {
                    _typingCustom = true;
                    _listedPart = null;
                  }),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text("Can't find your part? Type it here"),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: TextField(
                    key: const ValueKey('part-custom'),
                    controller: _customPart,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: maxCustomPartLength,
                    decoration: InputDecoration(
                      label: requiredLabel('Part name'),
                      hintText: 'e.g. Brake lever guard',
                      errorText: customError,
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: FilledButton(
              key: const ValueKey('proceed'),
              onPressed: _canProceed ? _proceed : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Proceed to Adding'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heading(String text, {bool required = false, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: AppType.body,
              fontWeight: FontWeight.w900,
            ),
            child: required ? requiredLabel(text) : Text(text),
          ),
          if (helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                helper,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: AppType.caption,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorLine(String text) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: AppColors.danger,
        fontSize: AppType.caption,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _detailsStep() {
    return Form(
      key: _formKey,
      autovalidateMode: _triedToPost
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      child: ListView(
        key: const ValueKey('step-details'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _summaryRow(),
          const SizedBox(height: 18),
          TextFormField(
            key: _nameKey,
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              label: requiredLabel('Product name'),
              hintText: 'e.g. NGK Spark Plug CPR8EA-9',
              border: const OutlineInputBorder(),
            ),
            validator: _nameError,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('add-item-brand'),
            controller: _brand,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Brand',
              hintText: 'e.g. NGK, Yamaha, Koso',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          _conditionSection(),
          const SizedBox(height: 18),
          Row(
            key: _priceKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('add-item-price'),
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    label: requiredLabel('Price (₱)'),
                    hintText: 'e.g. 250',
                    prefixText: '₱ ',
                    errorMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _priceError,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  key: const ValueKey('add-item-quantity'),
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    label: requiredLabel('Quantity'),
                    hintText: 'e.g. 5',
                    errorMaxLines: 2,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _quantityError,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            key: const ValueKey('add-item-description'),
            controller: _description,
            maxLines: 4,
            maxLength: 1000,
            decoration: const InputDecoration(
              labelText: 'Information',
              hintText:
                  'Tell buyers about the item: size, color, any defects, '
                  "what's included.",
              hintMaxLines: 3,
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          _photosSection(),
          const SizedBox(height: 22),
          _fitSection(),
          const SizedBox(height: 22),
          // Looks disabled until every required field is valid, but stays
          // tappable so the seller is taken to what is missing.
          FilledButton(
            key: const ValueKey('add-item-post'),
            onPressed: _post,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: _isComplete
                  ? AppColors.primary
                  : AppColors.lineStrong,
              foregroundColor: _isComplete ? Colors.white : AppColors.muted,
            ),
            child: const Text(
              'Post Item',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(categoryIcon(_category!), size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$_category › $_part',
              key: const ValueKey('add-item-summary'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          if (_isCustom)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Chip(
                label: Text('Custom'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          TextButton(
            key: const ValueKey('add-item-change'),
            onPressed: () => setState(() => _step = 0),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _photosSection() {
    final full = _photos.length >= maxItemPhotos;
    final missing = _triedToPost && _photos.isEmpty;
    // Once the seller pastes image links, the upload box is hidden.
    final usingLinks = _urlOpen || _photos.any((photo) => photo.url != null);
    final canUpload = widget.canUploadPhotos && !usingLinks;
    return Column(
      key: _photosKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Photos',
          required: true,
          helper: 'Add at least 1 clear photo of the actual item.',
        ),
        if (canUpload || _photos.isNotEmpty || _checkingUrl)
          Material(
            key: const ValueKey('add-item-photo-box'),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(
                color: missing ? AppColors.danger : AppColors.lineStrong,
                width: missing ? 1.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _photos.isEmpty && !_checkingUrl
                // Empty: the whole box opens the camera or gallery.
                ? InkWell(
                    key: const ValueKey('add-item-add-photo'),
                    onTap: _addPhotos,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 22),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 30,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Add photos',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Camera or gallery · JPG, PNG, WEBP · 10 MB max',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: AppType.micro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                // With photos: the thumbnails sit inside the box, followed
                // by a small tile to add more.
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 96,
                          child: ReorderableListView.builder(
                            key: const ValueKey('add-item-photos'),
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length,
                            onReorderItem: _reorderPhotos,
                            footer: _checkingUrl
                                ? _LinkPreviewTile(
                                    image: _imageForUrl(_url.text.trim()),
                                  )
                                : canUpload && !full
                                ? _AddMoreTile(onTap: _addPhotos)
                                : null,
                            itemBuilder: (context, index) {
                              final photo = _photos[index];
                              return Padding(
                                key: ObjectKey(photo),
                                padding: const EdgeInsets.only(right: 10),
                                child: _PhotoTile(
                                  key: ValueKey('add-item-photo-$index'),
                                  image: photo.upload != null
                                      ? MemoryImage(photo.upload!.bytes)
                                      : _imageForUrl(photo.url!),
                                  isCover: index == 0,
                                  onRemove: () =>
                                      setState(() => _photos.removeAt(index)),
                                  onSetCover: index == 0
                                      ? null
                                      : () => _setCover(index),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_photos.length} of $maxItemPhotos · '
                          'drag to reorder',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: AppType.micro,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        if (!full && !_urlOpen)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('add-item-url-open'),
              onPressed: () => setState(() => _urlOpen = true),
              icon: const Icon(Icons.link),
              label: Text(
                usingLinks
                    ? 'Add another image URL'
                    : 'No photo? Paste an image URL',
              ),
            ),
          ),
        // Lets the seller go back to uploading while no link is added yet.
        if (_urlOpen &&
            widget.canUploadPhotos &&
            !_checkingUrl &&
            !_photos.any((photo) => photo.url != null))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('add-item-upload-instead'),
              onPressed: () => setState(() {
                _urlOpen = false;
                _urlError = null;
                _url.clear();
              }),
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Upload photos instead'),
            ),
          ),
        if (!full && _urlOpen) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const ValueKey('add-item-image-url'),
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enabled: !_checkingUrl,
                  decoration: InputDecoration(
                    labelText: 'Image URL',
                    hintText: 'https://example.com/photo.jpg',
                    errorText: _urlError,
                    errorMaxLines: 3,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addUrl(),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: FilledButton.tonal(
                  key: const ValueKey('add-item-url-add'),
                  onPressed: _checkingUrl ? null : _addUrl,
                  child: _checkingUrl
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ),
            ],
          ),
        ],
        if (missing) _errorLine('Please add at least 1 photo'),
      ],
    );
  }

  Widget _conditionSection() {
    return Column(
      key: _conditionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Condition', required: true),
        Wrap(
          spacing: 8,
          children: [
            for (final condition in const ['New', 'Used', 'Surplus'])
              ChoiceChip(
                key: ValueKey('condition-$condition'),
                label: Text(condition),
                selected: _condition == condition,
                onSelected: (_) => setState(() => _condition = condition),
              ),
          ],
        ),
        if (_triedToPost && _condition == null)
          _errorLine('Please choose the condition.'),
      ],
    );
  }

  Widget _fitSection() {
    final showError = _triedToPost && !_fit.isValid;
    return Column(
      key: _fitKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          'Which motorcycles does this fit?',
          required: true,
          helper: 'Check all that apply.',
        ),
        MotorcycleChecklist(
          key: const ValueKey('add-item-motorcycles'),
          byBrand: motorcyclesByBrand(_rows),
          value: _fit,
          errorText: showError ? 'required' : null,
          onChanged: (fit) => setState(() => _fit = fit),
        ),
        if (showError)
          _errorLine(
            'Please check at least 1 motorcycle, or choose Universal.',
          ),
      ],
    );
  }

}

/// "1 Category → 2 Part → 3 Details", with the current step highlighted.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.step});

  final int step;

  static const _labels = ['Category', 'Part', 'Details'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          for (var index = 0; index < _labels.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: AppColors.faint,
                ),
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: index <= step
                        ? AppColors.primary
                        : AppColors.line,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: index <= step ? Colors.white : AppColors.muted,
                        fontSize: AppType.micro,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _labels[index],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: index == step ? AppColors.ink : AppColors.muted,
                        fontSize: AppType.caption,
                        fontWeight: index == step
                            ? FontWeight.w900
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(categoryIcon(category), size: 32, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                category,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({
    required this.name,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          selected: selected,
          title: Text(
            name,
            style: TextStyle(
              color: AppColors.ink,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          trailing: selected
              ? const Icon(Icons.check_circle, color: AppColors.primary)
              : null,
          onTap: onTap,
        ),
      ),
    );
  }
}

/// The pasted link's image, shown inside the photo box while it loads.
class _LinkPreviewTile extends StatelessWidget {
  const _LinkPreviewTile({required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('add-item-link-preview'),
      width: 96,
      height: 96,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image(
              image: image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: AppColors.noticeSoft,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "+ Add" tile after the thumbnails inside the photo box.
class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('add-item-add-photo'),
      color: AppColors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.primaryBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 96,
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
              SizedBox(height: 6),
              Text(
                'Add',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppType.caption,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.image,
    required this.isCover,
    required this.onRemove,
    this.onSetCover,
    super.key,
  });

  final ImageProvider image;
  final bool isCover;
  final VoidCallback onRemove;
  final VoidCallback? onSetCover;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image(
              image: ResizeImage(image, width: 288),
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 96,
                height: 96,
                color: AppColors.noticeSoft,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          if (isCover)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Cover',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else if (onSetCover != null)
            Positioned(
              left: 2,
              bottom: 2,
              child: IconButton.filled(
                tooltip: 'Set as cover',
                iconSize: 14,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  minimumSize: const Size(26, 26),
                ),
                onPressed: onSetCover,
                icon: const Icon(Icons.star_outline, color: Colors.white),
              ),
            ),
          Positioned(
            right: 2,
            top: 2,
            child: IconButton.filled(
              tooltip: 'Remove photo',
              iconSize: 14,
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                minimumSize: const Size(26, 26),
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
