import 'package:flutter/material.dart';

import '../data/jadwal.dart';

Future<DateTime?> pilihTanggalAkademik({
  required BuildContext context,
  required DateTime tanggalAwal,
  DateTime? sekarang,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _DialogKalenderAkademik(
    tanggalAwal: tanggalAwal,
    sekarang: sekarang ?? DateTime.now(),
  ),
);

class _DialogKalenderAkademik extends StatefulWidget {
  final DateTime tanggalAwal;
  final DateTime sekarang;

  const _DialogKalenderAkademik({
    required this.tanggalAwal,
    required this.sekarang,
  });

  @override
  State<_DialogKalenderAkademik> createState() =>
      _DialogKalenderAkademikState();
}

class _DialogKalenderAkademikState extends State<_DialogKalenderAkademik> {
  late DateTime _terpilih = DateTime(
    widget.tanggalAwal.year,
    widget.tanggalAwal.month,
    widget.tanggalAwal.day,
  );
  late DateTime _bulanTampil = DateTime(_terpilih.year, _terpilih.month);

  void _ubahBulan(int selisih) {
    final bulanBaru = DateTime(_bulanTampil.year, _bulanTampil.month + selisih);
    if (bulanBaru.year < 1900 || bulanBaru.year > 9999) return;
    setState(() => _bulanTampil = bulanBaru);
  }

  Widget _tanggal(DateTime? tanggal) {
    if (tanggal == null) return const SizedBox.expand();
    final tema = Theme.of(context);
    final libur = namaHariLibur(tanggal);
    final dipilih = hariSama(tanggal, _terpilih);
    final hariIni = hariSama(tanggal, widget.sekarang);
    final merah = libur != null;

    return Semantics(
      button: true,
      label:
          '${tanggal.day} ${namaBulan[tanggal.month - 1]} ${tanggal.year}'
          '${libur == null ? '' : ', $libur'}',
      child: InkWell(
        key: Key('tanggal_${kunciTanggal(tanggal)}'),
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _terpilih = tanggal),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dipilih
                ? tema.colorScheme.primary
                : merah
                ? const Color(0xFFFFE0E0)
                : null,
            border: merah && dipilih
                ? Border.all(color: Colors.red.shade700, width: 2)
                : hariIni
                ? Border.all(color: tema.colorScheme.primary)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${tanggal.day}',
            style: TextStyle(
              color: dipilih
                  ? tema.colorScheme.onPrimary
                  : merah
                  ? Colors.red.shade800
                  : null,
              fontWeight: dipilih || merah || hariIni
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lebarLayar = MediaQuery.sizeOf(context).width;
    final lebarKonten = (lebarLayar - 128).clamp(0, 340).toDouble();
    final hariPertama = DateTime(_bulanTampil.year, _bulanTampil.month, 1);
    final jumlahHari = DateTime(
      _bulanTampil.year,
      _bulanTampil.month + 1,
      0,
    ).day;
    final offset = hariPertama.weekday - DateTime.monday;
    final jumlahSel = ((offset + jumlahHari + 6) ~/ 7) * 7;
    final namaLiburTerpilih = namaHariLibur(_terpilih);
    final batasBulanSebelumnya =
        _bulanTampil.year == 1900 && _bulanTampil.month == DateTime.january;
    final batasBulanBerikutnya =
        _bulanTampil.year == 9999 && _bulanTampil.month == DateTime.december;

    return AlertDialog(
      key: const Key('kalenderAkademik'),
      title: const Text('Pilih tanggal'),
      content: SizedBox(
        width: lebarKonten,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Bulan sebelumnya',
                  onPressed: batasBulanSebelumnya ? null : () => _ubahBulan(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    '${namaBulan[_bulanTampil.month - 1]} ${_bulanTampil.year}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Bulan berikutnya',
                  onPressed: batasBulanBerikutnya ? null : () => _ubahBulan(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (final hari in [
                  'Sen',
                  'Sel',
                  'Rab',
                  'Kam',
                  'Jum',
                  'Sab',
                  'Min',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        hari,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 6 * 40,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisExtent: 40,
                ),
                itemCount: jumlahSel,
                itemBuilder: (context, index) {
                  final hari = index - offset + 1;
                  if (hari < 1 || hari > jumlahHari) {
                    return const SizedBox.expand();
                  }
                  return _tanggal(
                    DateTime(_bulanTampil.year, _bulanTampil.month, hari),
                  );
                },
              ),
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE0E0),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(child: Text('Tanggal merah: hari libur')),
              ],
            ),
            if (namaLiburTerpilih != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  namaLiburTerpilih,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _terpilih),
          child: const Text('Pilih'),
        ),
      ],
    );
  }
}
