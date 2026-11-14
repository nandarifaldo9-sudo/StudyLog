import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();
    final jadwalVm = context.watch<JadwalViewModel>();
    final tema = Theme.of(context);
    final hariIni = hariSama(_tanggalDipilih, widget.sekarang);
    final daftar = jadwalVm.jadwalUntukTanggal(_tanggalDipilih);
    final infoLibur = namaHariLibur(_tanggalDipilih);

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
          const SizedBox(height: 16),
          if (jadwalVm.galat != null) ...[
            Card(
              color: tema.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(jadwalVm.galat!),
                    TextButton(
                      onPressed: jadwalVm.sedangMemuat
                          ? null
                          : jadwalVm.muat,
                      child: const Text('Coba muat ulang'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (infoLibur != null &&
              _tanggalDipilih.weekday != DateTime.sunday) ...[
            Card(
              color: tema.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy,
                      color: tema.colorScheme.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        infoLibur,
                        style: TextStyle(
                          color: tema.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '${namaHari[_tanggalDipilih.weekday - 1]} • ${daftar.length} mata kuliah',
            style: tema.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (daftar.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    const Text('Tidak ada jadwal untuk tanggal ini'),
                  ],
                ),
              ),
            )
          else
            for (final j in daftar)
              _KartuJadwal(
                jadwal: j,
                status: hariIni ? statusKuliah(j, widget.sekarang) : null,
                jumlahCatatan: vm.jumlahUntuk(j.nama),
                adaDraft: widget.adaDraft.contains(j.nama),
                onTambah: jadwalVm.sedangMemuat
                        || vm.sedangMemuat
                        || vm.galat != null
                    ? null
                    : () => widget.onTambahCatatan(j, _tanggalDipilih),
              ),
        ],
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

  Widget _chip(String teks, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _chipStatus(StatusKuliah status) {
    switch (status) {
      case StatusKuliah.berlangsung:
        return _chip('Sedang berlangsung', const Color(0xFF2E7D32));
      case StatusKuliah.akanDatang:
        return _chip('Akan datang', const Color(0xFF546E7A));
      case StatusKuliah.selesai:
        return _chip('Selesai', const Color(0xFF9E9E9E));
    }
  }

  Widget _info(IconData ikon, String teks) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 16, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(teks, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final warna = warnaUntuk(jadwal.nama);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: warna),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 16, color: warna),
                            const SizedBox(width: 6),
                            Text(
                              jadwal.jamTeks,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: warna,
                              ),
                            ),
                          ],
                        ),
                        if (status != null) _chipStatus(status!),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      jadwal.nama,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      jadwal.kode,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _info(Icons.edit_note, '$jumlahCatatan catatan'),
                        if (adaDraft) _info(Icons.drafts_outlined, 'Ada draft'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: warna),
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
    );
  }
}
