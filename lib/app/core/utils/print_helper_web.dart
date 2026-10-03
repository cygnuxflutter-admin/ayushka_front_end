// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> printPdfBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    final iframe = html.IFrameElement()
      ..style.position = 'fixed'
      ..style.right = '0'
      ..style.bottom = '0'
      ..style.width = '0'
      ..style.height = '0'
      ..style.border = 'none'
      ..src = url;

    html.document.body?.children.add(iframe);

    iframe.onLoad.listen((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          final dynamic win = iframe.contentWindow;
          if (win != null) {
            win.focus();
            win.print();
          } else {
            html.window.open(url, '_blank');
          }
        } catch (_) {
          html.window.open(url, '_blank');
        }
      });
    });

    Future.delayed(const Duration(minutes: 2), () {
      iframe.remove();
      html.Url.revokeObjectUrl(url);
    });
  } catch (_) {
    html.window.open(url, '_blank');
  }
}

Future<void> downloadPdfBytes(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  Future.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}
