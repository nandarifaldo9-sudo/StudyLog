import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/draft_keys.dart';
import '../data/jadwal.dart';
import '../viewmodels/catatan_view_model.dart';
import 'daftar_catatan_page.dart';
import 'dashboard_page.dart';
import 'jadwal_page.dart';
import 'tambah_catatan_page.dart';
import '../viewmodels/jadwal_view_model.dart';

/// Kerangka utama: bottom navigation (Dashboard, Jadwal, Catatan).
/// Jam "sekarang" dan status draft disimpan di sini supaya semua tab sinkron.
class HomeShell extends StatefulWidget {
  final DateTime Function()? now;

  const HomeShell({super.key, this.now});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  late DateTime _sekarang;
  Timer? _jamTimer;
  Set<String> _adaDraft = {};
  late final JadwalViewModel _jadwalViewModel;
  int _generasiMuatDraft = 0;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _jadwalViewModel = context.read<JadwalViewModel>();
    _jadwalViewModel.addListener(_jadwalBerubah);
    _sekarang = _now();
    _jamTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _perbaruiWaktu(),
    );
    _muatStatusDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jadwalViewModel.removeListener(_jadwalBerubah);
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

  Future<void> _muatStatusDraft() async {
    final generasi = ++_generasiMuatDraft;
    try {
      final ada = await muatMataKuliahBerdraft(
        _jadwalViewModel.semuaMataKuliah,
      );
      if (!mounted || generasi != _generasiMuatDraft) return;
      setState(() => _adaDraft = ada);
    } catch (error) {
      if (!mounted || generasi != _generasiMuatDraft) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Status draft gagal dimuat: $error')),
        );
    }
  }

  void _jadwalBerubah() {
    unawaited(_muatStatusDraft());
  }

  /// Dipakai Dashboard dan Jadwal: buka form catatan untuk satu mata kuliah.
  Future<void> _bukaForm(JadwalKuliah jadwal, DateTime waktuAwal) async {
    final catatanViewModel = context.read<CatatanViewModel>();
    if (catatanViewModel.sedangMemuat || catatanViewModel.galat != null) {
      return;
    }
    final tanggal = hariSama(waktuAwal, _sekarang);
    final waktuCatatan = tanggal
        ? _sekarang
        : DateTime(
            waktuAwal.year,
            waktuAwal.month,
            waktuAwal.day,
            jadwal.mulai ~/ 60,
            jadwal.mulai % 60,
          );
    final hasil = await Navigator.push<HasilSimpanCatatan>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahCatatanPage(
          mataKuliah: jadwal.nama,
          waktuAwal: waktuCatatan,
          now: widget.now,
        ),
      ),
    );
    if (!mounted) return;
    if (hasil != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hasil == HasilSimpanCatatan.berhasilDenganDraftTertinggal
                ? 'Catatan tersimpan, tetapi draft lama belum terhapus'
                : 'Catatan berhasil disimpan',
          ),
        ),
      );
    }
    await _muatStatusDraft();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardPage(
            sekarang: _sekarang,
            adaDraft: _adaDraft,
            onTambahCatatan: _bukaForm,
            onPindahTab: (i) => setState(() => _tab = i),
          ),
          JadwalPage(
            sekarang: _sekarang,
            adaDraft: _adaDraft,
            onTambahCatatan: _bukaForm,
          ),
          DaftarCatatanPage(now: widget.now),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          _muatStatusDraft();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Catatan',
          ),
        ],
      ),
    );
  }
}
