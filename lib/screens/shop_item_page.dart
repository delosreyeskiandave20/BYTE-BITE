import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/item_parts.dart';
import '../data/price_format.dart';
import '../models/shop.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_item_card.dart';

/// Turns a shop's contact into a link: a PH mobile number becomes an SMS
/// link, and web or Messenger addresses open in the browser/app.
Uri? sellerContactUri(String contact) {
  final text = contact.trim();
  if (text.isEmpty) return null;
  final digits = text.replaceAll(RegExp(r'[\s\-()]'), '');
  if (RegExp(r'^\+?\d{7,15}$').hasMatch(digits)) {
    return Uri(scheme: 'sms', path: digits);
  }
  final withScheme = text.startsWith(RegExp('https?://'))
      ? text
      : 'https://$text';
  final uri = Uri.tryParse(withScheme);
  return uri == null || uri.host.isEmpty || !uri.host.contains('.')
      ? null
      : uri;
}

/// Opens a link outside the app. Swappable for tests.
typedef LinkOpener = Future<bool> Function(Uri uri);

Future<bool> _openExternally(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Buyer view of one shop item.
class ShopItemPage extends StatefulWidget {
  const ShopItemPage({
    required this.shop,
    required this.product,
    this.myMotorcycle,
    this.openLink,
    super.key,
  });

  final Shop shop;
  final ShopProduct product;
  final String? myMotorcycle;
  final LinkOpener? openLink;

  @override
  State<ShopItemPage> createState() => _ShopItemPageState();
}

class _ShopItemPageState extends State<ShopItemPage> {
  int _photo = 0;

  Future<void> _messageSeller(Uri uri) async {
    final opened = await (widget.openLink ?? _openExternally)(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the seller contact.')),
      );
    }
  }

  void _zoom(List<ImageProvider> gallery, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => _ZoomGallery(
          title: widget.product.name,
          gallery: gallery,
          initial: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shop = widget.shop;
    final gallery = product.gallery;
    final contact = sellerContactUri(shop.contact);
    final mine = widget.myMotorcycle;
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: Text(product.name, maxLines: 1)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: gallery.isEmpty
                ? const PhotoUnavailable()
                : Stack(
                    children: [
                      PageView.builder(
                        key: const ValueKey('item-gallery'),
                        itemCount: gallery.length,
                        onPageChanged: (page) => setState(() => _photo = page),
                        itemBuilder: (context, index) => GestureDetector(
                          onTap: () => _zoom(gallery, index),
                          child: Image(
                            image: gallery[index],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const PhotoUnavailable(),
                          ),
                        ),
                      ),
                      if (gallery.length > 1)
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_photo + 1} / ${gallery.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: AppType.section,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.price > 0
                      ? formatPeso(product.price)
                      : 'Price not set',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.isAvailable
                      ? '${product.quantity} in stock'
                      : 'Out of stock',
                  style: TextStyle(
                    color: product.isAvailable
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (mine != null && product.fits(mine)) ...[
                  const SizedBox(height: 8),
                  FitsYourBadge(motorcycle: mine),
                ],
                const SizedBox(height: 14),
                _InfoRow(
                  'Category',
                  product.part.isEmpty
                      ? product.category
                      : '${product.category} › ${product.part}',
                ),
                if (product.condition.isNotEmpty)
                  _InfoRow('Condition', product.condition),
                if (product.brand.isNotEmpty) _InfoRow('Brand', product.brand),
                const SizedBox(height: 18),
                const Text(
                  '✅ Fits these motorcycles:',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (product.fitsAll)
                  const Text('All motorcycles (universal)')
                else if (product.motorcycles.isEmpty)
                  const Text(
                    'Not listed. Ask the seller.',
                    style: TextStyle(color: AppColors.muted),
                  )
                else
                  for (final motorcycle in product.motorcycles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text('• $motorcycle'),
                    ),
                if (product.specs.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    product.specLabel.isEmpty
                        ? 'Specs'
                        : '${product.specLabel} per motorcycle',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final spec in product.specs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${motorcycleModel(spec.motorcycle)} – '
                        '${product.specLabel}: ${spec.value}',
                      ),
                    ),
                ],
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Description',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.description,
                    style: const TextStyle(
                      color: AppColors.inkSoft,
                      height: 1.45,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (shop.location.isNotEmpty)
                                  Text(
                                    shop.location,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: AppType.caption,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('message-seller'),
                        onPressed: contact == null
                            ? null
                            : () => _messageSeller(contact),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Message seller'),
                      ),
                      if (contact == null) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'This seller has not added a way to message them yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: AppType.caption,
                          ),
                        ),
                      ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen gallery: swipe between photos, pinch or double-tap to zoom.
class _ZoomGallery extends StatefulWidget {
  const _ZoomGallery({
    required this.title,
    required this.gallery,
    required this.initial,
  });

  final String title;
  final List<ImageProvider> gallery;
  final int initial;

  @override
  State<_ZoomGallery> createState() => _ZoomGalleryState();
}

class _ZoomGalleryState extends State<_ZoomGallery> {
  late final _pages = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.gallery.length,
        itemBuilder: (context, index) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: Image(
              key: ValueKey('zoomed-item-photo-$index'),
              image: widget.gallery[index],
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const PhotoUnavailable(),
            ),
          ),
        ),
      ),
    );
  }
}
