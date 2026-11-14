import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../theme/desain.dart';
import '../theme/warna_mata_kuliah.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/pemilih_tanggal.dart';
import 'kelola_jadwal_page.dart';

class JadwalPage extends StatefulWidget {
  final DateTime sekarang;
  final Set<String> adaDraft;
  final void Function(JadwalKuliah, DateTime) onTambahCatatan;

  const JadwalPage({
    super.key,
    required this.sekarang,
    required this.adaDraft,
    required this.onTambahCatatan,
  });

  @override
  State<JadwalPage> createState() => _JadwalPageState();
}

class _JadwalPageState extends State<JadwalPage> {
  late DateTime _tanggalDipilih = widget.sekarang;

  @override
  void didUpdateWidget(covariant JadwalPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!hariSama(oldWidget.sekarang, widget.sekarang) &&
        hariSama(_tanggalDipilih, oldWidget.sekarang)) {
      _tanggalDipilih = DateTime(
        widget.sekarang.year,
        widget.sekarang.month,
        widget.sekarang.day,
      );
    }
  }

  Future<void> _pilihTanggal() async {
    final tanggal = await pilihTanggalAkademik(
      context: context,
      tanggalAwal: _tanggalDipilih,
      sekarang: widget.sekarang,
    );
    if (tanggal == null || !mounted) return;
    setState(() => _tanggalDipilih = tanggal);
  }

  Future<void> _kelolaJadwal() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => KelolaJadwalPage(
          tanggalAwal: _tanggalDipilih,
          sekarang: widget.sekarang,
        ),
      ),
    );
  }

  void _geserTanggal(int hari) {
    setState(() {
      _tanggalDipilih = DateTime(
        _tanggalDipilih.year,
        _tanggalDipilih.month,
        _tanggalDipilih.day + hari,
      );
    });
  }

  /// Strip 7 hari (Senin-Minggu) pada minggu tanggal yang dipilih.
  Widget _stripMinggu(JadwalViewModel jadwalVm) {
    final senin = DateTime(
      _tanggalDipilih.year,
      _tanggalDipilih.month,
      _tanggalDipilih.day - (_tanggalDipilih.weekday - 1),
    );
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _HariStrip(
                tanggal: DateTime(senin.year, senin.month, senin.day + i),
                dipilih: hariSama(
                  DateTime(senin.year, senin.month, senin.day + i),
                  _tanggalDipilih,
                ),
                hariIni: hariSama(
                  DateTime(senin.year, senin.month, senin.day + i),
                  widget.sekarang,
                ),
                tanggalMerah:
                    namaTanggalMerah(
                      DateTime(senin.year, senin.month, senin.day + i),
                    ) !=
                    null,
                liburAkademik:
                    namaHariLibur(
                      DateTime(senin.year, senin.month, senin.day + i),
                    ) !=
                    null,
                adaJadwal: jadwalVm
                    .jadwalUntukTanggal(
                      DateTime(senin.year, senin.month, senin.day + i),
                    )
                    .isNotEmpty,
                onTap: () => setState(
                  () => _tanggalDipilih = DateTime(
                    senin.year,
                    senin.month,
                    senin.day + i,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();
    final jadwalVm = context.watch<JadwalViewModel>();
    final tema = Theme.of(context);
    final hariIni = hariSama(_tanggalDipilih, widget.sekarang);
    final daftar = jadwalVm.jadwalUntukTanggal(_tanggalDipilih);
    final infoLibur = namaHariLibur(_tanggalDipilih);
    final infoTanggalMerah = _tanggalDipilih.weekday == DateTime.sunday
        ? null
        : namaTanggalMerah(_tanggalDipilih);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah'),
        actions: [
          IconButton(
            key: const Key('kelolaJadwal'),
            tooltip: 'Kelola jadwal kuliah',
            onPressed: jadwalVm.sedangMemuat ? null : _kelolaJadwal,
            icon: const Icon(Icons.edit_calendar_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Hari sebelumnya',
                onPressed: () => _geserTanggal(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('pilihTanggalJadwal'),
                  onPressed: _pilihTanggal,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    formatTanggalPendek(_tanggalDipilih),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Hari berikutnya',
                onPressed: () => _geserTanggal(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stripMinggu(jadwalVm),
          if (jadwalVm.galat != null) ...[
            const SizedBox(height: 12),
            Card(
              color: tema.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwalVm.galat!),
                    TextButton(
                      onPressed: jadwalVm.sedangMemuat ? null : jadwalVm.muat,
                      child: const Text('Coba muat ulang'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (infoTanggalMerah != null && infoLibur == null) ...[
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: tema.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, color: tema.colorScheme.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tanggal merah: $infoTanggalMerah · '
                      'jadwal mingguan tetap berlaku',
                      style: TextStyle(
                        color: tema.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          JudulBagian(
            judul:
                '${namaHari[_tanggalDipilih.weekday - 1]} • ${daftar.length} mata kuliah',
          ),
          if (daftar.isEmpty)
            const KartuBerbayang(
              child: KeadaanKosong(
                ikon: Icons.event_busy_outlined,
                judul: 'Tidak ada jadwal untuk tanggal ini',
              ),
            )
          else
            for (final j in daftar)
              _KartuJadwal(
                jadwal: j,
                status: hariIni ? statusKuliah(j, widget.sekarang) : null,
                jumlahCatatan: vm.jumlahUntuk(j.nama),
                adaDraft: widget.adaDraft.contains(j.nama),
                onTambah:
                    jadwalVm.sedangMemuat || vm.sedangMemuat || vm.galat != null
                    ? null
                    : () => widget.onTambahCatatan(j, _tanggalDipilih),
              ),
        ],
      ),
    );
  }
}

class _HariStrip extends StatelessWidget {
  final DateTime tanggal;
  final bool dipilih;
  final bool hariIni;
  final bool tanggalMerah;
  final bool liburAkademik;
  final bool adaJadwal;
  final VoidCallback onTap;

  const _HariStrip({
    required this.tanggal,
    required this.dipilih,
    required this.hariIni,
    required this.tanggalMerah,
    required this.liburAkademik,
    required this.adaJadwal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    final warnaAngka = dipilih
        ? Colors.white
        : tanggalMerah
        ? const Color(0xFFC62828)
        : liburAkademik
        ? Colors.orange.shade900
        : skema.onSurface;

    return Material(
      color: dipilih ? skema.primary : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: dipilih || hariIni
              ? skema.primary
              : tanggalMerah
              ? const Color(0xFFC62828)
              : liburAkademik
              ? Colors.orange.shade800
              : Desain.garis,
          width: hariIni && !dipilih ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                namaHari[tanggal.weekday - 1].substring(0, 3),
                style: TextStyle(
                  fontSize: 11,
                  color: dipilih ? Colors.white70 : Desain.teksRedup,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${tanggal.day}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: warnaAngka,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: adaJadwal
                      ? (dipilih ? Colors.white : skema.primary)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuJadwal extends StatelessWidget {
  final JadwalKuliah jadwal;
  final StatusKuliah? status;
  final int jumlahCatatan;
  final bool adaDraft;
  final VoidCallback? onTambah;

  const _KartuJadwal({
    required this.jadwal,
    required this.status,
    required this.jumlahCatatan,
    required this.adaDraft,
    required this.onTambah,
  });

  Widget _lencanaStatus(StatusKuliah status) {
    switch (status) {
      case StatusKuliah.berlangsung:
        return const Lencana(
          teks: 'Sedang berlangsung',
          warna: Color(0xFF2E7D32),
          ikon: Icons.play_circle_outline,
        );
      case StatusKuliah.akanDatang:
        return const Lencana(teks: 'Akan datang', warna: Color(0xFF546E7A));
      case StatusKuliah.selesai:
        return const Lencana(teks: 'Selesai', warna: Color(0xFF8A8F99));
    }
  }

  Widget _info(IconData ikon, String teks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 16, color: Desain.teksRedup),
        const SizedBox(width: 4),
        Text(
          teks,
          style: const TextStyle(fontSize: 13, color: Desain.teksRedup),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final warna = warnaUntuk(jadwal.nama);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 14),
                Text(
                  formatMenit(jadwal.mulai),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formatMenit(jadwal.selesai),
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: Desain.teksRedup,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: KartuBerbayang(
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
                            Text(
                              jadwal.nama,
                              style: tema.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              jadwal.kode,
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: Desain.teksRedup,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (status != null) _lencanaStatus(status!),
                                _info(
                                  Icons.edit_note,
                                  '$jumlahCatatan catatan',
                                ),
                                if (adaDraft)
                                  _info(Icons.drafts_outlined, 'Ada draft'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: warna,
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: onTambah,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah catatan'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
