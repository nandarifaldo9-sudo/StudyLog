import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/jadwal.dart';

class JadwalPage extends StatelessWidget {
  const JadwalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final jadwalStore = context.watch<JadwalViewModel>();
    final jadwalMap = jadwalStore.jadwalKuliah;

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Jadwal')),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 7,
        itemBuilder: (context, index) {
          final hariIndex = index + 1; // 1 = Senin, 7 = Minggu
          final hariName = namaHari[index];
          final listJadwal = jadwalMap[hariIndex] ?? [];

          return ExpansionTile(
            title: Text(hariName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${listJadwal.length} Mata Kuliah'),
            children: [
              for (final j in listJadwal)
                ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(j.nama),
                  subtitle: Text('${j.kode} • ${j.jamTeks}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => jadwalStore.hapusJadwal(hariIndex, j),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: OutlinedButton.icon(
                  onPressed: () => _tampilDialogTambah(context, hariIndex),
                  icon: const Icon(Icons.add),
                  label: Text('Tambah Jadwal di hari $hariName'),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  void _tampilDialogTambah(BuildContext context, int hariIndex) {
    final kodeCtrl = TextEditingController();
    final namaCtrl = TextEditingController();
    TimeOfDay mulaiWaktu = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay selesaiWaktu = const TimeOfDay(hour: 10, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Tambah Jadwal (${namaHari[hariIndex - 1]})'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: 'Kode MK (Opsional)')),
                    TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Mata Kuliah')),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(context: context, initialTime: mulaiWaktu);
                              if (time != null) setState(() => mulaiWaktu = time);
                            },
                            child: Text('Mulai:\n${mulaiWaktu.format(context)}', textAlign: TextAlign.center),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final time = await showTimePicker(context: context, initialTime: selesaiWaktu);
                              if (time != null) setState(() => selesaiWaktu = time);
                            },
                            child: Text('Selesai:\n${selesaiWaktu.format(context)}', textAlign: TextAlign.center),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                FilledButton(
                  onPressed: () {
                    if (namaCtrl.text.trim().isEmpty) return;
                    final j = JadwalKuliah(
                      kode: kodeCtrl.text.trim().isEmpty ? '-' : kodeCtrl.text.trim(),
                      nama: namaCtrl.text.trim(),
                      mulai: mulaiWaktu.hour * 60 + mulaiWaktu.minute,
                      selesai: selesaiWaktu.hour * 60 + selesaiWaktu.minute,
                    );
                    context.read<JadwalViewModel>().tambahJadwal(hariIndex, j);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          }
      ),
    );
  }
}