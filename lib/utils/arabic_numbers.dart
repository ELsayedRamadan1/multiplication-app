String toArabicDigits(String input) {
  const western = '0123456789';
  const arabic = '٠١٢٣٤٥٦٧٨٩';
  final buf = StringBuffer();
  for (final ch in input.split('')) {
    final i = western.indexOf(ch);
    buf.write(i >= 0 ? arabic[i] : ch);
  }
  return buf.toString();
}

String formatNumber(dynamic v) {
  if (v == null) return '';
  if (v is num) {
    if (v % 1 == 0) return toArabicDigits(v.toInt().toString());
    return toArabicDigits(v.toString());
  }
  return toArabicDigits(v.toString());
}
