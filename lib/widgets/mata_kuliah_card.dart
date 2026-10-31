import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import '../theme/warna_mata_kuliah.dart';

/// Kartu mata kuliah di dashboard; warnanya khas per mata kuliah.
class MataKuliahCard extends StatelessWidget {
  final JadwalKuliah jadwal;
  final StatusKuliah status;
  final int jumlahCatatan;
  final bool adaDraft;
  final VoidCallback onTambah;

  const MataKuliahCard({
    super.key,
    required this.jadwal,
    required this.status,
    required this.jumlahCatatan,
    required this.adaDraft,
    required this.onTambah,
  });

  Widget _chip(String teks, Color warna, {Color teksWarna = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(teks, style: TextStyle(fontSize: 12, color: teksWarna)),
    );
  }

  Widget _chipStatus() {
    switch (status) {
      case StatusKuliah.berlangsung:
        return _chip('Sedang berlangsung', const Color(0xFF2E7D32));
      case StatusKuliah.akanDatang:
        return _chip('Akan datang', const Color(0xFF546E7A));
      case StatusKuliah.selesai:
        return _chip('Selesai', const Color(0xFF9E9E9E));
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = warnaUntuk(jadwal.nama);
    return Card(
      color: Color.alphaBlend(warna.withAlpha(40), Colors.white),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warna, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              jadwal.nama,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold, color: warna),
            ),
            const SizedBox(height: 4),
            Text('${jadwal.kode} • ${jadwal.jamTeks}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _chipStatus(),
                Text('$jumlahCatatan catatan'),
                if (adaDraft)
                  _chip(
                    'Ada draft',
                    const Color(0xFFFFE082),
                    teksWarna: Colors.black87,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: warna),
                onPressed: onTambah,
                child: const Text('TAMBAH CATATAN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
