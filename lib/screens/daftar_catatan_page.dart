import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/catatan_store.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';
import 'tambah_dari_daftar.dart';

/// Layar Daftar. Alur workbook M2: Daftar -> Detail, Daftar -> Form (+).
class DaftarCatatanPage extends StatelessWidget {
  /// [now] dipakai pengujian agar hari/jam bisa diatur.
  final DateTime Function()? now;

  const DaftarCatatanPage({super.key, this.now});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Catatan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Consumer<CatatanStore>(
            builder: (context, store, _) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Total ${store.jumlah} catatan'),
            ),
          ),
        ),
      ),
      body: Consumer<CatatanStore>(
        builder: (context, store, _) {
          final daftar = store.semua;
          if (daftar.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada catatan. Tambahkan melalui tombol +.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: daftar.length,
              itemBuilder: (context, i) {
                final catatan = daftar[i];
                return CatatanCard(
                  data: catatan,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailCatatanPage(catatan: catatan),
                    ),
                  ),
                );
              },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah catatan',
        onPressed: () => bukaFormDariDaftar(
          context,
          now: now,
          pesanSukses: 'Catatan disimpan sementara (belum permanen).',
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}