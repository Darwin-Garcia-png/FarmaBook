import 'dart:io';

void downloadBytes(List<int> bytes, String filename) {
  try {
    final home = Platform.environment['USERPROFILE'] ?? '';
    final dir = Directory('$home\\Downloads');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}\\$filename');
    file.writeAsBytesSync(bytes);
    print('PDF guardado en: ${file.path}');
  } catch (e) {
    print('Error guardando PDF: $e');
  }
}
