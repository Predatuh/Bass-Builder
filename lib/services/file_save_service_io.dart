import 'dart:io';

Future<String> saveBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path;
  final downloadDir = Directory('$home/Downloads');
  if (!downloadDir.existsSync()) {
    downloadDir.createSync(recursive: true);
  }
  final file = File('${downloadDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}