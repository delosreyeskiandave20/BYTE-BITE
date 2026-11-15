import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'motoscan_wordmark.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({required this.onSearch, super.key});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppBar(
      titleSpacing: isCompact ? 12 : 20,
      title: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: MotoScanWordmark(size: isCompact ? 21 : 23),
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: isCompact ? 8 : 16),
          child: IconButton(
            tooltip: 'Search parts',
            onPressed: onSearch,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.search),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
