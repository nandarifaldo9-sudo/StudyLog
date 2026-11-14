import 'package:flutter/material.dart';

import 'tambah_catatan_page.dart' as form;

/// Alur Daftar -> Form; tanggal dan mata kuliah dipilih di form.
Future<void> bukaFormDariDaftar(
  BuildContext context, {
  required String pesanSukses,
  DateTime Function()? now,
}) async {
  final waktuAwal = (now ?? DateTime.now)();
  final messenger = ScaffoldMessenger.of(context);
  final hasil = await Navigator.push<form.HasilSimpanCatatan>(
    context,
    MaterialPageRoute(
      builder: (_) => form.TambahCatatanPage(waktuAwal: waktuAwal, now: now),
    ),
  );
  if (hasil != null && context.mounted) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          hasil == form.HasilSimpanCatatan.berhasilDenganDraftTertinggal
              ? 'Catatan tersimpan, tetapi draft lama belum terhapus'
              : pesanSukses,
        ),
      ),
    );
  }
}
