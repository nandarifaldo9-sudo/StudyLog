import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../state/catatan_store.dart';
import '../theme/warna_mata_kuliah.dart';
import 'tambah_catatan_page.dart';

/// Layar Detail: isi lengkap catatan, dengan aksi UBAH dan HAPUS.
class DetailCatatanPage extends StatelessWidget {
  /// Catatan saat layar dibuka. Versi terbaru selalu dibaca dari store;
  /// objek ini hanya cadangan saat catatan baru saja dihapus.
  final HasilCatatan catatan;

  const DetailCatatanPage({super.key, required this.catatan});

  Future<void> _ubah(BuildContext context, HasilCatatan c) async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahCatatanPage(
          mataKuliah: c.mataKuliah,
          catatanAwal: c,
        ),
      ),
    );
    if (berhasil == true && context.mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Catatan berhasil diperbarui')),
      );
    }
  }

  Future<void> _hapus(BuildContext context, HasilCatatan c) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Catatan "${c.judul}" akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('BATAL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('HAPUS'),
          ),
        ],
      ),
    );
    if (setuju != true || !context.mounted) return;

    final store = context.read<CatatanStore>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // kembali ke layar sebelumnya (back stack)
    store.hapus(c.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('Catatan dihapus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CatatanStore>().cari(catatan.id) ?? catatan;
    final warna = warnaUntuk(c.mataKuliah);
    final hari = namaHari[c.waktu.weekday - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warna,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.menu_book, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.mataKuliah,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(c.judul, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '$hari, ${formatJam(c.waktu)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(c.isi, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _ubah(context, c),
                    child: const Text('UBAH'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                    ),
                    onPressed: () => _hapus(context, c),
                    child: const Text('HAPUS'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}