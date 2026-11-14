import 'package:flutter/material.dart';

import '../data/jadwal.dart';
import 'pemilih_tanggal.dart';

class HasilPindahKelas {
  final DateTime tanggal;
  final int mulai;
  final int selesai;

  const HasilPindahKelas({
    required this.tanggal,
    required this.mulai,
    required this.selesai,
  });
}

/// Dialog memindahkan satu pertemuan kelas mingguan (hanya tanggal ini).
Future<HasilPindahKelas?> bukaDialogPindahKelas(
  BuildContext context, {
  required JadwalKuliah jadwal,
  required DateTime tanggalAsal,
  DateTime? sekarang,
}) => showDialog<HasilPindahKelas>(
  context: context,
  builder: (_) => _DialogPindahKelas(
    jadwal: jadwal,
    tanggalAsal: tanggalAsal,
    sekarang: sekarang,
  ),
);

class _DialogPindahKelas extends StatefulWidget {
  final JadwalKuliah jadwal;
  final DateTime tanggalAsal;
  final DateTime? sekarang;

  const _DialogPindahKelas({
    required this.jadwal,
    required this.tanggalAsal,
    required this.sekarang,
  });

  @override
  State<_DialogPindahKelas> createState() => _DialogPindahKelasState();
}

class _DialogPindahKelasState extends State<_DialogPindahKelas> {
  late DateTime _tanggal = DateTime(
    widget.tanggalAsal.year,
    widget.tanggalAsal.month,
    widget.tanggalAsal.day,
  );
  late int _mulai = widget.jadwal.mulai;
  late int _selesai = widget.jadwal.selesai;
  String? _galat;

  Future<void> _pilihTanggal() async {
    final tanggal = await pilihTanggalAkademik(
      context: context,
      tanggalAwal: _tanggal,
      sekarang: widget.sekarang,
    );
    if (tanggal == null || !mounted) return;
    setState(() {
      _tanggal = DateTime(tanggal.year, tanggal.month, tanggal.day);
      _galat = null;
    });
  }

  Future<void> _pilihJam(bool mulai) async {
    final menit = mulai ? _mulai : _selesai;
    final waktu = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: menit ~/ 60, minute: menit % 60),
    );
    if (waktu == null || !mounted) return;
    setState(() {
      final nilai = waktu.hour * 60 + waktu.minute;
      if (mulai) {
        _mulai = nilai;
      } else {
        _selesai = nilai;
      }
      _galat = null;
    });
  }

  void _simpan() {
    if (_selesai <= _mulai) {
      setState(() => _galat = 'Jam selesai harus setelah jam mulai.');
      return;
    }
    final tidakBerubah =
        hariSama(_tanggal, widget.tanggalAsal) &&
        _mulai == widget.jadwal.mulai &&
        _selesai == widget.jadwal.selesai;
    if (tidakBerubah) {
      setState(() => _galat = 'Ubah tanggal atau jam terlebih dahulu.');
      return;
    }
    Navigator.pop(
      context,
      HasilPindahKelas(tanggal: _tanggal, mulai: _mulai, selesai: _selesai),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return AlertDialog(
      title: const Text('Pindahkan hanya tanggal ini'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.jadwal.nama,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Hanya pertemuan ${formatTanggalLengkap(widget.tanggalAsal)} '
                'yang dipindah.',
                style: tema.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('pilihTanggalPindah'),
                  onPressed: _pilihTanggal,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${namaHari[_tanggal.weekday - 1]}, ${formatTanggalPendek(_tanggal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pilihJam(true),
                      child: Text('Mulai ${formatMenit(_mulai)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pilihJam(false),
                      child: Text('Selesai ${formatMenit(_selesai)}'),
                    ),
                  ),
                ],
              ),
              if (_galat != null) ...[
                const SizedBox(height: 8),
                Text(_galat!, style: TextStyle(color: tema.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('simpanPindah'),
          onPressed: _simpan,
          child: const Text('Pindahkan'),
        ),
      ],
    );
  }
}
