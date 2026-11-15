import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/number_input.dart';

/// Runs [typed] through [formatters] the way a text field does, starting
/// from [before].
String _type(
  List<TextInputFormatter> formatters,
  String typed, {
  String before = '',
}) {
  final oldValue = TextEditingValue(
    text: before,
    selection: TextSelection.collapsed(offset: before.length),
  );
  var value = TextEditingValue(
    text: typed,
    selection: TextSelection.collapsed(offset: typed.length),
  );
  for (final formatter in formatters) {
    value = formatter.formatEditUpdate(oldValue, value);
  }
  return value.text;
}

void main() {
  group('whole number fields', () {
    test('accept digits only', () {
      expect(_type(NumberInput.wholeNumber, '25'), '25');
      expect(_type(NumberInput.wholeNumber, 'abc'), '');
      expect(_type(NumberInput.wholeNumber, '1a2b3'), '123');
      expect(_type(NumberInput.wholeNumber, '-5'), '5');
      expect(_type(NumberInput.wholeNumber, '2.5'), '25');
      expect(_type(NumberInput.wholeNumber, '1234567'), '12345');
    });

    test('explain what is wrong', () {
      expect(NumberInput.wholeNumberError('5', min: 1), isNull);
      expect(NumberInput.wholeNumberError('0', min: 0), isNull);
      expect(
        NumberInput.wholeNumberError('', min: 1),
        'Please enter a whole number, 1 or more.',
      );
      expect(
        NumberInput.wholeNumberError('0', min: 1),
        'Please enter a whole number, 1 or more.',
      );
      expect(
        NumberInput.wholeNumberError('five', min: 1),
        'Use whole numbers only, e.g. 5.',
      );
    });
  });

  group('price fields', () {
    test('accept digits and one decimal point with 2 decimals', () {
      expect(_type(NumberInput.price, '250'), '250');
      expect(_type(NumberInput.price, '1499.50'), '1499.50');
      expect(_type(NumberInput.price, '12.'), '12.');
      // Rejected edits keep the previous value.
      expect(_type(NumberInput.price, '12a', before: '12'), '12');
      expect(_type(NumberInput.price, '1.2.3', before: '1.2'), '1.2');
      expect(_type(NumberInput.price, '9.999', before: '9.99'), '9.99');
      expect(_type(NumberInput.price, '₱250'), '');
      expect(_type(NumberInput.price, '-1'), '');
    });

    test('explain what is wrong', () {
      expect(NumberInput.priceError('250'), isNull);
      expect(NumberInput.priceError('0.50'), isNull);
      expect(NumberInput.priceError(''), 'Please enter a price above 0.');
      expect(NumberInput.priceError('0'), 'Please enter a price above 0.');
      expect(
        NumberInput.priceError('abc'),
        'Use numbers only, e.g. 250 or 1499.50.',
      );
      expect(NumberInput.priceError('99999999'), 'Price is too high.');
    });
  });

  testWidgets('a field using the rules ignores typed letters', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: NumberInput.wholeNumber,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'abc12');
    expect(controller.text, '12');
  });
}
