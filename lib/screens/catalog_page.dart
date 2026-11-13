import 'package:flutter/material.dart';

import '../data/accessories_maintenance_catalog.dart';
import '../data/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/buy_options_button.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({
    required this.type,
    this.shopStore,
    this.onOwnerSignIn,
    super.key,
  });

  final String type;
  final ShopStore? shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  late final _shopStore = widget.shopStore ?? ShopStore.shared;
  String? _expandedGroup;

  bool get _isMaintenance => widget.type == 'maintenance';

  List<CatalogGroup> get _groups =>
      _isMaintenance ? maintenanceGroups : accessoryGroups;

  @override
  Widget build(BuildContext context) {
    final title = _isMaintenance ? 'Maintenance' : 'Accessories';
    final count = _isMaintenance
        ? maintenanceChoiceCount
        : accessoryChoiceCount;
    final description = _isMaintenance
        ? 'Browse maintenance supplies and their available choices.'
        : 'Browse accessory groups and their available choices.';

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to home',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            _isMaintenance
                ? 'MOTOSCAN / SERVICE GUIDE'
                : 'MOTOSCAN / ACCESSORY LIBRARY',
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 31,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tealSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  _isMaintenance ? Icons.build : Icons.extension,
                  size: 19,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isMaintenance
                        ? '$maintenanceItemCount maintenance items · $count choices'
                        : '$accessoryItemCount accessory groups · $count choices',
                    style: const TextStyle(
                      color: AppColors.teal,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _isMaintenance
                ? 'Maintenance supplies and choices'
                : 'Browse all groups',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          ..._groups.asMap().entries.map((entry) {
            final index = entry.key;
            final group = entry.value;
            final expanded = _expandedGroup == group.title;
            return _CatalogGroupCard(
              group: group,
              index: index,
              expanded: expanded,
              isMaintenance: _isMaintenance,
              shopStore: _shopStore,
              onOwnerSignIn: widget.onOwnerSignIn,
              onToggle: () => setState(() {
                _expandedGroup = expanded ? null : group.title;
              }),
            );
          }),
          if (!_isMaintenance) ...[
            const SizedBox(height: 14),
            const _CatalogNotice(text: accessoryNotice),
          ],
        ],
      ),
    );
  }
}

class _CatalogGroupCard extends StatelessWidget {
  const _CatalogGroupCard({
    required this.group,
    required this.index,
    required this.expanded,
    required this.isMaintenance,
    required this.shopStore,
    required this.onOwnerSignIn,
    required this.onToggle,
  });

  final CatalogGroup group;
  final int index;
  final bool expanded;
  final bool isMaintenance;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;
  final VoidCallback onToggle;

  static const _itemColors = [
    Color(0xFFFCE7DA),
    AppColors.tealSoft,
    AppColors.warningSoft,
    Color(0xFFE3EAF6),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: expanded ? AppColors.teal : AppColors.line,
          width: expanded ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(11),
              child: Row(
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(group.itemChoices[group.title] ?? group.items).length} choices',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(Icons.expand_more, color: AppColors.teal),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      border: Border(top: BorderSide(color: AppColors.line)),
                    ),
                    child: group.itemChoices.containsKey(group.title)
                        ? _MaintenanceChoiceList(
                            choices: group.itemChoices[group.title]!,
                            shopStore: shopStore,
                            onOwnerSignIn: onOwnerSignIn,
                            details: isMaintenance
                                ? maintenanceChoiceDetailsByGroup[group
                                          .title] ??
                                      const <String, CatalogChoiceDetails>{}
                                : accessoryChoiceDetailsByGroup[group.title] ??
                                      const <String, CatalogChoiceDetails>{},
                          )
                        : Column(
                            children: group.items
                                .asMap()
                                .entries
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _CatalogItemThumbnail(
                                            color:
                                                _itemColors[entry.key %
                                                    _itemColors.length],
                                            icon: Icons.extension,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                width: 19,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 2,
                                                      ),
                                                  child: Text(
                                                    '${entry.key + 1}',
                                                    style: const TextStyle(
                                                      color: AppColors.teal,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  entry.value,
                                                  style: const TextStyle(
                                                    color: AppColors.inkSoft,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 19,
                                            ),
                                            child: Text(
                                              'Browse ${entry.value.toLowerCase()} options, product details, and seller availability.',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 11,
                                                height: 1.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          BuyOptionsButton(
                                            store: shopStore,
                                            productQuery: entry.value,
                                            onOwnerSignIn: onOwnerSignIn,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _CatalogItemThumbnail extends StatelessWidget {
  const _CatalogItemThumbnail({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 112,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Icon(icon, size: 42, color: AppColors.teal)),
    );
  }
}

class _MaintenanceChoiceList extends StatelessWidget {
  const _MaintenanceChoiceList({
    required this.choices,
    required this.details,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final List<String> choices;
  final Map<String, CatalogChoiceDetails> details;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AVAILABLE CHOICES',
          style: TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 7),
        ...choices.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _MaintenanceChoiceCard(
              name: entry.value,
              details: details[entry.value] ?? const CatalogChoiceDetails(),
              shopStore: shopStore,
              onOwnerSignIn: onOwnerSignIn,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaintenanceChoiceCard extends StatelessWidget {
  const _MaintenanceChoiceCard({
    required this.name,
    required this.details,
    required this.shopStore,
    required this.onOwnerSignIn,
  });

  final String name;
  final CatalogChoiceDetails details;
  final ShopStore shopStore;
  final VoidCallback? onOwnerSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('catalog-choice-$name'),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MaintenanceChoiceImage(details: details),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 19,
                      color: AppColors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  details.description?.trim().isNotEmpty == true
                      ? details.description!
                      : '$name option. Check the product specifications '
                            'before buying.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                BuyOptionsButton(
                  store: shopStore,
                  productQuery: name,
                  onOwnerSignIn: onOwnerSignIn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceChoiceImage extends StatelessWidget {
  const _MaintenanceChoiceImage({required this.details});

  final CatalogChoiceDetails details;

  @override
  Widget build(BuildContext context) {
    final imageAsset = details.imageAsset;
    final imageUrl = details.imageUrl;
    if (imageAsset != null && imageAsset.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: Image.asset(
          imageAsset,
          width: 96,
          height: 126,
          cacheWidth: 192,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: Image.network(
          imageUrl,
          width: 96,
          height: 126,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: 96,
      height: 126,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0EFED)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, size: 23, color: AppColors.teal),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'Add an image to this choice',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogNotice extends StatelessWidget {
  const _CatalogNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFA46A1F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
