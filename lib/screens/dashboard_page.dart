import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../theme/warna_mata_kuliah.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/catatan_card.dart';
import 'detail_catatan_page.dart';

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
  ) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kelas khusus berikutnya',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(jadwal.nama, style: Theme.of(context).textTheme.titleMedium),
          Text(
            '${formatTanggalLengkap(tanggal)} • ${jadwal.jamTeks}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: jadwalViewModel.sedangMemuat
                  || !bisaMencatat
                  ? null
                  : () => onTambahCatatan(jadwal, tanggal),
              icon: const Icon(Icons.edit_note),
              label: const Text('Tambah catatan'),
            ),
          ),
        ],
      ),
    ),
  );

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
      final hariIni =
          tanggal.year == sekarang.year &&
          tanggal.month == sekarang.month &&
          tanggal.day == sekarang.day;
      label = hariIni
          ? 'Berikutnya hari ini'
          : 'Kuliah berikutnya • ${namaHari[tanggal.weekday - 1]}';
    } else {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Belum ada jadwal kuliah.'),
        ),
      );
    }

    final warna = warnaUntuk(j.nama);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warna, Color.lerp(warna, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            j.nama,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${j.jamTeks} • ${j.kode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: warna,
            ),
            onPressed: jadwalViewModel.sedangMemuat
                || !bisaMencatat
                ? null
                : () => onTambahCatatan(j, tanggal),
            icon: const Icon(Icons.edit_note),
            label: Text(
              tanggal.year == sekarang.year &&
                      tanggal.month == sekarang.month &&
                      tanggal.day == sekarang.day
                  ? 'Catat sekarang'
                  : 'Catat untuk tanggal ini',
            ),
          ),
        ],
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
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('StudyLog')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            sapaan(sekarang),
            style: tema.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatTanggalLengkap(sekarang)} • ${formatJam(sekarang)}',
            style: tema.textTheme.bodyMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
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
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Catatan hari ini',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: judul,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$sudahDicatat/${jadwal.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: sudahDicatat / jadwal.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$sudahDicatat dari ${jadwal.length} mata kuliah',
                      style: tema.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Catatan terbaru',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: judul,
                ),
              ),
              TextButton(
                onPressed: () => onPindahTab(2),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          if (vm.jumlah == 0)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.sticky_note_2_outlined,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text('Belum ada catatan'),
                  ],
                ),
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
          const SizedBox(height: 8),
          Text('Ringkasan per mata kuliah', style: judul),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: warna.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ikon, color: warna, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nilai,
                    style: tema.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nama,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '$jumlah',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: maks == 0 ? 0 : jumlah / maks,
            minHeight: 6,
            color: warna,
            backgroundColor: warna.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
