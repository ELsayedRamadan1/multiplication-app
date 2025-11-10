// Utility for formatting numbers with Arabic-Indic digits
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

String toArabicDigits(Object? input) {
  if (input == null) return '';
  final s = input.toString();
  const western = ['0','1','2','3','4','5','6','7','8','9'];
  const arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    final idx = western.indexOf(ch);
    if (idx >= 0) buffer.write(arabic[idx]);
    else buffer.write(ch);
  }
  return buffer.toString();
}

// Convert Arabic-Indic digits (٠-٩) and related separators back to western digits (0-9, dot)
String fromArabicDigits(String input) {
  final arabic = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
  final western = ['0','1','2','3','4','5','6','7','8','9'];
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    final idx = arabic.indexOf(ch);
    if (idx >= 0) buffer.write(western[idx]);
    else if (ch == '٫' || ch == '،' || ch == ',') buffer.write('.'); // Arabic decimal comma or comma -> dot
    else if (ch == '٬') {
      // Arabic thousands separator — remove
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}


// InputFormatter that transforms typed western digits into Arabic-Indic digits for display.
class ArabicDigitsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final transformed = toArabicDigits(newValue.text);
    // Preserve selection offset; mapping is one-to-one so offset remains valid.
    int offset = newValue.selection.extentOffset;
    if (offset > transformed.length) offset = transformed.length;
    return TextEditingValue(
      text: transformed,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }
}
