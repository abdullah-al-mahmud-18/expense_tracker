import 'package:flutter/services.dart';

/// Converts any typed or pasted uppercase letters to lowercase.
class LowerCaseTextFormatter extends TextInputFormatter {
  const LowerCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
