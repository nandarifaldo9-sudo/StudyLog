import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/jadwal.dart';
import '../viewmodels/jadwal_view_model.dart';
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

  void _tampilkanGalat(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Perubahan jadwal gagal: $error')));
  }

  Future<void> _editMingguan(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final hasil = await bukaEditorJadwal(
      context,
      hariAwal: _tanggal.weekday,
      jadwalAwal: jadwal,
    );
    if (hasil == null || !mounted) return;
    try {
      await context.read<JadwalViewModel>().simpanMataKuliah(
        hariBaru: hasil.hari,
        hariLama: _tanggal.weekday,
        kodeLama: jadwal.kode,
        jadwal: hasil.jadwal,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal mingguan berhasil diubah')),
        );
      }
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
    final konfirmasi = await _konfirmasiHapus(
      judul: 'Hapus mata kuliah mingguan?',
      pesan: '${jadwal.nama} akan dihapus dari jadwal setiap minggu.',
    );
    if (konfirmasi != true || !mounted) return;
    try {
      await context.read<JadwalViewModel>().hapusMataKuliah(
        _tanggal.weekday,
        jadwal.kode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mata kuliah mingguan dihapus')),
        );
      }
    } on ArgumentError catch (error) {
      _tampilkanGalat(error);
    } on StateError catch (error) {
      _tampilkanGalat(error);
    } on Exception catch (error) {
      _tampilkanGalat(error);
    }
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

  Future<void> _tambahUntukTanggal() async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final hasil = await bukaEditorJadwal(
      context,
      hariAwal: _tanggal.weekday,
      pilihHari: false,
    );
    if (hasil == null || !mounted) return;
    try {
      await context.read<JadwalViewModel>().tambahKelasPadaTanggal(
        _tanggal,
        hasil.jadwal,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelas untuk tanggal ini ditambahkan')),
        );
      }
    } on ArgumentError catch (error) {
      _tampilkanGalat(error);
    } on StateError catch (error) {
      _tampilkanGalat(error);
    } on Exception catch (error) {
      _tampilkanGalat(error);
    }
  }

  Future<void> _hapusUntukTanggal(JadwalKuliah jadwal) async {
    final vm = context.read<JadwalViewModel>();
    if (vm.sedangMemuat || vm.galat != null) return;
    final konfirmasi = await _konfirmasiHapus(
      judul: 'Hapus kelas pada tanggal ini?',
      pesan:
          '${jadwal.nama} hanya akan dihapus dari ${formatTanggalPendek(_tanggal)}.',
    );
    if (konfirmasi != true || !mounted) return;
    try {
      await context.read<JadwalViewModel>().hapusKelasPadaTanggal(
        _tanggal,
        jadwal.kode,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kelas tanggal tertentu dihapus')),
        );
      }
    } on ArgumentError catch (error) {
      _tampilkanGalat(error);
    } on StateError catch (error) {
      _tampilkanGalat(error);
    } on Exception catch (error) {
      _tampilkanGalat(error);
    }
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
          if (aksi == 'edit') {
            _editMingguan(jadwal);
          } else {
            _hapusMingguan(jadwal);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Ubah atau pindahkan')),
          PopupMenuItem(value: 'delete', child: Text('Hapus mingguan')),
        ],
      ),
    ),
  );

  Widget _kartuKhusus(JadwalKuliah jadwal) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(
        Icons.event_available,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(jadwal.nama),
      subtitle: Text('${jadwal.kode} • ${jadwal.jamTeks}'),
      trailing: IconButton(
        key: Key('hapusTanggal_${jadwal.kode}'),
        tooltip: 'Hapus dari tanggal ini',
        onPressed: () => _hapusUntukTanggal(jadwal),
        icon: const Icon(Icons.delete_outline),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<JadwalViewModel>();
    final libur = namaHariLibur(_tanggal);
    final mingguan = libur == null
        ? vm.jadwalUntukHari(_tanggal.weekday)
        : const <JadwalKuliah>[];
    final khusus = vm.kelasKhususUntukTanggal(_tanggal);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('tambahMataKuliah'),
        onPressed: vm.sedangMemuat || vm.galat != null
            ? null
            : _tambahUntukTanggal,
        icon: const Icon(Icons.add),
        label: const Text('Tambah mata kuliah'),
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
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JADWAL UNTUK TANGGAL',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  letterSpacing: 0.6,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${namaHari[_tanggal.weekday - 1]}, ${formatTanggalPendek(_tanggal)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
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
          if (libur != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
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
                        Icons.event_busy,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$libur · jadwal mingguan tidak berlaku',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
            if (mingguan.isEmpty && khusus.isEmpty)
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
                for (final jadwal in khusus) _kartuKhusus(jadwal),
            ],
          ],
        ],
      ),
    );
  }
}
