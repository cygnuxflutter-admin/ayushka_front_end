import 'dart:typed_data';

import 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart';

/// Cross-platform Print and PDF export helper that avoids MissingPluginException
/// by leveraging native HTML5 Blob/Iframe APIs on Web and Printing package on native platforms.
class PrintHelper {
  static Future<void> printPdf(Uint8List bytes, String filename) =>
      printPdfBytes(bytes, filename);

  static Future<void> downloadPdf(Uint8List bytes, String filename) =>
      downloadPdfBytes(bytes, filename);
}
