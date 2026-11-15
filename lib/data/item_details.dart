import 'item_specs.dart';

/// Parts that need a few extra questions so buyers can find the exact size,
/// capacity or code. Parts without a kind are listed with no extra questions.
enum DetailKind { tire, battery, sparkPlug, engineOil, chain, sprocket }

/// The part kind a product name refers to, or null when the item has no
/// size/capacity questions.
///
/// Matching is deliberately narrow: "Tire pressure gauge" is a tool, not a
/// tire, and "Battery charger" is not a battery.
DetailKind? detailKindFor(String name) {
  final words = name
      .toLowerCase()
      .replaceAll('-', ' ')
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.isNotEmpty)
      .toSet();
  bool has(String word) => words.contains(word);

  if ((has('tire') || has('tyre') || has('tires') || has('tyres')) &&
      !has('gauge') &&
      !has('pressure')) {
    return DetailKind.tire;
  }
  if (has('battery') &&
      !has('charger') &&
      !has('tester') &&
      !has('terminal') &&
      !has('tender')) {
    return DetailKind.battery;
  }
  if (has('spark') && (has('plug') || has('plugs')) && !has('cap')) {
    return DetailKind.sparkPlug;
  }
  if (has('engine') && has('oil') && !has('filter')) {
    return DetailKind.engineOil;
  }
  if (has('sprocket') || has('sprockets')) return DetailKind.sprocket;
  if (has('chain') &&
      !has('lube') &&
      !has('lubricant') &&
      !has('lock') &&
      !has('cleaner')) {
    return DetailKind.chain;
  }
  return null;
}

/// One answer a seller can tap. [usedOn] names the motorcycles in the master
/// table that use this value, shown as a hint ("used on …").
class DetailOption {
  const DetailOption(this.value, {this.usedOn = const []});

  final String value;
  final List<String> usedOn;
}

/// One question shown under the product name once a [DetailKind] is known.
class DetailQuestion {
  const DetailQuestion({
    required this.id,
    required this.label,
    required this.options,
    this.saveLabel,
  });

  /// Stable id used for widget keys and keeping answers while the form
  /// rebuilds, e.g. "position" or "batteryType".
  final String id;

  /// The question as the seller reads it, e.g. "Front or rear?".
  final String label;

  /// The heading saved with the answer, e.g. "Position". Defaults to [label].
  final String? saveLabel;

  final List<DetailOption> options;

  String get detailLabel => saveLabel ?? label;
}

/// The questions for [kind], in the order they should be answered. Questions
/// that depend on a previous answer only appear once that answer exists.
List<DetailQuestion> detailQuestionsFor(
  DetailKind kind,
  List<ItemSpecRow> rows,
  Map<String, String> answers,
) {
  return switch (kind) {
    DetailKind.tire => _tireQuestions(rows, answers),
    DetailKind.battery => _batteryQuestions(rows, answers),
    DetailKind.sprocket => _sprocketQuestions(rows, answers),
    DetailKind.chain => _chainQuestions(rows),
    DetailKind.sparkPlug || DetailKind.engineOil => const [],
  };
}

// ------------------------------------------------------------------- tires

List<DetailQuestion> _tireQuestions(
  List<ItemSpecRow> rows,
  Map<String, String> answers,
) {
  final position = answers['position'];
  return [
    const DetailQuestion(
      id: 'position',
      label: 'Front or rear?',
      saveLabel: 'Position',
      options: [
        DetailOption('Front'),
        DetailOption('Rear'),
        DetailOption('Front & rear set'),
      ],
    ),
    if (position != null)
      DetailQuestion(
        id: 'size',
        label: 'Tire size',
        options: _sizeOptions(rows, switch (position) {
          'Front' => const [ItemSpecField.frontTire],
          'Rear' => const [ItemSpecField.rearTire],
          _ => const [ItemSpecField.frontTire, ItemSpecField.rearTire],
        }),
      ),
    if (position != null)
      const DetailQuestion(
        id: 'tireType',
        label: 'Tire type',
        options: [DetailOption('Tubeless'), DetailOption('Tube type')],
      ),
  ];
}

List<DetailOption> _sizeOptions(
  List<ItemSpecRow> rows,
  List<ItemSpecField> fields,
) {
  final usedOn = <String, List<String>>{};
  for (final row in rows) {
    for (final field in fields) {
      final value = row.valueOf(field)?.value;
      if (value == null || value.trim().isEmpty) continue;
      final models = usedOn.putIfAbsent(value, () => []);
      if (!models.contains(row.motorcycle)) models.add(row.motorcycle);
    }
  }
  final sizes = usedOn.keys.toList()..sort();
  return [
    for (final size in sizes)
      DetailOption(size, usedOn: List.unmodifiable(usedOn[size]!)),
  ];
}

// ---------------------------------------------------------------- batteries

const _batteryTypes = [
  DetailOption('Maintenance-free (MF)'),
  DetailOption('Conventional (wet)'),
];

