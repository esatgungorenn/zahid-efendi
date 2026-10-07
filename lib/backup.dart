import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'format.dart';
import 'store.dart';

Future<void> exportBackup(BuildContext context) async {
  final store = StoreScope.of(context);
  final dir = await getTemporaryDirectory();
  final name =
      'zahit-efendi-yedek-${fmtDate(DateTime.now()).replaceAll('.', '-')}.json';
  final file = File('${dir.path}/$name');
  await file.writeAsString(store.exportJson());
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'application/json')],
    title: 'Zahit Efendi yedeği',
  ));
}

Future<void> importBackup(BuildContext context) async {
  final store = StoreScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final picked = await FilePicker.pickFile();
  if (picked == null || !context.mounted) return;

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Yedekten geri yükle'),
      content: const Text(
          'Telefondaki tüm denemeler yedekteki denemelerle değiştirilecek. Devam edilsin mi?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Geri yükle')),
      ],
    ),
  );
  if (ok != true) return;

  try {
    await store.importJson(utf8.decode(await picked.readAsBytes()));
    messenger.showSnackBar(const SnackBar(content: Text('Yedek geri yüklendi')));
  } on FormatException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
