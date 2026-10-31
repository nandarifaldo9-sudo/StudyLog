import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/draft_keys.dart';
import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../theme/warna_mata_kuliah.dart';
import '../widgets/catatan_card.dart';
import '../widgets/mata_kuliah_card.dart';
import 'tambah_catatan_page.dart';

class DashboardPage extends StatefulWidget {
  final DateTime Function()? now;

  const DashboardPage({super.key, this.now});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  final List<HasilCatatan> _daftarHasil = [];
  Set<String> _adaDraft = {};

  late DateTime _sekarang;
  Timer? _jamTimer;

  DateTime _now() => (widget.now ?? DateTime.now)();

  /// Jadwal pada hari berjalan (kosong pada Sabtu/Minggu).
  List<JadwalKuliah> get _jadwalHariIni =>
      jadwalKuliah[_sekarang.weekday] ?? const <JadwalKuliah>[];

  /// Kuliah yang sedang berlangsung saat ini (null jika tidak ada).
  JadwalKuliah? get _kuliahBerlangsung {
    for (final j in _jadwalHariIni) {
      if (statusKuliah(j, _sekarang) == StatusKuliah.berlangsung) return j;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sekarang = _now();
    // Perbarui hari/jam tiap menit agar benar-benar "real time".
    _jamTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _perbaruiWaktu(),
    );
    _muatStatusDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jamTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _perbaruiWaktu();
      _muatStatusDraft();
    }
  }

  void _perbaruiWaktu() {
    if (!mounted) return;
    setState(() => _sekarang = _now());
  }

  /// Mengecek mata kuliah mana yang masih punya draft.
  Future<void> _muatStatusDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final ada = <String>{};
    for (final j in _jadwalHariIni) {
      final judul = prefs.getString(kDraftJudul(j.nama)) ?? '';
      final isi = prefs.getString(kDraftIsi(j.nama)) ?? '';
      if (judul.trim().isNotEmpty || isi.trim().isNotEmpty) ada.add(j.nama);
    }
    if (!mounted) return;
    setState(() => _adaDraft = ada);
  }

  /// Membuka form untuk mata kuliah terpilih dan menunggu hasilnya.
  Future<void> _bukaForm(JadwalKuliah jadwal) async {
    final hasil = await Navigator.push<HasilCatatan>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahCatatanPage(
          mataKuliah: jadwal.nama,
          jam: jadwal.jamTeks,
          now: widget.now,
        ),
      ),
    );
    if (!mounted) return;
    if (hasil != null) {
      setState(() => _daftarHasil.insert(0, hasil)); // terbaru di atas
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data ditampilkan (belum tersimpan permanen).'),
        ),
      );
    }
    await _muatStatusDraft();
  }

  Widget _infoHari(int jumlahMataKuliah) {
    final hari = namaHari[_sekarang.weekday - 1];
    final tanggal =
        '$hari, ${_sekarang.day}/${_sekarang.month}/${_sekarang.year} • ${formatJam(_sekarang)}';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(tanggal, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              jumlahMataKuliah == 0
                  ? 'Tidak ada jadwal kuliah hari ini.'
                  : 'Hari ini ada $jumlahMataKuliah mata kuliah.',
            ),
          ],
        ),
      ),
    );
  }

  /// Pintasan: mata kuliah yang sedang berlangsung dipilih otomatis.
  Widget _kartuSekarang(JadwalKuliah j) {
    final warna = warnaUntuk(j.nama);
    return Card(
      color: warna,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kuliah saat ini',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              j.nama,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              j.jamTeks,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: warna,
              ),
              onPressed: () => _bukaForm(j),
              child: const Text('CATAT SEKARANG'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jadwalHariIni = _jadwalHariIni;
    final namaHariIni = jadwalHariIni.map((j) => j.nama).toList();
    final berlangsung = _kuliahBerlangsung;
    final catatanHariIni = _daftarHasil
        .where((h) => namaHariIni.contains(h.mataKuliah))
        .toList();
    final judul = Theme.of(context).textTheme.titleMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('StudyLog')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoHari(jadwalHariIni.length),
            if (berlangsung != null) _kartuSekarang(berlangsung),
            const SizedBox(height: 16),
            Text('Mata kuliah hari ini', style: judul),
            const SizedBox(height: 8),
            if (jadwalHariIni.isEmpty)
              const Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada kuliah hari ini. '
                    'Catatan dapat ditambahkan pada hari kuliah.',
                  ),
                ),
              )
            else
              for (final j in jadwalHariIni)
                MataKuliahCard(
                  jadwal: j,
                  status: statusKuliah(j, _sekarang),
                  jumlahCatatan: _daftarHasil
                      .where((h) => h.mataKuliah == j.nama)
                      .length,
                  adaDraft: _adaDraft.contains(j.nama),
                  onTambah: () => _bukaForm(j),
                ),
            if (jadwalHariIni.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Catatan hari ini', style: judul),
              const SizedBox(height: 8),
              if (catatanHariIni.isEmpty)
                const Text(
                  'Belum ada catatan. Tekan TAMBAH CATATAN pada mata kuliah.',
                )
              else
                for (final hasil in catatanHariIni) CatatanCard(data: hasil),
            ],
          ],
        ),
      ),
    );
  }
}
