// Lists the photo file name every Design ideas item, Maintenance choice and
// Accessories choice
// expects, and which are still missing.
//
// Run from the project root:
//   dart run tool/list_missing_images.dart              (everything)
//   dart run tool/list_missing_images.dart design
//   dart run tool/list_missing_images.dart maintenance
//   dart run tool/list_missing_images.dart accessories
import 'dart:io';

import 'package:flutter_application_1/data/accessories_maintenance_catalog.dart';
import 'package:flutter_application_1/data/design_catalog.dart';
import 'package:flutter_application_1/data/image_slug.dart';

void main(List<String> args) {
  final only = args.isEmpty ? null : args.first.toLowerCase();

  if (only == null || only == 'design') {
    _report(
      title: 'DESIGN IDEAS',
      folder: 'assets/design',
      groups: {
        for (final group in designGroups)
          group.title: {
            for (final item in group.items) item: designImageSlug(item),
          },
      },
    );
  }
  if (only == null || only == 'maintenance') {
    _report(
      title: 'MAINTENANCE',
      folder: 'assets/maintenance',
      groups: {
        for (final group in maintenanceGroups)
          group.title: {
            for (final choice in group.itemChoices.values.expand((c) => c))
              choice: maintenanceImageSlug(group.title, choice),
          },
      },
    );
  }
  if (only == null || only == 'accessories') {
    _report(
      title: 'ACCESSORIES',
      folder: 'assets/accessories',
      groups: {
        for (final group in accessoryGroups)
          group.title: {
            for (final choice in group.itemChoices.values.expand((c) => c))
              choice: accessoryImageSlug(group.title, choice),
          },
      },
    );
  }
}

void _report({
  required String title,
  required String folder,
  required Map<String, Map<String, String>> groups,
}) {
  final dir = Directory(folder);
  final existing = dir.existsSync()
      ? dir
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .where((name) => !name.startsWith('.') && name.contains('.'))
            .map((name) => name.substring(0, name.lastIndexOf('.')))
            .toSet()
      : <String>{};

  stdout.writeln('\n===== $title  ($folder/) =====');
  var total = 0;
  var missing = 0;
  for (final group in groups.entries) {
    stdout.writeln('\n${group.key}');
    for (final entry in group.value.entries) {
      total++;
      final has = existing.contains(entry.value);
      if (!has) missing++;
      stdout.writeln(
        has
            ? '  [x] ${entry.value}   (${entry.key})'
            : '  [ ] ${entry.value}.jpg   (${entry.key})',
      );
    }
  }

  final known = groups.values.expand((slugs) => slugs.values).toSet();
  final unmatched = existing.difference(known);
  stdout.writeln('\n$missing of $total still need a photo.');
  if (unmatched.isNotEmpty) {
    stdout.writeln(
      'These files match no item, so they are not shown (check spelling): '
      '${unmatched.join(', ')}',
    );
  }
}
