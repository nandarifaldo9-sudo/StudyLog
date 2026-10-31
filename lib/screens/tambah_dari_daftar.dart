import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import 'tambah_catatan_page.dart';

/// Alur workbook: Daftar -> Form (tombol +), lalu Form kembali ke Daftar.
Future<void> bukaFormDariDaftar(
  BuildContext context, {
  required String pesanSukses,
  DateTime Function()? now,
}) async {
  final sekarang = (now ?? DateTime.now)();
  final jadwal = jadwalKuliah[sekarang.weekday] ?? const <JadwalKuliah>[];
  final messenger = ScaffoldMessenger.of(context);

  if (jadwal.isEmpty) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Tidak ada kuliah hari ini. Catatan ditambahkan pada hari kuliah.',
        ),
      ),
    );
    return;
  }

  final JadwalKuliah? pilihan = jadwal.length == 1
      ? jadwal.first
      : await showModalBottomSheet<JadwalKuliah>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(title: Text('Pilih mata kuliah')),
                for (final j in jadwal)
                  ListTile(
                    title: Text(j.nama),
                    subtitle: Text(j.jamTeks),
                    onTap: () => Navigator.pop(ctx, j),
                  ),
              ],
            ),
          ),
        );
  if (pilihan == null || !context.mounted) return;

  final tersimpan = await Navigator.push<HasilCatatan>(
    context,
    MaterialPageRoute(
      builder: (_) => TambahCatatanPage(
        mataKuliah: pilihan.nama,
        jam: pilihan.jamTeks,
        now: now,
      ),
    ),
  );
  if (tersimpan != null) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(pesanSukses)));
  }
}