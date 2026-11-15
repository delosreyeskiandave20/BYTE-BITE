import 'package:flutter/material.dart';

import '../data/item_parts.dart';
import '../theme/app_theme.dart';

/// What the seller checked in "Which motorcycles does this fit?".
class MotorcycleFit {
  const MotorcycleFit({this.models = const {}, this.universal = false});

  final Set<String> models;

  /// "Universal / Fits all motorcycles"; model boxes are ignored when set.
  final bool universal;

  /// The checked models, or none when Universal is set.
  List<String> get motorcycles => [if (!universal) ...models];

  bool get isValid => universal || motorcycles.isNotEmpty;

  MotorcycleFit copyWith({Set<String>? models, bool? universal}) =>
      MotorcycleFit(
        models: models ?? this.models,
        universal: universal ?? this.universal,
      );
}

/// Checklist of every motorcycle in the master table, grouped by brand, with
/// "Universal" at the top.
class MotorcycleChecklist extends StatefulWidget {
  const MotorcycleChecklist({
    required this.byBrand,
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  /// From [motorcyclesByBrand].
  final Map<String, List<String>> byBrand;
  final MotorcycleFit value;
  final ValueChanged<MotorcycleFit> onChanged;
  final String? errorText;

  @override
  State<MotorcycleChecklist> createState() => _MotorcycleChecklistState();
}

class _MotorcycleChecklistState extends State<MotorcycleChecklist> {
  final _search = TextEditingController();
  String _query = '';

  /// The model list starts hidden; tapping the search opens it.
  bool _open = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setOpen(bool open) {
    if (!open) {
      FocusScope.of(context).unfocus();
      _search.clear();
      _query = '';
    }
    setState(() => _open = open);
  }

  void _toggle(String model, bool checked) {
    final models = {...widget.value.models};
    checked ? models.add(model) : models.remove(model);
    widget.onChanged(widget.value.copyWith(models: models));
  }

  void _toggleBrand(List<String> brandModels, bool checked) {
    final models = {...widget.value.models};
    checked ? models.addAll(brandModels) : models.removeAll(brandModels);
    widget.onChanged(widget.value.copyWith(models: models));
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final enabled = !value.universal;
    final needle = _query.trim().toLowerCase();
    final count = value.universal ? 0 : value.motorcycles.length;
    final error = widget.errorText;
    // Tapping (or starting a scroll) anywhere outside the checklist closes the
    // model list, so the long list never gets in the way of the rest of the
    // form.
    return TapRegion(
      onTapOutside: (_) {
        if (_open) _setOpen(false);
      },
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: error == null ? AppColors.line : AppColors.danger,
            width: error == null ? 1 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  key: const ValueKey('fit-search'),
                  controller: _search,
                  decoration: const InputDecoration(
                    hintText: 'Search motorcycle…',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onTap: () => _setOpen(true),
                  onChanged: (text) => setState(() {
                    _query = text;
                    _open = true;
                  }),
                ),
              ),
              const SizedBox(height: 6),
              CheckboxListTile(
                key: const ValueKey('fit-universal'),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                value: value.universal,
                title: const Text(
                  'Universal / Fits all motorcycles',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                onChanged: (checked) {
                  // Universal disables every model, so the list is closed.
                  if (checked ?? false) _setOpen(false);
                  widget.onChanged(value.copyWith(universal: checked ?? false));
                },
              ),
              const Divider(height: 8),
              // Collapsed: show what is checked so far.
              if (!_open && !value.universal && value.models.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final model in value.models)
                        InputChip(
                          key: ValueKey('fit-chip-$model'),
                          label: Text(model),
                          visualDensity: VisualDensity.compact,
                          onDeleted: () => _toggle(model, false),
                        ),
                    ],
                  ),
                ),
              if (_open)
                for (final brand in widget.byBrand.entries)
                  if (brand.value.any(
                    (model) => model.toLowerCase().contains(needle),
                  )) ...[
                    CheckboxListTile(
                      key: ValueKey('fit-brand-${brand.key}'),
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                      enabled: enabled,
                      tristate: true,
                      value: brand.value.every(value.models.contains)
                          ? true
                          : brand.value.any(value.models.contains)
                          ? null
                          : false,
                      title: Text(
                        'Select all ${brand.key}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      onChanged: (_) => _toggleBrand(
                        brand.value,
                        !brand.value.every(value.models.contains),
                      ),
                    ),
                    for (final model in brand.value)
                      if (model.toLowerCase().contains(needle))
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: CheckboxListTile(
                            key: ValueKey('fit-model-$model'),
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            controlAffinity: ListTileControlAffinity.leading,
                            enabled: enabled,
                            value: value.models.contains(model),
                            title: Text(model),
                            onChanged: (checked) =>
                                _toggle(model, checked ?? false),
                          ),
                        ),
                  ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value.universal
                            ? 'Fits all motorcycles'
                            : '$count motorcycle${count == 1 ? '' : 's'} '
                                  'selected',
                        key: const ValueKey('fit-counter'),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('fit-toggle'),
                      onPressed: () => _setOpen(!_open),
                      icon: Icon(_open ? Icons.expand_less : Icons.expand_more),
                      label: Text(_open ? 'Hide list' : 'Show all motorcycles'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
