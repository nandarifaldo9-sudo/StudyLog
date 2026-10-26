import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/draft_keys.dart';
import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../theme/warna_mata_kuliah.dart';

class TambahCatatanPage extends StatefulWidget {
  /// Mata kuliah ditentukan dari dashboard, bukan dipilih di form.
  final String mataKuliah;
  final String? jam;
  final DateTime Function()? now;

  const TambahCatatanPage({
    super.key,
    required this.mataKuliah,
    this.jam,
    this.now,
  });

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _isi = TextEditingController();

  bool _draftDipulihkan = false;
  bool _sedangMemulihkan = false;
  Timer? _debounce;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _judul.addListener(_jadwalkanSimpanDraft);
    _isi.addListener(_jadwalkanSimpanDraft);
    _muatDraft();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Keluar sebelum jeda debounce selesai: simpan draft sekarang juga.
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
      unawaited(_simpanDraft()); // nilai dibaca sebelum controller di-dispose
    }
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _debounce?.cancel();
      unawaited(_simpanDraft());
    }
  }

  // ----------------------------- DRAFT -------------------------------------

  Future<void> _muatDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final judul = prefs.getString(kDraftJudul(widget.mataKuliah)) ?? '';
    final isi = prefs.getString(kDraftIsi(widget.mataKuliah)) ?? '';
    if (!mounted) return;
    if (judul.trim().isEmpty && isi.trim().isEmpty) return;

    _sedangMemulihkan = true;
    _judul.text = judul;
    _isi.text = isi;
    _sedangMemulihkan = false;
    setState(() => _draftDipulihkan = true);
  }

  void _jadwalkanSimpanDraft() {
    if (_sedangMemulihkan) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _simpanDraft);
  }

  Future<void> _simpanDraft() async {
    // Ambil nilai dulu sebelum await agar aman jika widget sudah ditutup.
    final mk = widget.mataKuliah;
    final judul = _judul.text;
    final isi = _isi.text;
    final prefs = await SharedPreferences.getInstance();

    if (judul.trim().isEmpty && isi.trim().isEmpty) {
      await prefs.remove(kDraftJudul(mk));
      await prefs.remove(kDraftIsi(mk));
      return;
    }
    await prefs.setString(kDraftJudul(mk), judul);
    await prefs.setString(kDraftIsi(mk), isi);
  }

  /// Mengosongkan form dan menghapus draft.
  void _kosongkanForm() {
    _debounce?.cancel();
    _sedangMemulihkan = true;
    _formKey.currentState?.reset();
    _judul.clear();
    _isi.clear();
    _sedangMemulihkan = false;

    setState(() => _draftDipulihkan = false);
    unawaited(_simpanDraft()); // form kosong -> draft dihapus
  }

  // ----------------------------- AKSI --------------------------------------

  String? _wajibDiisi(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi';
    }
    return null;
  }

  /// Event: tombol SIMPAN ditekan.
  void _simpan() {
    if (!_formKey.currentState!.validate()) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Form belum valid, periksa kembali input'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final hasil = HasilCatatan(
      mataKuliah: widget.mataKuliah,
      judul: _judul.text.trim(),
      isi: _isi.text.trim(),
      waktu: _now(),
    );

    _kosongkanForm(); // form bersih + draft dihapus
    Navigator.pop(context, hasil); // kirim hasil ke dashboard
  }

  // ----------------------------- UI ----------------------------------------

  Widget _headerMataKuliah() {
    final warna = warnaUntuk(widget.mataKuliah);
    final hari = namaHari[_now().weekday - 1];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warna,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu_book, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.mataKuliah,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.jam == null
                      ? 'Kuliah hari $hari'
                      : 'Kuliah hari $hari • ${widget.jam}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerDraft() {
    return Card(
      color: const Color(0xFFFFF8E1),
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        leading: const Icon(Icons.restore),
        title: const Text('Draft dipulihkan'),
        subtitle: const Text('Isian terakhirmu yang belum disimpan kembali.'),
        trailing: TextButton(
          onPressed: _kosongkanForm,
          child: const Text('HAPUS'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Catatan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerMataKuliah(),
            if (_draftDipulihkan) _bannerDraft(),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _judul,
                    decoration: const InputDecoration(
                      labelText: 'Judul catatan',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => _wajibDiisi(v, 'Judul catatan'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _isi,
                    decoration: const InputDecoration(
                      labelText: 'Isi catatan',
                      helperText: 'Draft tersimpan otomatis',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (v) => _wajibDiisi(v, 'Isi catatan'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _simpan,
                      child: const Text('SIMPAN'),
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
}
