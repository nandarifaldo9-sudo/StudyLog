import 'package:flutter/material.dart';

/// Token desain bersama agar semua layar tampil konsisten.
class Desain {
  Desain._();

  static const Color garis = Color(0xFFE5E8F0);
  static const Color teksRedup = Color(0xFF6B7385);
  static const double radius = 18;

  /// Bayangan sangat halus untuk kartu.
  static List<BoxShadow> get bayangan => [
    BoxShadow(
      color: const Color(0xFF1B2A55).withAlpha(14),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Kartu putih dengan border tipis dan bayangan halus.
class KartuBerbayang extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const KartuBerbayang({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final bentuk = BorderRadius.circular(Desain.radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: bentuk,
        border: Border.all(color: Desain.garis),
        boxShadow: Desain.bayangan,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: bentuk,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Judul bagian: garis aksen + judul + tombol aksi opsional.
class JudulBagian extends StatelessWidget {
  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;

  const JudulBagian({super.key, required this.judul, this.aksi, this.onAksi});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: aksi == null ? 22 : 12, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: tema.colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              judul,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tema.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (aksi != null) TextButton(onPressed: onAksi, child: Text(aksi!)),
        ],
      ),
    );
  }
}

/// Ikon di dalam kotak bersudut membulat dengan warna lembut.
class KotakIkon extends StatelessWidget {
  final IconData ikon;
  final Color warna;
  final double ukuran;

  const KotakIkon({
    super.key,
    required this.ikon,
    required this.warna,
    this.ukuran = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: warna.withAlpha(28),
        borderRadius: BorderRadius.circular(ukuran * 0.32),
      ),
      child: Icon(ikon, color: warna, size: ukuran * 0.52),
    );
  }
}

/// Label kecil berbentuk pil (status, nama mata kuliah, dsb).
class Lencana extends StatelessWidget {
  final String teks;
  final Color warna;
  final IconData? ikon;
  final bool terisi;

  const Lencana({
    super.key,
    required this.teks,
    required this.warna,
    this.ikon,
    this.terisi = false,
  });

  @override
  Widget build(BuildContext context) {
    final warnaTeks = terisi ? Colors.white : warna;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: terisi ? warna : warna.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[
            Icon(ikon, size: 14, color: warnaTeks),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              teks,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: warnaTeks,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tampilan kosong: ikon bulat + judul + deskripsi opsional.
class KeadaanKosong extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String? deskripsi;

  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    this.deskripsi,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KotakIkon(ikon: ikon, warna: tema.colorScheme.primary, ukuran: 60),
            const SizedBox(height: 14),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: tema.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (deskripsi != null) ...[
              const SizedBox(height: 4),
              Text(
                deskripsi!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall?.copyWith(
                  color: Desain.teksRedup,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
