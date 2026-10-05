import 'dart:typed_data';
import 'package:printing/printing.dart';

Future<void> printPdfBytes(Uint8List bytes, String filename) async {
  await Printing.layoutPdf(
    onLayout: (_) async => bytes,
    name: filename,
  );
}

Future<void> downloadPdfBytes(Uint8List bytes, String filename) async {
  await Printing.sharePdf(
    bytes: bytes,
    filename: filename,
  );
}
