import 'accessories_maintenance_catalog.dart';
import 'design_catalog.dart';
import 'item_parts.dart';
import 'item_specs.dart';

/// One part a seller can pick by name in Add Item, with the category it
/// belongs to. An owner's own listings can be passed as [extras] so they are
/// suggested before the catalogs.
class PartSuggestion {
  const PartSuggestion({required this.name, required this.category});

  final String name;
  final String category;

  @override
  bool operator ==(Object other) =>
      other is PartSuggestion &&
      other.name == name &&
      other.category == category;

  @override
  int get hashCode => Object.hash(name, category);
}

/// Every part name the shop can suggest, mapped to one of the eight
/// [itemCategories]. The parts list comes first, then accessories, maintenance
/// and designs; a name that appears in more than one catalog keeps the first
/// category it was found in.
List<PartSuggestion> buildPartSuggestions([
  List<PartSuggestion> extras = const [],
]) {
  final seen = <String>{};
  final suggestions = <PartSuggestion>[];

  void add(String name, String category) {
    final trimmed = name.trim();
    final key = trimmed.toLowerCase();
    if (trimmed.isEmpty || !itemCategories.contains(category)) return;
    if (!seen.add(key)) return;
    suggestions.add(PartSuggestion(name: trimmed, category: category));
  }

  for (final extra in extras) {
    add(extra.name, extra.category);
  }
  for (final entry in partsByCategory.entries) {
    for (final part in entry.value) {
      add(part, entry.key);
    }
  }
  for (final group in accessoryGroups) {
    for (final choice in group.itemChoices.values.expand((c) => c)) {
      add(choice, 'Accessories');
    }
  }
  for (final group in maintenanceGroups) {
    for (final choice in group.itemChoices.values.expand((c) => c)) {
      add(choice, 'Maintenance');
    }
  }
  for (final group in designGroups) {
    for (final item in group.items) {
      add(item, 'Designs');
    }
  }
  return List.unmodifiable(suggestions);
}
