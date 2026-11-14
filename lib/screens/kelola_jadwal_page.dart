import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/dialog_pindah_kelas.dart';
import '../widgets/editor_jadwal_dialog.dart';
import '../widgets/pemilih_tanggal.dart';

class KelolaJadwalPage extends StatefulWidget {
  final DateTime tanggalAwal;
  final DateTime? sekarang;

  const KelolaJadwalPage({super.key, required this.tanggalAwal, this.sekarang});

  @override
  State<KelolaJadwalPage> createState() => _KelolaJadwalPageState();
}

class _KelolaJadwalPageState extends State<KelolaJadwalPage> {
  late DateTime _tanggal = DateTime(
    widget.tanggalAwal.year,
    widget.tanggalAwal.month,
    widget.tanggalAwal.day,
  );

  String _pesanGalat(Object error) {
    if (error is ArgumentError) return '${error.message}';
    if (error is StateError) return error.message;
    if (error is FormatException) return error.message;
    return '$error';
  }

  void _tampilkanGalat(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Perubahan jadwal gagal: ${_pesanGalat(error)}'),
        ),
      );
  }

  /// Menjalankan perubahan jadwal, lalu menampilkan hasilnya.
  Future<void> _jalankan(
    Future<void> Function() aksi,
    String pesanSukses,
  ) async {
    try {
      await aksi();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pesanSukses)));
    } on ArgumentError catch (error) {
      _tampilkanGalat(error);
    } on StateError catch (error) {
      _tampilkanGalat(error);
    } on Exception catch (error) {
      _tampilkanGalat(error);
    }
  }

  Future<bool?> _konfirmasiHapus({
    required String judul,
    required String pesan,
  }) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(judul),
      content: Text(pesan),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );

  Future<void> _hapusMingguan(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final hari = _tanggal.weekday;
    final konfirmasi = await _konfirmasiHapus(
      judul: 'Hapus mata kuliah mingguan?',
      pesan: '${jadwal.nama} akan dihapus dari jadwal setiap minggu.',
    );
    if (konfirmasi != true || !mounted) return;
    await _jalankan(
      () => vm.hapusMataKuliah(hari, jadwal.kode),
      'Mata kuliah mingguan dihapus',
    );
  }

  Future<void> _pindahkanSekali(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final asal = _tanggal;
    final hasil = await bukaDialogPindahKelas(
      context,
      jadwal: jadwal,
      tanggalAsal: asal,
      sekarang: widget.sekarang,
    );
    if (hasil == null || !mounted) return;
    await _jalankan(
      () => vm.pindahkanKelasSekali(
        dariTanggal: asal,
        kode: jadwal.kode,
        keTanggal: hasil.tanggal,
        mulai: hasil.mulai,
        selesai: hasil.selesai,
      ),
      'Pertemuan dipindah',
    );
  }

  Future<void> _batalkanSekali(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    await _jalankan(
      () => vm.batalkanKelasSekali(tanggal: _tanggal, kode: jadwal.kode),
      'Pertemuan tanggal ini dibatalkan',
    );
  }

  Future<void> _kembalikan(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    await _jalankan(
      () => vm.kembalikanKelas(tanggal: _tanggal, kode: jadwal.kode),
      'Pertemuan dikembalikan ke jadwal semula',
    );
  }

  Future<void> _pilihTanggal() async {
    final tanggal = await pilihTanggalAkademik(
      context: context,
      tanggalAwal: _tanggal,
      sekarang: widget.sekarang,
    );
    if (tanggal == null || !mounted) return;
    setState(
      () => _tanggal = DateTime(tanggal.year, tanggal.month, tanggal.day),
    );
  }

  Future<void> _tambahMingguan() async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final hasil = await bukaEditorJadwal(context, hariAwal: _tanggal.weekday);
    if (hasil == null || !mounted) return;
    await _jalankan(
      () => vm.simpanMataKuliah(hariBaru: hasil.hari, jadwal: hasil.jadwal),
      'Mata kuliah ditambahkan',
    );
  }

  Future<void> _hapusUntukTanggal(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final tanggal = _tanggal;
    final konfirmasi = await _konfirmasiHapus(
      judul: 'Hapus kelas pada tanggal ini?',
      pesan:
          '${jadwal.nama} hanya akan dihapus dari ${formatTanggalPendek(tanggal)}.',
    );
    if (konfirmasi != true || !mounted) return;
    await _jalankan(
      () => vm.hapusKelasPadaTanggal(tanggal, jadwal.kode),
      'Kelas tanggal tertentu dihapus',
    );
  }

  Widget _judulBagian({
    required IconData ikon,
    required String judul,
    required int jumlah,
  }) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Row(
      children: [
        Icon(ikon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            judul,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('$jumlah'),
        ),
      ],
    ),
  );

  Widget _kartuKosong({
    required IconData ikon,
    required String judul,
    required String deskripsi,
  }) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(ikon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  deskripsi,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _kartuMingguan(JadwalKuliah jadwal) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const Icon(Icons.repeat),
      title: Text(jadwal.nama),
      subtitle: Text('${jadwal.kode} • ${jadwal.jamTeks}'),
      trailing: PopupMenuButton<String>(
        key: Key('menuMingguan_${jadwal.kode}'),
        tooltip: 'Aksi mata kuliah',
        onSelected: (aksi) {
          switch (aksi) {
            case 'pindah':
              _pindahkanSekali(jadwal);
            case 'batal':
              _batalkanSekali(jadwal);
            default:
              _hapusMingguan(jadwal);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'pindah',
            child: Text('Pindahkan hanya tanggal ini'),
          ),
          PopupMenuItem(
            value: 'batal',
            child: Text('Batalkan hanya tanggal ini'),
          ),
          PopupMenuItem(value: 'hapus', child: Text('Hapus mingguan')),
        ],
      ),
    ),
  );

  String _keteranganKecuali(JadwalViewModel vm, PengecualianKelas p) {
    final tujuan = p.keTanggal;
    if (tujuan == null) return 'Dibatalkan hanya pada tanggal ini';
    final tanggal = DateTime.parse(tujuan);
    final jam = vm
        .kelasKhususUntukTanggal(tanggal)
        .where((j) => j.kode == p.kode)
        .map((j) => j.jamTeks)
        .firstOrNull;
    return 'Dipindah ke ${namaHari[tanggal.weekday - 1]}, '
        '${formatTanggalPendek(tanggal)}${jam == null ? '' : ' • $jam'}';
  }

  Widget _kartuDikecualikan(
    JadwalViewModel vm,
    JadwalKuliah jadwal,
    PengecualianKelas pengecualian,
  ) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(
        pengecualian.keTanggal == null
            ? Icons.event_busy
            : Icons.drive_file_move_outline,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(jadwal.nama),
      subtitle: Text(
        '${jadwal.kode} • ${jadwal.jamTeks}\n'
        '${_keteranganKecuali(vm, pengecualian)}',
      ),
      isThreeLine: true,
      trailing: TextButton(
        key: Key('kembalikan_${jadwal.kode}'),
        onPressed: () => _kembalikan(jadwal),
        child: const Text('Kembalikan'),
      ),
    ),
  );

  Widget _kartuKhusus(JadwalViewModel vm, JadwalKuliah jadwal) {
    final asal = vm.asalPindahan(_tanggal, jadwal.kode);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          asal == null ? Icons.event_available : Icons.drive_file_move_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(jadwal.nama),
        subtitle: Text(
          asal == null
              ? '${jadwal.kode} • ${jadwal.jamTeks}'
              : '${jadwal.kode} • ${jadwal.jamTeks}\n'
                    'Pindahan dari ${formatTanggalPendek(asal)}',
        ),
        isThreeLine: asal != null,
        trailing: IconButton(
          key: Key('hapusTanggal_${jadwal.kode}'),
          tooltip: 'Hapus dari tanggal ini',
          onPressed: () => _hapusUntukTanggal(jadwal),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JadwalViewModel>();
    final libur = namaHariLibur(_tanggal);
    final tanggalMerah = _tanggal.weekday == DateTime.sunday
        ? null
        : namaTanggalMerah(_tanggal);
    final mingguan = vm.mingguanBerlakuUntukTanggal(_tanggal);
    final dikecualikan = vm.kelasDikecualikanUntukTanggal(_tanggal);
    final khusus = vm.kelasKhususUntukTanggal(_tanggal);
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tambahMataKuliah'),
        // heroTag null: mencegah tombol "Tambah" di tab Catatan ikut
        // beranimasi "terbang" ke tombol ini saat berpindah halaman.
        heroTag: null,
        onPressed: vm.sedangMemuat || vm.galat != null ? null : _tambahMingguan,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal Kelas'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              key: const Key('pilihTanggalKhusus'),
              onTap: vm.sedangMemuat ? null : _pilihTanggal,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tema.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JADWAL UNTUK TANGGAL',
                            style: tema.textTheme.labelSmall?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${namaHari[_tanggal.weekday - 1]}, ${formatTanggalPendek(_tanggal)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_calendar_outlined),
                  ],
                ),
              ),
            ),
          ),
          if (tanggalMerah != null && libur == null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tema.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event,
                        size: 18,
                        color: tema.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Tanggal merah: $tanggalMerah · '
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
              ),
            ),
          ],
          if (vm.galat != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.galat!,
                    style: TextStyle(color: tema.colorScheme.error),
                  ),
                  TextButton(
                    onPressed: vm.sedangMemuat ? null : vm.muat,
                    child: const Text('Coba muat ulang'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (vm.sedangMemuat)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (mingguan.isEmpty && khusus.isEmpty && dikecualikan.isEmpty)
              _kartuKosong(
                ikon: libur == null ? Icons.event_note : Icons.event_busy,
                judul: 'Belum ada mata kuliah',
                deskripsi: 'Tidak ada jadwal untuk tanggal ini.',
              )
            else ...[
              if (mingguan.isNotEmpty) ...[
                _judulBagian(
                  ikon: Icons.repeat,
                  judul: 'Jadwal mingguan',
                  jumlah: mingguan.length,
                ),
                for (final jadwal in mingguan) _kartuMingguan(jadwal),
              ],
              if (dikecualikan.isNotEmpty) ...[
                _judulBagian(
                  ikon: Icons.rule,
                  judul: 'Dikecualikan pada tanggal ini',
                  jumlah: dikecualikan.length,
                ),
                for (final (jadwal, pengecualian) in dikecualikan)
                  _kartuDikecualikan(vm, jadwal, pengecualian),
              ],
              _judulBagian(
                ikon: Icons.event_available,
                judul: 'Kelas khusus tanggal ini',
                jumlah: khusus.length,
              ),
              if (khusus.isEmpty)
                _kartuKosong(
                  ikon: Icons.add_circle_outline,
                  judul: 'Belum ada kelas khusus',
                  deskripsi: 'Tambahan hanya berlaku pada tanggal ini.',
                )
              else
                for (final jadwal in khusus) _kartuKhusus(vm, jadwal),
            ],
          ],
        ],
      ),
    );
  }
}
