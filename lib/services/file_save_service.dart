import 'file_save_service_stub.dart'
    if (dart.library.io) 'file_save_service_io.dart'
    if (dart.library.html) 'file_save_service_web.dart' as impl;

Future<String> saveBytes({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
}) {
  return impl.saveBytes(fileName: fileName, bytes: bytes, mimeType: mimeType);
}