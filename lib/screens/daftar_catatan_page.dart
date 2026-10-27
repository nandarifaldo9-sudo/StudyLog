import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/catatan_store.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';

/// Layar Daftar: menampilkan semua catatan dari CatatanStore.
class DaftarCatatanPage extends StatelessWidget {
  const DaftarCatatanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final daftar = context.watch<CatatanStore>().semua;

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Catatan')),
      body: daftar.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada catatan.\n'
                  'Tambahkan dari mata kuliah di beranda.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
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
            ),
    );
  }
}