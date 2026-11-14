import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../theme/warna_mata_kuliah.dart';
import 'tambah_catatan_page.dart';

/// Layar detail: isi lengkap catatan dan aksi pengelolaan.
class DetailCatatanPage extends StatelessWidget {
  /// Catatan saat layar dibuka. Versi terbaru selalu dibaca dari store;
  /// objek ini hanya cadangan saat catatan baru saja dihapus.
  final HasilCatatan catatan;

  const DetailCatatanPage({super.key, required this.catatan});

  Future<void> _ubah(BuildContext context, HasilCatatan c) async {
    final hasil = await Navigator.push<HasilSimpanCatatan>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TambahCatatanPage(mataKuliah: c.mataKuliah, catatanAwal: c),
      ),
    );
    if (hasil != null && context.mounted) {
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
        content: const Text('Catatan ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true || !context.mounted) return;

    final store = context.read<CatatanViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await store.hapus(c.id); // hapus baris di SQLite, lalu perbarui daftar
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (context.mounted) navigator.pop(); // kembali ke layar sebelumnya
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<CatatanViewModel>().cari(catatan.id) ?? catatan;
    final warna = warnaUntuk(c.mataKuliah);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Catatan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: warna.withAlpha(24),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined, color: warna),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.mataKuliah,
                      style: TextStyle(
                        color: warna,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              c.judul,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${formatTanggalLengkap(c.waktu)} • ${formatJam(c.waktu)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  c.isi,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(height: 1.55),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _ubah(context, c),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ubah'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _hapus(context, c),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
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
