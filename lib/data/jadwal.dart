import 'package:flutter/material.dart';

const List<String> namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

class JadwalKuliah {
  final String kode;
  final String nama;
  final int mulai;
  final int selesai;

  JadwalKuliah({
    required this.kode,
    required this.nama,
    required this.mulai,
    required this.selesai,
  });

  String get jamTeks => '${formatMenit(mulai)} - ${formatMenit(selesai)}';
}

String formatMenit(int menit) =>
    '${(menit ~/ 60).toString().padLeft(2, '0')}:${(menit % 60).toString().padLeft(2, '0')}';

enum StatusKuliah { akanDatang, berlangsung, selesai }

StatusKuliah statusKuliah(JadwalKuliah jadwal, DateTime sekarang) {
  final menit = sekarang.hour * 60 + sekarang.minute;
  if (menit < jadwal.mulai) return StatusKuliah.akanDatang;
  if (menit < jadwal.selesai) return StatusKuliah.berlangsung;
  return StatusKuliah.selesai;
}

class JadwalViewModel extends ChangeNotifier {
  // Data bawaan awal (bisa diedit nanti di UI)
  final Map<int, List<JadwalKuliah>> _jadwal = {
    DateTime.monday: [
      JadwalKuliah(kode: '111500', nama: 'Sistem Manajemen Basis Data', mulai: 19 * 60, selesai: 20 * 60 + 30),
      JadwalKuliah(kode: '111600', nama: 'Teknologi Aplikasi Bergerak', mulai: 20 * 60 + 30, selesai: 22 * 60),
    ],
    DateTime.tuesday: [
      JadwalKuliah(kode: '111100', nama: 'Penalaran Komputer', mulai: 19 * 60, selesai: 20 * 60 + 30),
      JadwalKuliah(kode: '111400', nama: 'Simulasi dan Game Komputer', mulai: 20 * 60 + 30, selesai: 22 * 60),
    ],
    DateTime.wednesday: [
      JadwalKuliah(kode: '110700', nama: 'Kriptografi', mulai: 20 * 60 + 30, selesai: 22 * 60),
    ],
    DateTime.thursday: [
      JadwalKuliah(kode: '000800', nama: 'Penulisan dan Publikasi Ilmiah', mulai: 19 * 60, selesai: 20 * 60 + 30),
    ],
    DateTime.friday: [
      JadwalKuliah(kode: '110600', nama: 'Jaringan Nirkabel', mulai: 19 * 60, selesai: 20 * 60 + 30),
      JadwalKuliah(kode: '111000', nama: 'Pemrograman Aplikasi Bergerak', mulai: 20 * 60 + 30, selesai: 22 * 60),
    ],
  };

  Map<int, List<JadwalKuliah>> get jadwalKuliah => _jadwal;

  void tambahJadwal(int hari, JadwalKuliah jadwalBaru) {
    if (_jadwal[hari] == null) _jadwal[hari] = [];
    _jadwal[hari]!.add(jadwalBaru);
    // Mengurutkan jadwal berdasarkan jam mulai
    _jadwal[hari]!.sort((a, b) => a.mulai.compareTo(b.mulai));
    notifyListeners();
  }

  void hapusJadwal(int hari, JadwalKuliah jadwal) {
    _jadwal[hari]?.remove(jadwal);
    notifyListeners();
  }
}

String formatJam(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const List<String> namaBulanSingkat = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String formatTanggal(DateTime t) => '${t.day} ${namaBulanSingkat[t.month - 1]} ${t.year}';
String formatWaktuCatatan(DateTime t) => '${namaHari[t.weekday - 1]}, ${formatTanggal(t)} - ${formatJam(t)}';