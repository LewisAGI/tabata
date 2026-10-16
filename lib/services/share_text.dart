import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

Rect? shareOrigin(BuildContext context) {
  if (!Platform.isIOS) {
    return null;
  }
  final box = context.findRenderObject();
  if (box is RenderBox &&
      box.hasSize &&
      box.size.width > 0 &&
      box.size.height > 0) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return const Rect.fromLTWH(1, 1, 2, 2);
}

Future<void> copyPlainText(String text) {
  return Clipboard.setData(ClipboardData(text: text));
}

Future<void> sharePlainText(
  BuildContext context,
  String text, {
  bool asFile = false,
}) async {
  final origin = shareOrigin(context);
  if (!asFile) {
    await SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: origin),
    );
    return;
  }
  final file = File('${Directory.systemTemp.path}/tabata.txt');
  await file.writeAsString(text);
  await SharePlus.instance.share(
    ShareParams(
      text: text,
      files: [XFile(file.path, mimeType: 'text/plain', name: 'tabata.txt')],
      sharePositionOrigin: origin,
    ),
  );
}
