import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';

List<TextInputFormatter> getAmountTextInputFormatters() {
  return <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9]+[,.]{0,1}[0-9]{0,7}')),
    TextInputFormatter.withFunction(
      (oldValue, newValue) => newValue.copyWith(
        text: newValue.text.replaceAll(',', '.'),
      ),
    ),
    TextInputFormatter.withFunction(
      // The max 7 decimal digits in the regex does not seem to work
      (oldValue, newValue) {
        var d = Decimal.tryParse(newValue.text);
        if (d == null) {
          return const TextEditingValue(text: '');
        }
        if (d.scale > 7) {
          return TextEditingValue(text: d.floor(scale: 7).toStringAsFixed(7));
        }
        return newValue;
      },
    ),
  ];
}
