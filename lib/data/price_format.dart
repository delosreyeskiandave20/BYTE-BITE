/// Formats a peso amount with thousands separators, for example `₱1,850.00`.
String formatPeso(num amount) {
  final fixed = amount.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  final sign = amount < 0 ? '-' : '';
  return '$sign₱$grouped${fixed.substring(dot)}';
}
