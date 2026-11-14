import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../theme/warna_mata_kuliah.dart';

/// Kartu catatan: garis warna di kiri mengikuti mata kuliah.
class CatatanCard extends StatelessWidget {
  final HasilCatatan data;
  final VoidCallback? onTap;

  const CatatanCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final warna = warnaUntuk(data.mataKuliah);
    final hari = namaHari[data.waktu.weekday - 1];
    final tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: warna),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: warna.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.mataKuliah,
                          style: TextStyle(
                            color: warna,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.judul,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.isi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$hari, ${formatTanggalPendek(data.waktu)} • ${formatJam(data.waktu)}',
                            style: tema.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
