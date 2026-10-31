import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/catatan_view_model.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';

/// Layar Daftar: menampilkan semua catatan dari CatatanViewModel.
class DaftarCatatanPage extends StatelessWidget {
  final DateTime Function()? now;

  const DaftarCatatanPage({super.key, this.now});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatatanViewModel>();
    final daftar = store.semua;

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Catatan')),
      body: store.galat != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(store.galat!, textAlign: TextAlign.center),
              ),
            )
          : daftar.isEmpty
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
