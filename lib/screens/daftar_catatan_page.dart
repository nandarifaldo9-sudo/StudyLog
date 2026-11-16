import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/desain.dart';
import '../theme/warna_mata_kuliah.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';
import 'tambah_dari_daftar.dart';

/// Layar Daftar: semua catatan dari CatatanViewModel, dengan pencarian,
/// filter per mata kuliah, dan pengurutan.
class DaftarCatatanPage extends StatefulWidget {
  /// [now] dipakai pengujian agar hari/jam bisa diatur.
  final DateTime Function()? now;

  const DaftarCatatanPage({super.key, this.now});

  @override
  State<DaftarCatatanPage> createState() => _DaftarCatatanPageState();
}

class _DaftarCatatanPageState extends State<DaftarCatatanPage> {
  final _kolomCari = TextEditingController();
  String _kataKunci = '';
  UrutanCatatan _urutan = UrutanCatatan.terbaru;

  /// null = semua mata kuliah.
  String? _mataKuliah;

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
      ),
      onChanged: (nilai) => setState(() => _kataKunci = nilai),
    );
  }

  Widget _pesan(String teks) =>
      KeadaanKosong(ikon: Icons.sticky_note_2_outlined, judul: teks);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();
    final jadwalViewModel = context.watch<JadwalViewModel>();
    final hasil = vm.telusuri(
      _kataKunci,
      urutan: _urutan,
      mataKuliah: _mataKuliah,
    );
    final mencari = _kataKunci.trim().isNotEmpty;
    final adaFilter = mencari || _mataKuliah != null;

    final Widget isi;
    if (vm.sedangMemuat) {
      isi = const Center(child: CircularProgressIndicator());
    } else if (vm.galat != null) {
      isi = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.galat!, textAlign: TextAlign.center),
              TextButton(onPressed: vm.muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    } else if (vm.jumlah == 0) {
      isi = _pesan('Belum ada catatan.');
    } else if (hasil.isEmpty) {
      isi = _pesan(
        mencari
            ? 'Tidak ada catatan yang cocok dengan "${_kataKunci.trim()}".'
            : 'Belum ada catatan untuk $_mataKuliah.',
      );
    } else {
      isi = ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
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
      appBar: AppBar(
        title: const Text('Semua Catatan'),
        actions: [
          PopupMenuButton<UrutanCatatan>(
            key: const Key('menuUrutan'),
            tooltip: 'Urutkan',
            icon: const Icon(Icons.sort),
            initialValue: _urutan,
            onSelected: (nilai) => setState(() => _urutan = nilai),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: UrutanCatatan.terbaru,
                child: Text('Terbaru dulu'),
              ),
              PopupMenuItem(
                value: UrutanCatatan.terlama,
                child: Text('Terlama dulu'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _kolomPencarian(),
          ),
          if (adaFilter && hasil.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vm.sedangMemuat || vm.galat != null
            ? null
            : () => bukaFormDariDaftar(
                context,
                now: widget.now,
                pesanSukses: 'Catatan berhasil disimpan',
              ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
