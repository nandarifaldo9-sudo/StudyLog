import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/catatan_store.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';

/// Layar Daftar: semua catatan dari CatatanStore, dengan pencarian
/// berdasarkan judul atau mata kuliah.
class DaftarCatatanPage extends StatefulWidget {
  const DaftarCatatanPage({super.key});

  @override
  State<DaftarCatatanPage> createState() => _DaftarCatatanPageState();
}

class _DaftarCatatanPageState extends State<DaftarCatatanPage> {
  final _kolomCari = TextEditingController();
  String _kataKunci = '';

  @override
  void dispose() {
    _kolomCari.dispose();
    super.dispose();
  }

  void _hapusKataKunci() {
    _kolomCari.clear();
    setState(() => _kataKunci = '');
  }

  Widget _kolomPencarian() {
    return TextField(
      key: const Key('kolomCari'),
      controller: _kolomCari,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari judul atau mata kuliah',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _kataKunci.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.clear),
                onPressed: _hapusKataKunci,
              ),
        border: const OutlineInputBorder(),
      ),
      onChanged: (nilai) => setState(() => _kataKunci = nilai),
    );
  }

  Widget _pesan(String teks) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(teks, textAlign: TextAlign.center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CatatanStore>();
    final hasil = store.telusuri(_kataKunci);
    final mencari = _kataKunci.trim().isNotEmpty;

    final Widget isi;
    if (store.galat != null) {
      isi = _pesan(store.galat!);
    } else if (store.jumlah == 0) {
      isi = _pesan(
        'Belum ada catatan.\n'
        'Tambahkan dari mata kuliah di beranda.',
      );
    } else if (hasil.isEmpty) {
      isi = _pesan('Tidak ada catatan yang cocok dengan "${_kataKunci.trim()}".');
    } else {
      isi = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: hasil.length,
        itemBuilder: (context, i) {
          final catatan = hasil[i];
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
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Catatan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _kolomPencarian(),
          ),
          if (mencari && hasil.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${hasil.length} catatan ditemukan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          Expanded(child: isi),
        ],
      ),
    );
  }
}