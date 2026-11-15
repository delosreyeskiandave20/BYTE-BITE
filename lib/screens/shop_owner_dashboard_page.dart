import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../data/price_format.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/load_error_banner.dart';
import '../data/item_parts.dart';
import '../data/item_specs.dart';
import '../widgets/motorcycle_checklist.dart';
import 'add_item_page.dart';

/// Form validator for fields that must not be blank.
String? _requiredField(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required.';
  return null;
}

class ShopOwnerDashboardPage extends StatefulWidget {
  const ShopOwnerDashboardPage({
    required this.store,
    required this.ownerEmail,
    required this.onDone,
    this.pickPhotos,
    this.imageForUrl,
    this.specRows,
    super.key,
  });

  final ShopStore store;
  final String ownerEmail;
  final VoidCallback onDone;

  /// Overrides for the Add Item page; tests pass these to avoid loading
  /// assets, the network and the device photo picker.
  final ItemPhotoPicker? pickPhotos;
  final UrlImageBuilder? imageForUrl;
  final List<ItemSpecRow>? specRows;

  @override
  State<ShopOwnerDashboardPage> createState() => _ShopOwnerDashboardPageState();
}

class _ShopOwnerDashboardPageState extends State<ShopOwnerDashboardPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactController;

  bool _saving = false;
  bool _loadingShop = false;
  bool _sendingVerification = false;
  bool _checkingVerification = false;
  String? _loadError;
  String _savedSignature = '';
  final _productsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final shop = widget.store.shopForOwner(widget.ownerEmail);
    _nameController = TextEditingController(text: shop?.name ?? '');
    _locationController = TextEditingController(text: shop?.location ?? '');
    _descriptionController = TextEditingController(
      text: shop?.description ?? '',
    );
    _contactController = TextEditingController(text: shop?.contact ?? '');
    _savedSignature = _currentSignature;
    if (shop == null && widget.store.isCloudConnected) {
      _loadExistingShop();
    }
  }

  String get _currentSignature => [
    _nameController.text,
    _locationController.text,
    _descriptionController.text,
    _contactController.text,
  ].map((value) => value.trim()).join('\u0000');

  bool get _hasUnsavedChanges => _currentSignature != _savedSignature;

  Future<void> _loadExistingShop() async {
    setState(() {
      _loadingShop = true;
      _loadError = null;
    });
    try {
      final shop = await widget.store.loadShopForOwner(widget.ownerEmail);
      if (!mounted) return;
      if (shop != null) {
        if (_nameController.text.isEmpty) _nameController.text = shop.name;
        if (_locationController.text.isEmpty) {
          _locationController.text = shop.location;
        }
        if (_descriptionController.text.isEmpty) {
          _descriptionController.text = shop.description;
        }
        if (_contactController.text.isEmpty) {
          _contactController.text = shop.contact;
        }
      }
      _savedSignature = _currentSignature;
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = _describeError(error));
        _showError(error, action: 'load your shop');
      }
    } finally {
      if (mounted) setState(() => _loadingShop = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<bool> _saveShopDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return false;
    setState(() => _saving = true);
    try {
      await widget.store.saveShop(
        ownerEmail: widget.ownerEmail,
        name: _nameController.text,
        location: _locationController.text,
        description: _descriptionController.text,
        contact: _contactController.text,
      );
      _savedSignature = _currentSignature;
      return true;
    } catch (error) {
      if (mounted) _showError(error);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(Object error, {String action = 'save changes'}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not $action: ${_describeError(error)}'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  String _describeError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to change this shop.';
        case 'unauthenticated':
          return 'Your session expired. Sign in again.';
        case 'unavailable':
          return 'The service is unreachable. Check your connection and retry.';
        case 'deadline-exceeded':
          return 'The request timed out. Try again.';
        case 'failed-precondition':
          return 'The shop data is not ready yet. Refresh and try again.';
        case 'resource-exhausted':
          return 'Too many requests right now. Try again shortly.';
      }
      return error.message ?? error.code;
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Some shop details are invalid.';
    }
    if (error is StateError) return error.message;
    return error.toString();
  }

  Future<void> _handleBack() async {
    if (_saving) return;
    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'Your shop details have unsaved changes. Leave without saving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (!mounted || discard != true) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDone() async {
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save shop changes?'),
        content: const Text(
          'Save your shop details and return to the shop, or go back to keep editing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Back to editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save and view shop'),
          ),
        ],
      ),
    );
    if (!mounted || save != true) return;
    if (!await _saveShopDetails()) return;
    if (!mounted) return;
    widget.onDone();
  }

  Future<void> _addProduct() async {
    if (widget.store.shopForOwner(widget.ownerEmail) == null) {
      if (!await _saveShopDetails()) return;
    }
    if (!mounted) return;
    final item = await Navigator.of(context).push<AddItemResult>(
      MaterialPageRoute(
        builder: (_) => AddItemPage(
          pickPhotos: widget.pickPhotos,
          imageForUrl: widget.imageForUrl,
          specRows: widget.specRows,
          canUploadPhotos: widget.store.canUploadPhotos,
        ),
      ),
    );
    if (!mounted || item == null) return;
    setState(() => _saving = true);
    var posted = false;
    try {
      // Keep the seller's order: uploads are stored, pasted links are used
      // as they are. The first photo is the cover.
      final urls = [
        for (final photo in item.photos)
          photo.url ??
              await widget.store.uploadProductPhoto(
                ownerEmail: widget.ownerEmail,
                photo: photo.upload!,
              ),
      ];
      await widget.store.addProduct(
        ownerEmail: widget.ownerEmail,
        name: item.name,
        category: item.category,
        part: item.part,
        isCustomPart: item.isCustomPart,
        brand: item.brand,
        condition: item.condition,
        description: item.description,
        price: item.price,
        quantity: item.quantity,
        imageUrl: urls.isEmpty ? '' : urls.first,
        photoUrls: urls.skip(1).toList(),
        motorcycles: item.motorcycles,
        fitsAll: item.fitsAll,
        specLabel: item.specLabel,
        specs: item.specs,
      );
      posted = true;
    } catch (error) {
      if (mounted) _showError(error, action: 'post your item');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!posted || !mounted) return;
    final addAnother = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success),
        title: const Text('Item posted!'),
        content: Text('"${item.name}" is now listed in your shop.'),
        actions: [
          TextButton(
            key: const ValueKey('posted-add-another'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add another item'),
          ),
          FilledButton(
            key: const ValueKey('posted-view-items'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('View my items'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (addAnother == true) {
      await _addProduct();
      return;
    }
    // Bring the product list into view.
    final products = _productsKey.currentContext;
    if (products != null && products.mounted) {
      await Scrollable.ensureVisible(
        products,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  Future<void> _editProduct(ShopProduct product) async {
    final result = await showModalBottomSheet<_ProductDetails>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _EditProductSheet(product: product, specRows: widget.specRows),
    );
    if (!mounted || result == null) return;
    try {
      await widget.store.updateProduct(
        ownerEmail: widget.ownerEmail,
        productId: product.id,
        name: result.name,
        category: result.category,
        description: result.description,
        price: result.price,
        quantity: result.quantity,
        imageUrl: result.imageUrl,
        brand: result.brand,
        condition: result.condition,
        motorcycles: result.motorcycles,
        fitsAll: result.fitsAll,
        specs: result.specs,
      );
    } catch (error) {
      if (mounted) _showError(error);
    }
  }

  Future<void> _deleteProduct(ShopProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Remove “${product.name}” from your shop? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await widget.store.deleteProduct(
        ownerEmail: widget.ownerEmail,
        productId: product.id,
      );
    } catch (error) {
      if (mounted) _showError(error, action: 'delete the product');
    }
  }

  Future<void> _deleteShop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete shop?'),
        content: const Text(
          'Delete your shop profile and all of its products? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete shop'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    try {
      await widget.store.deleteShop(ownerEmail: widget.ownerEmail);
      if (!mounted) return;
      widget.onDone();
    } catch (error) {
      if (mounted) _showError(error, action: 'delete your shop');
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sendingVerification = true);
    try {
      await widget.store.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification email sent to ${widget.ownerEmail}.'),
        ),
      );
    } catch (error) {
      if (mounted) _showError(error, action: 'send the verification email');
    } finally {
      if (mounted) setState(() => _sendingVerification = false);
    }
  }

  Future<void> _checkVerification() async {
    setState(() => _checkingVerification = true);
    try {
      await widget.store.refreshOwnerAccount();
      if (!mounted) return;
      final verified = widget.store.isEmailVerified;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            verified ? 'Email verified. Your owner account is fully set up.' : 'Email is not verified yet. Open the link in your inbox and try again.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) _showError(error, action: 'check your email verification');
    } finally {
      if (mounted) setState(() => _checkingVerification = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to manage your shop.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await widget.store.signOut();
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to owner sign in',
          onPressed: _saving ? null : _handleBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Manage your shop'),
        backgroundColor: AppColors.paper,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _saving ? null : _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          if (_loadingShop) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading your shop…'),
                ],
              ),
            );
          }
          final shop = widget.store.shopForOwner(widget.ownerEmail);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              if (widget.store.isOwnerAuthAvailable &&
                  !widget.store.isEmailVerified) ...[
                _VerificationBanner(
                  email: widget.ownerEmail,
                  sending: _sendingVerification,
                  checking: _checkingVerification,
                  onSend: _sendVerificationEmail,
                  onCheck: _checkVerification,
                ),
                const SizedBox(height: 14),
              ],
              if (widget.store.syncError case final error?) ...[
                LoadErrorBanner(
                  message:
                      'A change was not saved online: ${_describeError(error)}',
                  onRetry: widget.store.clearSyncError,
                  actionLabel: 'Dismiss',
                ),
                const SizedBox(height: 14),
              ],
              if (_loadError != null) ...[
                LoadErrorBanner(
                  message: 'Could not load your shop: $_loadError',
                  onRetry: _loadExistingShop,
                ),
                const SizedBox(height: 14),
              ],
              const Text(
                'Shop profile',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add your shop name, location, and details. Products you list will appear in the Shop tab.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Shop name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _requiredField(value, 'Shop name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'City, province',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => _requiredField(value, 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Shop information',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('shop-contact'),
                      controller: _contactController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'How buyers can message you',
                        hintText: 'e.g. 09171234567 or m.me/yourshop',
                        helperText: 'Used by the "Message seller" button on your items.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                key: _productsKey,
                children: [
                  const Expanded(
                    child: Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _saving ? null : _addProduct,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (shop == null)
                const Text(
                  'Create your shop listing before adding products.',
                  style: TextStyle(color: AppColors.muted),
                )
              else if (shop.products.isEmpty)
                const Text(
                  'No products listed yet.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    children: [
                      for (var index = 0; index < shop.products.length; index++)
                        _OwnerProductTile(
                          key: ValueKey(
                            'owner-product-$index-${shop.products[index].id}',
                          ),
                          product: shop.products[index],
                          onEdit: () => _editProduct(shop.products[index]),
                          onDelete: () => _deleteProduct(shop.products[index]),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _confirmDone,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Done'),
                ),
              ),
              if (shop != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _deleteShop,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete shop'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(46),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Small in-button progress indicator shared by the verification actions.
const _verificationSpinner = SizedBox(
  width: 16,
  height: 16,
  child: CircularProgressIndicator(strokeWidth: 2),
);

class _VerificationBanner extends StatelessWidget {
  const _VerificationBanner({
    required this.email,
    required this.sending,
    required this.checking,
    required this.onSend,
    required this.onCheck,
  });

  final String email;
  final bool sending;
  final bool checking;
  final VoidCallback onSend;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'We sent a verification link to $email. Confirm it to secure your owner account.',
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              TextButton(
                onPressed: sending ? null : onSend,
                child: sending
                    ? _verificationSpinner
                    : const Text('Resend email'),
              ),
              TextButton(
                onPressed: checking ? null : onCheck,
                child: checking
                    ? _verificationSpinner
                    : const Text('I have verified'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerProductTile extends StatelessWidget {
  const _OwnerProductTile({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final ShopProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: product.hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image(
                image: product.imageProvider,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image_outlined,
                  color: AppColors.danger,
                ),
              ),
            )
          : Icon(
              product.isAvailable
                  ? Icons.inventory_2_outlined
                  : Icons.remove_shopping_cart_outlined,
              color: product.isAvailable ? AppColors.primary : AppColors.danger,
            ),
      title: Text(product.name),
      subtitle: Text(
        '${product.category} · '
        '${product.price > 0 ? formatPeso(product.price) : 'No price'} · '
        '${product.quantity} in stock · '
        '${product.isAvailable ? 'Available' : 'Unavailable'}',
      ),
      onTap: onEdit,
      trailing: PopupMenuButton<_ProductAction>(
        tooltip: 'Product options',
        onSelected: (action) {
          switch (action) {
            case _ProductAction.edit:
              onEdit();
            case _ProductAction.delete:
              onDelete();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _ProductAction.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit product'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _ProductAction.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete product'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ProductAction { edit, delete }

class _ProductDetails {
  const _ProductDetails({
    required this.name,
    required this.category,
    required this.brand,
    required this.condition,
    required this.description,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.motorcycles,
    required this.fitsAll,
    required this.specs,
  });

  final String name;
  final String category;
  final String brand;
  final String condition;
  final String description;
  final double price;
  final int quantity;
  final String imageUrl;
  final List<String> motorcycles;
  final bool fitsAll;
  final List<FitSpec> specs;
}

class _EditProductSheet extends StatefulWidget {
  const _EditProductSheet({required this.product, this.specRows});

  final ShopProduct product;
  final List<ItemSpecRow>? specRows;

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.product.name);
  late final _brandController = TextEditingController(
    text: widget.product.brand,
  );
  late final _descriptionController = TextEditingController(
    text: widget.product.description,
  );
  late final _priceController = TextEditingController(
    text: widget.product.price > 0
        ? widget.product.price.toStringAsFixed(2)
        : '',
  );
  late final _quantityController = TextEditingController(
    text: widget.product.quantity.toString(),
  );
  late final _imageUrlController = TextEditingController(
    text: widget.product.imageUrl,
  );
  late String _category;
  late final List<String> _categories;
  late String? _condition = widget.product.condition.isEmpty
      ? null
      : widget.product.condition;
  List<ItemSpecRow> _rows = const [];
  late MotorcycleFit _fit;

  /// One editable value per motorcycle in the saved specs.
  late final Map<String, TextEditingController> _specValues = {
    for (final spec in widget.product.specs)
      spec.motorcycle: TextEditingController(text: spec.value),
  };

  @override
  void initState() {
    super.initState();
    _category = widget.product.category.trim().isEmpty
        ? shopProductCategories.first
        : widget.product.category;
    _categories = {
      ...shopProductCategories,
      if (_category.isNotEmpty) _category,
    }.toList(growable: false);
    _rows = widget.specRows ?? const [];
    _fit = _fitFor(_rows);
    if (widget.specRows == null) {
      loadItemSpecs().then((rows) {
        if (mounted) {
          setState(() {
            _rows = rows;
            _fit = _fitFor(rows);
          });
        }
      }, onError: (_) {});
    }
  }

  /// Saved motorcycles that are not in the table (from older listings).
  /// They have no checkbox, so they are kept as they are when saving.
  List<String> _unlisted = const [];

  /// Checks the saved motorcycles that are in the table.
  MotorcycleFit _fitFor(List<ItemSpecRow> rows) {
    final listed = {for (final row in rows) row.motorcycle};
    final saved = widget.product.motorcycles;
    _unlisted = saved.where((m) => !listed.contains(m)).toList();
    return MotorcycleFit(
      models: saved.where(listed.contains).toSet(),
      universal: widget.product.fitsAll,
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _nameController,
      _brandController,
      _descriptionController,
      _priceController,
      _quantityController,
      _imageUrlController,
      ..._specValues.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_fit.isValid && _unlisted.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please check at least 1 motorcycle, or choose Universal.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      _ProductDetails(
        name: _nameController.text.trim(),
        category: _category,
        brand: _brandController.text.trim(),
        condition: _condition ?? '',
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        quantity: int.parse(_quantityController.text.trim()),
        imageUrl: _imageUrlController.text.trim(),
        motorcycles: _fit.universal ? const [] : [..._fit.models, ..._unlisted],
        fitsAll: _fit.universal,
        specs: [
          for (final entry in _specValues.entries)
            if (!_fit.universal && _fit.models.contains(entry.key))
              FitSpec(motorcycle: entry.key, value: entry.value.text.trim()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.product.specLabel;
    final product = widget.product;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit ${product.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (product.part.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    '${product.category} › ${product.part}',
                    if (product.isCustomPart) 'Custom',
                  ].join(' · '),
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => _requiredField(value, 'Product name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand',
                  hintText: 'e.g. NGK, Yamaha, Koso',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: [
                  for (final condition in productConditions)
                    ButtonSegment(value: condition, label: Text(condition)),
                ],
                selected: {?_condition},
                onSelectionChanged: (selected) => setState(
                  () => _condition = selected.isEmpty ? null : selected.first,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price (PHP)',
                        prefixText: '₱ ',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final price = double.tryParse(value?.trim() ?? '');
                        if (price == null || !price.isFinite || price <= 0) {
                          return 'Enter a price above zero.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final quantity = int.tryParse(value?.trim() ?? '');
                        if (quantity == null || quantity < 0) {
                          return 'Enter zero or more.';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                (int.tryParse(_quantityController.text.trim()) ?? 1) > 0
                    ? 'This item will be listed as available in your shop.'
                    : 'Quantity 0 shows this item as Out of stock.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'Which motorcycles does this fit?',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              MotorcycleChecklist(
                byBrand: motorcyclesByBrand(_rows),
                value: _fit,
                onChanged: (fit) => setState(() => _fit = fit),
              ),
              if (label.isNotEmpty && !_fit.universal)
                for (final row in _rows)
                  if (_fit.models.contains(row.motorcycle)) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      key: ValueKey('edit-spec-${row.motorcycle}'),
                      controller: _specValues.putIfAbsent(
                        row.motorcycle,
                        TextEditingController.new,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${motorcycleModel(row.motorcycle)} – $label',
                        hintText: 'Not available, please type it in',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Description or information',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _imageUrlController,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Cover photo URL',
                  hintText: 'https://example.com/photo.jpg',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  // Older listings without a photo may stay that way here.
                  if (trimmed.isEmpty) return null;
                  final uri = Uri.tryParse(trimmed);
                  if (uri == null ||
                      uri.host.isEmpty ||
                      (uri.scheme != 'http' && uri.scheme != 'https')) {
                    return 'Enter a valid https image URL.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submit,
                child: const Text('Save product details'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
