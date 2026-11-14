import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../theme/desain.dart';
import '../theme/warna_mata_kuliah.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';

String _formatSisa(int menit) {
  if (menit < 60) return '$menit menit';
  final jam = menit ~/ 60;
  final sisa = menit % 60;
  return sisa == 0 ? '$jam jam' : '$jam jam $sisa menit';
}

Widget _lingkaran(double ukuran, int alpha) => Container(
  width: ukuran,
  height: ukuran,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: Colors.white.withAlpha(alpha),
  ),
);

class DashboardPage extends StatelessWidget {
  final DateTime sekarang;
  final Set<String> adaDraft;
  final void Function(JadwalKuliah, DateTime) onTambahCatatan;

  /// 0 = Dashboard, 1 = Jadwal, 2 = Catatan.
  final ValueChanged<int> onPindahTab;

  const DashboardPage({
    super.key,
    required this.sekarang,
    required this.adaDraft,
    required this.onTambahCatatan,
    required this.onPindahTab,
  });

  JadwalKuliah? _berlangsung(List<JadwalKuliah> jadwalHariIni) {
    for (final j in jadwalHariIni) {
      if (statusKuliah(j, sekarang) == StatusKuliah.berlangsung) return j;
    }
    return null;
  }

  /// Kuliah berikutnya beserta tanggalnya.
  (JadwalKuliah, DateTime)? _berikutnya(JadwalViewModel jadwalViewModel) {
    for (var i = 0; i < 7; i++) {
      final tanggal = DateTime(sekarang.year, sekarang.month, sekarang.day + i);
      final daftar = jadwalViewModel.jadwalUntukTanggal(tanggal);
      for (final j in daftar) {
        if (i == 0 && statusKuliah(j, sekarang) != StatusKuliah.akanDatang) {
          continue;
        }
        return (j, tanggal);
      }
    }
    final tanggalKhusus = jadwalViewModel.tanggalKelasKhususBerikutnya(
      sekarang,
    );
    if (tanggalKhusus != null) {
      for (final jadwal in jadwalViewModel.jadwalUntukTanggal(tanggalKhusus)) {
        if (hariSama(tanggalKhusus, sekarang) &&
            statusKuliah(jadwal, sekarang) != StatusKuliah.akanDatang) {
          continue;
        }
        return (jadwal, tanggalKhusus);
      }
    }
    return null;
  }

  (JadwalKuliah, DateTime)? _kelasKhususBerikutnya(
    JadwalViewModel jadwalViewModel,
  ) {
    final tanggal = jadwalViewModel.tanggalKelasKhususBerikutnya(sekarang);
    if (tanggal == null) return null;
    for (final jadwal in jadwalViewModel.kelasKhususUntukTanggal(tanggal)) {
      if (hariSama(tanggal, sekarang) &&
          statusKuliah(jadwal, sekarang) != StatusKuliah.akanDatang) {
        continue;
      }
      return (jadwal, tanggal);
    }
    return null;
  }

