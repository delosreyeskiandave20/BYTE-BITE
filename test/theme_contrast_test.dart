import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/theme/app_theme.dart';

double _contrast(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  const surfaces = <String, Color>{
    'paper': AppColors.paper,
    'surface': AppColors.surface,
    'surfaceMuted': AppColors.surfaceMuted,
  };

  test('body and secondary text meet WCAG AA on every surface', () {
    for (final entry in surfaces.entries) {
      expect(
        _contrast(AppColors.ink, entry.value),
        greaterThanOrEqualTo(7),
        reason: 'ink on ${entry.key}',
      );
      expect(
        _contrast(AppColors.inkSoft, entry.value),
        greaterThanOrEqualTo(4.5),
        reason: 'inkSoft on ${entry.key}',
      );
      expect(
        _contrast(AppColors.muted, entry.value),
        greaterThanOrEqualTo(4.5),
        reason: 'muted on ${entry.key}',
      );
    }
  });

  test('primary button labels are readable', () {
    expect(_contrast(Colors.white, AppColors.teal), greaterThanOrEqualTo(4.5));
  });

  test('status colours meet AA on their soft backgrounds', () {
    expect(
      _contrast(AppColors.success, AppColors.successSoft),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColors.warning, AppColors.warningSoft),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(AppColors.danger, AppColors.dangerSoft),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('decorative colours are documented as below AA', () {
    // Guardrail: faint and orange must never be used for text.
    expect(_contrast(AppColors.faint, AppColors.paper), lessThan(4.5));
    expect(_contrast(AppColors.orange, AppColors.paper), lessThan(3));
  });
}
