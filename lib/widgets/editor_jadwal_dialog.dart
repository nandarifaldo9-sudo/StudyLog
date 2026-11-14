import 'package:flutter/material.dart';

import '../data/jadwal.dart';

class HasilEditorJadwal {
  final int hari;
  final JadwalKuliah jadwal;

  const HasilEditorJadwal({required this.hari, required this.jadwal});
}

Future<HasilEditorJadwal?> bukaEditorJadwal(
  BuildContext context, {
  required int hariAwal,
  JadwalKuliah? jadwalAwal,
  bool pilihHari = true,
}) => showDialog<HasilEditorJadwal>(
  context: context,
  builder: (_) => _EditorJadwalDialog(
    hariAwal: hariAwal,
    jadwalAwal: jadwalAwal,
    pilihHari: pilihHari,
  ),
);

class _EditorJadwalDialog extends StatefulWidget {
  final int hariAwal;
  final JadwalKuliah? jadwalAwal;
  final bool pilihHari;

  const _EditorJadwalDialog({
    required this.hariAwal,
    required this.jadwalAwal,
    required this.pilihHari,
  });

  @override
  State<_EditorJadwalDialog> createState() => _EditorJadwalDialogState();
}

class _EditorJadwalDialogState extends State<_EditorJadwalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late int _hari;
  late int _mulai;
  late int _selesai;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(
      text: widget.jadwalAwal?.kode ?? '',
    );
    _namaController = TextEditingController(
      text: widget.jadwalAwal?.nama ?? '',
    );
    _hari = widget.hariAwal;
    _mulai = widget.jadwalAwal?.mulai ?? 19 * 60;
    _selesai = widget.jadwalAwal?.selesai ?? 20 * 60 + 30;
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _pilihJam(bool mulai) async {
    final menit = mulai ? _mulai : _selesai;
    final waktu = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: menit ~/ 60, minute: menit % 60),
    );
    if (waktu == null || !mounted) return;
    setState(() {
      if (mulai) {
        _mulai = waktu.hour * 60 + waktu.minute;
      } else {
        _selesai = waktu.hour * 60 + waktu.minute;
      }
    });
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    if (_selesai <= _mulai) {
      setState(() => _galat = 'Jam selesai harus setelah jam mulai.');
      return;
    }
    Navigator.pop(
      context,
      HasilEditorJadwal(
        hari: _hari,
        jadwal: JadwalKuliah(
          kode: _kodeController.text.trim(),
          nama: _namaController.text.trim(),
          mulai: _mulai,
          selesai: _selesai,
        ),
      ),
    );
  }

  Widget _jamButton({
    required String label,
    required int menit,
    required VoidCallback onPressed,
  }) => Expanded(
    child: OutlinedButton(
      onPressed: onPressed,
      child: Text('$label ${formatMenit(menit)}'),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tambah = widget.jadwalAwal == null;
    return AlertDialog(
      title: Text(tambah ? 'Tambah mata kuliah' : 'Ubah jadwal mata kuliah'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.pilihHari) ...[
                  DropdownButtonFormField<int>(
                    initialValue: _hari,
                    decoration: const InputDecoration(labelText: 'Hari'),
                    items: [
                      for (
                        var hari = DateTime.monday;
                        hari <= DateTime.saturday;
                        hari++
                      )
                        DropdownMenuItem(
                          value: hari,
                          child: Text(namaHari[hari - 1]),
                        ),
                    ],
                    onChanged: (hari) {
                      if (hari != null) setState(() => _hari = hari);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _kodeController,
                  decoration: const InputDecoration(
                    labelText: 'Kode mata kuliah',
                  ),
                  validator: (nilai) => nilai == null || nilai.trim().isEmpty
                      ? 'Kode mata kuliah wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama mata kuliah',
                  ),
                  validator: (nilai) => nilai == null || nilai.trim().isEmpty
                      ? 'Nama mata kuliah wajib diisi'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _jamButton(
                      label: 'Mulai',
                      menit: _mulai,
                      onPressed: () => _pilihJam(true),
                    ),
                    const SizedBox(width: 8),
                    _jamButton(
                      label: 'Selesai',
                      menit: _selesai,
                      onPressed: () => _pilihJam(false),
                    ),
                  ],
                ),
                if (_galat != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _galat!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('simpanJadwal'),
          onPressed: _simpan,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
