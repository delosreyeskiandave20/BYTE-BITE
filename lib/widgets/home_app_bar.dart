import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({required this.onSearch, super.key});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;

    return AppBar(
      titleSpacing: isCompact ? 12 : 20,
      title: Row(
        children: [
          Container(
            width: isCompact ? 34 : 36,
            height: isCompact ? 34 : 36,
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.two_wheeler, color: Colors.white, size: 20),
          ),
          SizedBox(width: isCompact ? 7 : 9),
          Flexible(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: isCompact ? 21 : 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                children: const [
                  TextSpan(text: 'Moto'),
                  TextSpan(
                    text: 'Scan',
                    style: TextStyle(color: AppColors.teal),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
