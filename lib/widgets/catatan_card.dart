import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../theme/desain.dart';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: KartuBerbayang(
        onTap: onTap,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: warna),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Lencana(teks: data.mataKuliah, warna: warna),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.judul,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.isi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: Desain.teksRedup,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: Desain.teksRedup,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$hari, ${formatTanggalPendek(data.waktu)} • ${formatJam(data.waktu)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: Desain.teksRedup,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Desain.teksRedup,
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
