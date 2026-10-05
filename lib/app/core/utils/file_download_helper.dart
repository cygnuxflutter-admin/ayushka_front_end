import 'file_download_helper_stub.dart'
    if (dart.library.html) 'file_download_helper_web.dart';

/// Centralized file download helper across Web, Desktop, and Mobile.
class FileDownloadHelper {
  FileDownloadHelper._();

  /// Prompts a download or saves [bytes] with the given [fileName].
  static Future<void> download({
    required List<int> bytes,
    required String fileName,
    String mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  }) async {
    await downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
    );
  }
}
