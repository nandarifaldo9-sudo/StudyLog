import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/draft_keys.dart';
import '../data/jadwal.dart';
import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/jadwal_view_model.dart';
import '../widgets/pemilih_tanggal.dart';

enum HasilSimpanCatatan { berhasil, berhasilDenganDraftTertinggal }

class TambahCatatanPage extends StatefulWidget {
  final String? mataKuliah;
  final DateTime? waktuAwal;
  final String? jam;
  final DateTime Function()? now;
  final HasilCatatan? catatanAwal;

  const TambahCatatanPage({
    super.key,
    this.mataKuliah,
    this.waktuAwal,
    this.jam,
    this.now,
    this.catatanAwal,
  });

  @override
  State<TambahCatatanPage> createState() => _TambahCatatanPageState();
}

class _TambahCatatanPageState extends State<TambahCatatanPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _judulController;
  late final TextEditingController _isiController;
  late DateTime _waktuCatatan;
  Timer? _draftTimer;
  String? _mataKuliah;
  bool _draftDipulihkan = false;
  bool _sedangMenyimpan = false;
  bool _mengaturDraft = false;
  int _generasiMuatDraft = 0;
  Future<void> _antrianDraft = Future<void>.value();
  String? _galat;

  bool get _mengubah => widget.catatanAwal != null;

  List<JadwalKuliah> get _jadwalTanggal =>
      context.read<JadwalViewModel>().jadwalUntukTanggal(_waktuCatatan);

  @override
  void initState() {
    super.initState();
    _waktuCatatan = widget.waktuAwal ?? (widget.now ?? DateTime.now)();
    final jadwal = _jadwalTanggal;
    _mataKuliah = jadwal.any((j) => j.nama == widget.mataKuliah)
        ? widget.mataKuliah
        : jadwal.isEmpty
        ? null
        : jadwal.first.nama;
    _judulController = TextEditingController(
      text: widget.catatanAwal?.judul ?? '',
    );
    _isiController = TextEditingController(text: widget.catatanAwal?.isi ?? '');
    _judulController.addListener(_jadwalkanSimpanDraft);
    _isiController.addListener(_jadwalkanSimpanDraft);
    if (!_mengubah && _mataKuliah != null) {
      _muatDraft(_mataKuliah!);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _muatDraft(String mataKuliah) async {
    final generasi = ++_generasiMuatDraft;
    try {
      await _antrianDraft;
      final prefs = await SharedPreferences.getInstance();
      final judul = prefs.getString(kDraftJudul(mataKuliah)) ?? '';
      final isi = prefs.getString(kDraftIsi(mataKuliah)) ?? '';
      if (!mounted || generasi != _generasiMuatDraft) return;
      if (judul.isNotEmpty || isi.isNotEmpty) {
        _mengaturDraft = true;
        _judulController.text = judul;
        _isiController.text = isi;
        _mengaturDraft = false;
        setState(() => _draftDipulihkan = true);
      }
    } catch (error) {
      if (!mounted || generasi != _generasiMuatDraft) return;
      setState(() => _galat = 'Gagal memuat draft: $error');
    }
  }

  void _jadwalkanSimpanDraft() {
    if (_mengubah ||
        _mengaturDraft ||
        _sedangMenyimpan ||
        _mataKuliah == null) {
      return;
    }
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _simpanDraft);
  }

  Future<void> _simpanDraft() async {
    final mataKuliah = _mataKuliah;
    if (mataKuliah == null) return;
    await _simpanDraftKonten(
      mataKuliah,
      _judulController.text,
      _isiController.text,
    );
  }

  Future<void> _simpanDraftKonten(
    String mataKuliah,
    String judul,
    String isi,
  ) {
    final operasi = _antrianDraft.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      final judulTersimpan = await prefs.setString(
        kDraftJudul(mataKuliah),
        judul,
      );
      final isiTersimpan = await prefs.setString(kDraftIsi(mataKuliah), isi);
      if (!judulTersimpan || !isiTersimpan) {
        throw StateError('Draft gagal disimpan ke perangkat.');
      }
    });
    _antrianDraft = operasi.catchError((Object error) {
      if (mounted) setState(() => _galat = 'Gagal menyimpan draft: $error');
    });
    return _antrianDraft;
  }

  Future<void> _hapusDraft() async {
    await _antrianDraft;
    final prefs = await SharedPreferences.getInstance();
    final judulDihapus = await prefs.remove(kDraftJudul(_mataKuliah!));
    final isiDihapus = await prefs.remove(kDraftIsi(_mataKuliah!));
    if (!judulDihapus || !isiDihapus) {
      throw StateError('Draft lama belum dapat dihapus dari perangkat.');
    }
  }

  void _gantiMataKuliah(String? mataKuliah) {
    if (mataKuliah == _mataKuliah) return;
    _draftTimer?.cancel();
    final sebelumnya = _mataKuliah;
    final judulSebelumnya = _judulController.text;
    final isiSebelumnya = _isiController.text;
    if (sebelumnya != null) {
      _simpanDraftKonten(sebelumnya, judulSebelumnya, isiSebelumnya);
    }
    _generasiMuatDraft++;
    _mengaturDraft = true;
    setState(() {
      _mataKuliah = mataKuliah;
      _draftDipulihkan = false;
      _judulController.clear();
      _isiController.clear();
    });
    _mengaturDraft = false;
    if (mataKuliah != null) _muatDraft(mataKuliah);
  }

  Future<void> _pilihTanggal() async {
    final tanggal = await pilihTanggalAkademik(
      context: context,
      tanggalAwal: _waktuCatatan,
      sekarang: (widget.now ?? DateTime.now)(),
    );
    if (tanggal == null || !mounted) return;

    final waktuBaru = DateTime(
      tanggal.year,
      tanggal.month,
      tanggal.day,
      _waktuCatatan.hour,
      _waktuCatatan.minute,
    );
    final jadwalBaru = context.read<JadwalViewModel>().jadwalUntukTanggal(
      waktuBaru,
    );
    final mataKuliahBaru = jadwalBaru.any((j) => j.nama == _mataKuliah)
        ? _mataKuliah
        : jadwalBaru.isEmpty
        ? null
        : jadwalBaru.first.nama;

    setState(() => _waktuCatatan = waktuBaru);
    _gantiMataKuliah(mataKuliahBaru);
  }

  Future<void> _pilihWaktu() async {
    final waktu = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_waktuCatatan),
      helpText: 'Pilih waktu kuliah',
    );
    if (waktu == null || !mounted) return;
    setState(() {
      _waktuCatatan = DateTime(
        _waktuCatatan.year,
        _waktuCatatan.month,
        _waktuCatatan.day,
        waktu.hour,
        waktu.minute,
      );
    });
  }

  String? _validasiWajib(String? nilai, String pesan) {
    if (nilai == null || nilai.trim().isEmpty) return pesan;
    return null;
  }

  Future<void> _simpan() async {
    if (_sedangMenyimpan || !_formKey.currentState!.validate()) return;
    final store = context.read<CatatanViewModel>();
    if (store.sedangMemuat || store.galat != null) return;

    setState(() {
      _sedangMenyimpan = true;
      _galat = null;
    });
    try {
      final judul = _judulController.text.trim();
      final isi = _isiController.text.trim();
      var draftTertinggal = false;
      if (_mengubah) {
        await store.ubah(widget.catatanAwal!.id, judul: judul, isi: isi);
      } else {
        await store.tambah(
          mataKuliah: _mataKuliah!,
          judul: judul,
          isi: isi,
          waktu: _waktuCatatan,
        );
        _draftTimer?.cancel();
        try {
          await _hapusDraft();
        } catch (_) {
          draftTertinggal = true;
        }
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        draftTertinggal
            ? HasilSimpanCatatan.berhasilDenganDraftTertinggal
            : HasilSimpanCatatan.berhasil,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sedangMenyimpan = false;
        _galat = 'Gagal menyimpan catatan: $e';
      });
    }
  }

  Widget _pilihTanggalDanWaktu() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('pilihTanggal'),
            onPressed: _sedangMenyimpan ? null : _pilihTanggal,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              formatTanggalPendek(_waktuCatatan),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          key: const Key('pilihWaktu'),
          onPressed: _sedangMenyimpan ? null : _pilihWaktu,
          icon: const Icon(Icons.access_time),
          label: Text(formatJam(_waktuCatatan)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final catatanViewModel = context.watch<CatatanViewModel>();
    final jadwalViewModel = context.watch<JadwalViewModel>();
    final jadwalTanggal = jadwalViewModel.jadwalUntukTanggal(_waktuCatatan);
    final jadwalTerpilih = jadwalTanggal.where((j) => j.nama == _mataKuliah);
    final infoLibur = namaHariLibur(_waktuCatatan);

    return PopScope(
      canPop: !_sedangMenyimpan,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_mengubah ? 'Ubah Catatan' : 'Tambah Catatan'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              if (_mengubah)
                Text(
                  widget.catatanAwal!.mataKuliah,
                  style: Theme.of(context).textTheme.titleMedium,
                )
              else ...[
                _pilihTanggalDanWaktu(),
                if (infoLibur != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(
                        Icons.event_busy,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text(infoLibur),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      side: BorderSide.none,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_mataKuliah),
                  initialValue: _mataKuliah,
                  decoration: const InputDecoration(
                    labelText: 'Mata kuliah',
                  ),
                  items: [
                    for (final jadwal in jadwalTanggal)
                      DropdownMenuItem(
                        value: jadwal.nama,
                        child: Text(jadwal.nama),
                      ),
                  ],
                  onChanged: _sedangMenyimpan || jadwalViewModel.sedangMemuat
                      ? null
                      : _gantiMataKuliah,
                  validator: (nilai) => nilai == null
                      ? 'Tidak ada jadwal pada tanggal ini'
                      : null,
                ),
                if (jadwalTanggal.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Belum ada mata kuliah pada tanggal ini.',
                  ),
                ],
                if (jadwalTerpilih.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Jadwal: ${jadwalTerpilih.first.jamTeks}'),
                ],
              ],
              if (widget.jam != null && _mengubah) ...[
                const SizedBox(height: 4),
                Text(widget.jam!),
              ],
              if (_draftDipulihkan) ...[
                const SizedBox(height: 8),
                const Text('Draft dipulihkan'),
              ],
              if (_galat != null) ...[
                const SizedBox(height: 12),
                Text(
                  _galat!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (catatanViewModel.galat != null) ...[
                const SizedBox(height: 12),
                Text(
                  catatanViewModel.galat!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: catatanViewModel.sedangMemuat
                      ? null
                      : catatanViewModel.muat,
                  child: const Text('Coba muat ulang'),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulController,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(
                  labelText: 'Judul catatan',
                ),
                textInputAction: TextInputAction.next,
                validator: (nilai) =>
                    _validasiWajib(nilai, 'Judul catatan wajib diisi'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isiController,
                enabled: !_sedangMenyimpan,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
                validator: (nilai) =>
                    _validasiWajib(nilai, 'Isi catatan wajib diisi'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    _sedangMenyimpan ||
                        jadwalViewModel.sedangMemuat ||
                        catatanViewModel.sedangMemuat ||
                        catatanViewModel.galat != null
                    ? null
                    : _simpan,
                child: Text(
                  _sedangMenyimpan
                      ? 'Menyimpan...'
                      : _mengubah
                      ? 'Simpan perubahan'
                      : 'Simpan',
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
