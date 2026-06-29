/// Formats integer pesos as a grouped string, e.g. 1234567 -> "$1.234.567".
/// (Colombian style: dots as thousands separators, no decimals.)
String formatMoney(int pesos) {
  final negative = pesos < 0;
  final digits = pesos.abs().toString();
  final buffer = StringBuffer();

  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }

  return '${negative ? '-' : ''}\$$buffer';
}

/// Parses a user-typed amount ("50.000", "$50000") into whole pesos.
/// Returns null when there are no digits.
int? parseMoney(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}