List<DetailQuestion> _batteryQuestions(
  List<ItemSpecRow> rows,
  Map<String, String> answers,
) {
  final volts = answers['volts'];
  return [
    const DetailQuestion(
      id: 'volts',
      label: 'What volts?',
      saveLabel: 'Volts',
      options: [DetailOption('12V'), DetailOption('6V')],
    ),
    if (volts != null)
      DetailQuestion(
        id: 'capacity',
        label: 'What capacity (Ah)?',
        saveLabel: 'Capacity (Ah)',
        options: _batteryCapacities(rows, volts),
      ),
    if (volts != null)
      DetailQuestion(
        id: 'model',
        label: 'Which battery model / code?',
        saveLabel: 'Battery model / code',
        options: _batteryModels(rows, volts),
      ),
    if (volts != null)
      const DetailQuestion(
        id: 'batteryType',
        label: 'Battery type',
        options: _batteryTypes,
      ),
  ];
}

/// Cells look like "12V 5Ah" or "YTZ6V / YTZ7V"; cells without a capacity are
/// skipped instead of guessed.
List<DetailOption> _batteryCapacities(List<ItemSpecRow> rows, String volts) {
  final capacities = <String>{};
  for (final row in rows) {
    final cell = row.valueOf(ItemSpecField.battery)?.value;
    if (cell == null) continue;
    final compact = cell.toLowerCase().replaceAll(' ', '');
    if (!compact.startsWith(volts.toLowerCase())) continue;
    final match = RegExp(r'(\d+(?:\.\d+)?)\s*ah')
        .firstMatch(cell.toLowerCase());
    if (match != null) capacities.add('${match.group(1)}Ah');
  }
  final values = capacities.toList()
    ..sort((a, b) => _leadingNumber(a).compareTo(_leadingNumber(b)));
  return [for (final value in values) DetailOption(value)];
}

/// Model codes start with letters (YTZ6V, GTZ5S); a "12V 5Ah" cell has none.
List<DetailOption> _batteryModels(List<ItemSpecRow> rows, String volts) {
  if (volts.toLowerCase() != '12v') return const [];
  final models = <String>[];
  for (final row in rows) {
    final cell = row.valueOf(ItemSpecField.battery)?.value;
    if (cell == null) continue;
    for (final part in cell.split(RegExp(r'[/,]'))) {
      final candidate = part.trim();
      if (RegExp(r'^[A-Za-z]{2,}[0-9][A-Za-z0-9-]*$').hasMatch(candidate) &&
          !models.contains(candidate)) {
        models.add(candidate);
      }
    }
  }
  return [for (final model in models) DetailOption(model)];
}

// ------------------------------------------------------------------- chains

List<DetailQuestion> _chainQuestions(List<ItemSpecRow> rows) {
  final sizes = <String>{};
  final links = <int>{};
  for (final row in rows) {
    final cell = row.valueOf(ItemSpecField.chainSprockets)?.value;
    if (cell == null || cell.toLowerCase().contains('belt')) continue;
    for (final match in RegExp(r'\b(\d{3})\s*chain\b').allMatches(cell)) {
      sizes.add(match.group(1)!);
    }
    final linkMatch = RegExp(r'(\d+)\s*links?\b').firstMatch(cell);
    if (linkMatch != null) links.add(int.parse(linkMatch.group(1)!));
  }
  return [
    DetailQuestion(
      id: 'chainSize',
      label: 'Chain size',
      saveLabel: 'Chain size',
      options: [for (final size in sizes.toList()..sort()) DetailOption(size)],
    ),
    DetailQuestion(
      id: 'links',
      label: 'Number of links',
      saveLabel: 'Number of links',
      options: [
        for (final count in links.toList()..sort())
          DetailOption('$count links'),
      ],
    ),
  ];
}

// ---------------------------------------------------------------- sprockets

List<DetailQuestion> _sprocketQuestions(
  List<ItemSpecRow> rows,
  Map<String, String> answers,
) {
  final position = answers['position'];
  return [
    const DetailQuestion(
      id: 'position',
      label: 'Front or rear?',
      saveLabel: 'Position',
      options: [DetailOption('Front'), DetailOption('Rear')],
    ),
    if (position != null)
      DetailQuestion(
        id: 'teeth',
        label: 'How many teeth?',
        saveLabel: 'Teeth',
        options: _teethOptions(rows, position),
      ),
  ];
}

List<DetailOption> _teethOptions(List<ItemSpecRow> rows, String position) {
  final front = <int>{};
  final rear = <int>{};
  for (final row in rows) {
    final cell = row.valueOf(ItemSpecField.chainSprockets)?.value;
    if (cell == null) continue;
    final text = cell.toLowerCase();
    if (text.contains('belt')) continue;
    for (final match in RegExp(
      r'(\d+)\s*t\s*(front|rear)\b',
    ).allMatches(text)) {
      final teeth = int.parse(match.group(1)!);
      (match.group(2) == 'front' ? front : rear).add(teeth);
    }
    for (final match in RegExp(
      r'\b(front|rear)\b[^/]*?(\d+)\s*t\b',
    ).allMatches(text)) {
      final teeth = int.parse(match.group(2)!);
      (match.group(1) == 'front' ? front : rear).add(teeth);
    }
  }
  final values = (position == 'Front' ? front : rear).toList()..sort();
  return [for (final teeth in values) DetailOption('${teeth}T')];
}

double _leadingNumber(String text) {
  final match = RegExp(r'^\d+(?:\.\d+)?').firstMatch(text);
  return match == null ? 0 : double.parse(match.group(0)!);
}
