import 'package:flutter/services.dart';

/// Master spec table used to prefill the shop's Add Item form.
///
/// The rows live in [itemSpecsAssetPath] (one row per motorcycle) so the
/// values can be corrected without touching the UI. A shop owner's edits are
/// saved on their own item and never change this table.
const itemSpecsAssetPath = 'assets/data/item_specs.csv';

/// Text shown for a value the master table marks as unknown ("—").
const itemSpecUnknownHint = 'Not available, please type it in';

/// The categories offered by Add Item, always in this order.
const itemCategories = <String>[
  'Engine',
  'Electrical',
  'Suspension',
  'Wheels and Tires',
  'Body Parts',
  'Accessories',
  'Maintenance',
  'Designs',
];

/// One column of the master table.
enum ItemSpecField {
  frontTire('Front tire'),
  rearTire('Rear tire'),
  battery('Battery'),
  sparkPlug('Spark plug'),
  engineOil('Engine oil'),
  chainSprockets('Chain & sprockets'),
  fuelTank('Fuel tank'),
  tirePressure('Tire pressure (psi)');

  const ItemSpecField(this.column);

  /// Header of this column in the CSV file.
  final String column;
}

/// A table value split into the value itself and any note such as
/// "(sources differ)", which the form shows as an info hint.
class ItemSpecValue {
  const ItemSpecValue(this.value, {this.note});

  final String value;
  final String? note;

  /// Parses one CSV cell. "—" (or an empty cell) is unknown and returns null;
  /// nothing is ever guessed.
  static ItemSpecValue? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == '—' || text == '-') return null;
    final note = RegExp(r'\s*\(([^()]*)\)\s*$').firstMatch(text);
    // Keep model-name style parentheses inside values; only a trailing note
    // made of words is split off.
    if (note != null && note.group(1)!.contains(RegExp(r'[a-z]{3,}'))) {
      final value = text.substring(0, note.start).trim();
      if (value.isNotEmpty) {
        return ItemSpecValue(value, note: note.group(1)!.trim());
      }
    }
    return ItemSpecValue(text);
  }
}

/// One motorcycle row of the master table.
class ItemSpecRow {
  const ItemSpecRow({required this.motorcycle, required this.values});

  final String motorcycle;
  final Map<ItemSpecField, ItemSpecValue> values;

  ItemSpecValue? valueOf(ItemSpecField field) => values[field];

  /// "Belt (CVT) no chain" marks a scooter, which has a drive belt instead
  /// of a chain and sprockets.
  bool get isScooter =>
      values[ItemSpecField.chainSprockets]?.value.toLowerCase().startsWith(
        'belt',
      ) ??
      false;
}

/// Parses the master CSV. Cells never contain commas, so a plain split is
/// enough; rows with the wrong column count are skipped.
List<ItemSpecRow> parseItemSpecs(String csv) {
  final lines = csv
      .split(RegExp(r'\r?\n'))
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) return const [];
  final header = lines.first.split(',').map((cell) => cell.trim()).toList();
  final columns = <ItemSpecField, int>{
    for (final field in ItemSpecField.values)
      if (header.contains(field.column)) field: header.indexOf(field.column),
  };
  final rows = <ItemSpecRow>[];
  for (final line in lines.skip(1)) {
    final cells = line.split(',');
    if (cells.length != header.length) continue;
    final name = cells.first.trim();
    if (name.isEmpty) continue;
    rows.add(
      ItemSpecRow(
        motorcycle: name,
        values: {
          for (final entry in columns.entries)
            entry.key: ?ItemSpecValue.parse(cells[entry.value]),
        },
      ),
    );
  }
  return List.unmodifiable(rows);
}

Future<List<ItemSpecRow>> loadItemSpecs([AssetBundle? bundle]) async {
  final csv = await (bundle ?? rootBundle).loadString(itemSpecsAssetPath);
  return parseItemSpecs(csv);
}
