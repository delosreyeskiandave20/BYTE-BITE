import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Inline notice for a failed background load, with an optional retry action.
class LoadErrorBanner extends StatelessWidget {
  const LoadErrorBanner({
    required this.message,
    this.onRetry,
    this.compact = false,
    super.key,
  });

  final String message;
  final VoidCallback? onRetry;

  /// Uses smaller type and tighter padding for dense screens.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: compact
          ? const EdgeInsets.fromLTRB(12, 10, 8, 10)
          : const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(compact ? AppRadius.sm : 14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: AppColors.danger,
            size: compact ? 18 : 19,
          ),
          SizedBox(width: compact ? 8 : 9),
          Expanded(
            child: Text(
              message,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: TextStyle(
                color: AppColors.danger,
                fontSize: compact ? 11 : 12,
                fontWeight: compact ? FontWeight.w600 : null,
                height: compact ? null : 1.35,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