  Widget _kartuKelasKhusus(
    BuildContext context,
    JadwalViewModel jadwalViewModel,
    JadwalKuliah jadwal,
    DateTime tanggal,
    bool bisaMencatat,
  ) {
    final tema = Theme.of(context);
    return KartuBerbayang(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Lencana(
            teks: 'Kelas khusus berikutnya',
            warna: tema.colorScheme.primary,
            ikon: Icons.event_available,
          ),
          const SizedBox(height: 10),
          Text(
            jadwal.nama,
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatTanggalLengkap(tanggal)} • ${jadwal.jamTeks}',
            style: tema.textTheme.bodySmall?.copyWith(color: Desain.teksRedup),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: jadwalViewModel.sedangMemuat || !bisaMencatat
                  ? null
                  : () => onTambahCatatan(jadwal, tanggal),
              icon: const Icon(Icons.edit_note),
              label: const Text('Tambah catatan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuUtama(
    BuildContext context,
    JadwalViewModel jadwalViewModel,
    List<JadwalKuliah> jadwalHariIni,
    bool bisaMencatat,
  ) {
    final berlangsung = _berlangsung(jadwalHariIni);
    final berikut = _berikutnya(jadwalViewModel);

    final JadwalKuliah j;
    final String label;
    final DateTime tanggal;
    if (berlangsung != null) {
      j = berlangsung;
      label = 'Sedang berlangsung';
      tanggal = sekarang;
    } else if (berikut != null) {
      j = berikut.$1;
      tanggal = berikut.$2;
      final hariIni = hariSama(tanggal, sekarang);
      label = hariIni
          ? 'Berikutnya hari ini'
          : 'Kuliah berikutnya • ${namaHari[tanggal.weekday - 1]}';
    } else {
      return const KartuBerbayang(
        padding: EdgeInsets.all(20),
        child: Text('Belum ada jadwal kuliah.'),
      );
    }

    final warna = warnaUntuk(j.nama);
    final menitSekarang = sekarang.hour * 60 + sekarang.minute;
    final hariIni = hariSama(tanggal, sekarang);
    final sedangBerlangsung = berlangsung != null;
    const putihRedup = TextStyle(color: Colors.white70, fontSize: 13);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [warna, Color.lerp(warna, Colors.black, 0.35)!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(right: -36, top: -36, child: _lingkaran(140, 24)),
            Positioned(right: 48, bottom: -56, child: _lingkaran(112, 16)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Lencana(
                    teks: label,
                    warna: Colors.white,
                    ikon: sedangBerlangsung
                        ? Icons.play_circle_outline
                        : Icons.schedule,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    j.nama,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${j.jamTeks} • ${j.kode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: putihRedup,
                        ),
                      ),
                    ],
                  ),
                  if (sedangBerlangsung) ...[
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: ((menitSekarang - j.mulai) / (j.selesai - j.mulai))
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      minHeight: 6,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sisa ${_formatSisa(j.selesai - menitSekarang)}',
                      style: putihRedup,
                    ),
                  ] else if (hariIni) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Mulai dalam ${_formatSisa(j.mulai - menitSekarang)}',
                      style: putihRedup,
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(formatTanggalLengkap(tanggal), style: putihRedup),
                  ],
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: warna,
                    ),
                    onPressed: jadwalViewModel.sedangMemuat || !bisaMencatat
                        ? null
                        : () => onTambahCatatan(j, tanggal),
                    icon: const Icon(Icons.edit_note),
                    label: Text(
                      hariIni ? 'Catat sekarang' : 'Catat untuk tanggal ini',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();
    final jadwalViewModel = context.watch<JadwalViewModel>();
    final tema = Theme.of(context);
    final bisaMencatat = !vm.sedangMemuat && vm.galat == null;
    final jadwal = jadwalViewModel.jadwalUntukTanggal(sekarang);
    final berikut = _berikutnya(jadwalViewModel);
    final kelasKhusus = _kelasKhususBerikutnya(jadwalViewModel);
    final kelasKhususSudahDiKartuUtama =
        berikut != null &&
        kelasKhusus != null &&
        berikut.$1.kode == kelasKhusus.$1.kode &&
        hariSama(berikut.$2, kelasKhusus.$2);
    final sudahDicatat = jadwal
        .where((j) => vm.adaCatatanHariIni(j.nama, sekarang))
        .length;
    final namaMataKuliah = {
      ...warnaMataKuliah.keys,
      ...jadwalViewModel.semuaMataKuliah,
      ...vm.semua.map((catatan) => catatan.mataKuliah),
    };
    final maks = namaMataKuliah
        .map(vm.jumlahUntuk)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final judul = tema.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, color: tema.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('StudyLog'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            sapaan(sekarang),
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF202638),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Desain.teksRedup,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${formatTanggalLengkap(sekarang)} • ${formatJam(sekarang)}',
                  style: tema.textTheme.bodyMedium?.copyWith(
                    color: Desain.teksRedup,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _kartuUtama(context, jadwalViewModel, jadwal, bisaMencatat),
          if (kelasKhusus != null && !kelasKhususSudahDiKartuUtama) ...[
            const SizedBox(height: 12),
            _kartuKelasKhusus(
              context,
              jadwalViewModel,
              kelasKhusus.$1,
              kelasKhusus.$2,
              bisaMencatat,
            ),
          ],
          if (vm.sedangMemuat)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          if (vm.galat != null) ...[
            const SizedBox(height: 12),
            Card(
              color: tema.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vm.galat!),
                    TextButton(
                      onPressed: vm.sedangMemuat ? null : vm.muat,
                      child: const Text('Coba muat ulang'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _KartuStat(
                  ikon: Icons.sticky_note_2_outlined,
                  nilai: '${vm.jumlah}',
                  label: 'Total catatan',
                  warna: const Color(0xFF3949AB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KartuStat(
                  ikon: Icons.trending_up,
                  nilai: '${vm.jumlahMingguIni(sekarang)}',
                  label: 'Minggu ini',
                  warna: const Color(0xFF00897B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KartuStat(
                  ikon: Icons.school_outlined,
                  nilai: '${jadwal.length}',
                  label: 'Kuliah hari ini',
                  warna: const Color(0xFFEF6C00),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KartuStat(
                  ikon: Icons.drafts_outlined,
                  nilai: '${adaDraft.length}',
                  label: 'Draft',
                  warna: const Color(0xFF8E24AA),
                ),
              ),
            ],
          ),
          if (jadwal.isNotEmpty) ...[
            const SizedBox(height: 12),
            KartuBerbayang(
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: sudahDicatat / jadwal.length,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: tema.colorScheme.primary.withAlpha(
                              30,
                            ),
                          ),
                        ),
                        Text(
                          '$sudahDicatat/${jadwal.length}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan hari ini',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: judul,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sudahDicatat dari ${jadwal.length} mata kuliah',
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: Desain.teksRedup,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          JudulBagian(
            judul: 'Catatan terbaru',
            aksi: 'Lihat semua',
            onAksi: () => onPindahTab(2),
          ),
          if (vm.jumlah == 0)
            const KartuBerbayang(
              child: KeadaanKosong(
                ikon: Icons.sticky_note_2_outlined,
                judul: 'Belum ada catatan',
                deskripsi: 'Catatan yang kamu tulis akan muncul di sini.',
              ),
            )
          else
            for (final c in vm.terbaru(3))
              CatatanCard(
                data: c,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailCatatanPage(catatan: c),
                  ),
                ),
              ),
          const JudulBagian(judul: 'Ringkasan per mata kuliah'),
          KartuBerbayang(
            child: Column(
              children: [
                for (final mk in namaMataKuliah)
                  _BarisRingkasan(
                    nama: mk,
                    jumlah: vm.jumlahUntuk(mk),
                    maks: maks,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuStat extends StatelessWidget {
  final IconData ikon;
  final String nilai;
  final String label;
  final Color warna;

  const _KartuStat({
    required this.ikon,
    required this.nilai,
    required this.label,
    required this.warna,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return KartuBerbayang(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KotakIkon(ikon: ikon, warna: warna, ukuran: 36),
          const SizedBox(height: 12),
          Text(
            nilai,
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tema.textTheme.bodySmall?.copyWith(color: Desain.teksRedup),
          ),
        ],
      ),
    );
  }
}

class _BarisRingkasan extends StatelessWidget {
  final String nama;
  final int jumlah;
  final int maks;

  const _BarisRingkasan({
    required this.nama,
    required this.jumlah,
    required this.maks,
  });

  @override
  Widget build(BuildContext context) {
    final warna = warnaUntuk(nama);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: warna, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '$jumlah',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: maks == 0 ? 0 : jumlah / maks,
            minHeight: 6,
            color: warna,
            backgroundColor: warna.withAlpha(28),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
