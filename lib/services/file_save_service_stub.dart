Future<String> saveBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) async {
  throw UnsupportedError('File saving is not supported on this platform.');
}