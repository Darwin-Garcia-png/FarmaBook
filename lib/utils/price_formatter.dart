String formatCop(num value) {
  final formatted = value.toStringAsFixed(0);
  final parts = formatted.split('.');
  final intPart = parts[0];
  final buffer = StringBuffer();
  int count = 0;
  for (int i = intPart.length - 1; i >= 0; i--) {
    if (count > 0 && count % 3 == 0) buffer.write(',');
    buffer.write(intPart[i]);
    count++;
  }
  return '\$${buffer.toString().split('').reversed.join()}';
}
