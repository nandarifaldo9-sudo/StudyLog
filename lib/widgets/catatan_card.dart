import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../theme/warna_mata_kuliah.dart';

/// Card hasil; warnanya mengikuti mata kuliah. Bisa diketuk untuk membuka detail.
class CatatanCard extends StatelessWidget {
  final HasilCatatan data;
  final VoidCallback? onTap;

  const CatatanCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final warna = warnaUntuk(data.mataKuliah);
    final hari = namaHari[data.waktu.weekday - 1];

    return Card(
      color: Color.alphaBlend(warna.withAlpha(40), Colors.white),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: warna, width: 1.5),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: warna,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.mataKuliah,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(data.judul, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(data.isi, maxLines: 3, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                '$hari, ${formatJam(data.waktu)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
