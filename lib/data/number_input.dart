import 'package:flutter/services.dart';

/// Shared rules for number fields, so every form blocks letters and other
/// symbols the same way and shows the same error messages.
///
/// Typing or pasting anything that is not allowed is rejected and the field
/// keeps its previous value.
abstract final class NumberInput {
  /// Largest price a seller can enter, in pesos.
  static const maxPrice = 9999999.99;

  /// Largest stock quantity a seller can enter.
  static const maxQuantity = 99999;

  /// Digits only, for counts such as quantity. Up to 5 digits.
  static final wholeNumber = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(5),
  ];

  /// Digits with at most one decimal point and two decimal places, for
  /// prices such as `250` or `1499.50`. Up to 7 digits before the point.
  static final price = <TextInputFormatter>[
    _WholeTextFormatter(RegExp(r'^\d{0,7}(\.\d{0,2})?$')),
  ];

  /// Error for a required price above zero, or null when valid.
  static String? priceError(String? value) {
    const missing = 'Please enter a price above 0.';
    final text = value?.trim() ?? '';
    if (text.isEmpty) return missing;
    final price = double.tryParse(text);
    if (price == null || !price.isFinite) {
      return 'Use numbers only, e.g. 250 or 1499.50.';
    }
    if (price <= 0) return missing;
    if (price > maxPrice) return 'Price is too high.';
    return null;
  }

  /// Error for a required whole number of at least [min], or null when valid.
  static String? wholeNumberError(String? value, {int min = 0}) {
    final missing = 'Please enter a whole number, $min or more.';
    final text = value?.trim() ?? '';
    if (text.isEmpty) return missing;
    final number = int.tryParse(text);
    if (number == null) return 'Use whole numbers only, e.g. 5.';
    if (number < min) return missing;
    if (number > maxQuantity) return 'Please enter $maxQuantity or less.';
    return null;
  }
}

/// Accepts an edit only when the whole new text matches [pattern]; otherwise
/// keeps the previous text, so one wrong key never wipes the field.
class _WholeTextFormatter extends TextInputFormatter {
  _WholeTextFormatter(this.pattern);

  final RegExp pattern;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => pattern.hasMatch(newValue.text) ? newValue : oldValue;
}
