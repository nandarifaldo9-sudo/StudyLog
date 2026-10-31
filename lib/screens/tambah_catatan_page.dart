import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/draft_keys.dart';
import '../models/catatan.dart';
import '../viewmodels/catatan_view_model.dart';

class TambahCatatanPage extends StatefulWidget {
  final String mataKuliah;
  final String? jam;
  final DateTime Function()? now;
  final HasilCatatan? catatanAwal;

  const TambahCatatanPage({
    super.key,
    required this.mataKuliah,
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
  Timer? _draftTimer;
  bool _draftDipulihkan = false;
  bool _sedangMenyimpan = false;
  String? _galat;

  bool get _mengubah => widget.catatanAwal != null;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(
      text: widget.catatanAwal?.judul ?? '',
    );
    _isiController = TextEditingController(text: widget.catatanAwal?.isi ?? '');
    _judulController.addListener(_jadwalkanSimpanDraft);
    _isiController.addListener(_jadwalkanSimpanDraft);
    if (!_mengubah) _muatDraft();
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  Future<void> _muatDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final judul = prefs.getString(kDraftJudul(widget.mataKuliah)) ?? '';
    final isi = prefs.getString(kDraftIsi(widget.mataKuliah)) ?? '';
    if (!mounted) return;
    if (judul.isNotEmpty || isi.isNotEmpty) {
      _judulController.text = judul;
      _isiController.text = isi;
      setState(() => _draftDipulihkan = true);
    }
  }

  void _jadwalkanSimpanDraft() {
    if (_mengubah) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _simpanDraft);
  }

  Future<void> _simpanDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kDraftJudul(widget.mataKuliah),
        _judulController.text,
      );
      await prefs.setString(kDraftIsi(widget.mataKuliah), _isiController.text);
    } catch (e) {
      if (mounted) setState(() => _galat = 'Gagal menyimpan draft: $e');
    }
  }

  Future<void> _hapusDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kDraftJudul(widget.mataKuliah));
    await prefs.remove(kDraftIsi(widget.mataKuliah));
  }

  String? _validasiWajib(String? nilai, String pesan) {
    if (nilai == null || nilai.trim().isEmpty) return pesan;
    return null;
  }

  Future<void> _simpan() async {
    if (_sedangMenyimpan || !_formKey.currentState!.validate()) return;

    setState(() {
      _sedangMenyimpan = true;
      _galat = null;
    });
    try {
      final store = context.read<CatatanViewModel>();
      final judul = _judulController.text.trim();
      final isi = _isiController.text.trim();
      if (_mengubah) {
        await store.ubah(widget.catatanAwal!.id, judul: judul, isi: isi);
      } else {
        await store.tambah(
          mataKuliah: widget.mataKuliah,
          judul: judul,
          isi: isi,
          waktu: (widget.now ?? DateTime.now)(),
        );
        _draftTimer?.cancel();
        await _hapusDraft();
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sedangMenyimpan = false;
        _galat = 'Gagal menyimpan catatan: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Text(
                widget.mataKuliah,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (widget.jam != null) ...[
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul catatan',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (nilai) =>
                    _validasiWajib(nilai, 'Judul catatan wajib diisi'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isiController,
                decoration: const InputDecoration(
                  labelText: 'Isi catatan',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: 10,
                validator: (nilai) =>
                    _validasiWajib(nilai, 'Isi catatan wajib diisi'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _sedangMenyimpan ? null : _simpan,
                child: Text(
                  _sedangMenyimpan
                      ? 'MENYIMPAN...'
                      : _mengubah
                      ? 'SIMPAN PERUBAHAN'
                      : 'SIMPAN',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
