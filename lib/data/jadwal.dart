// Data jadwal kuliah: model sesi, status berdasarkan jam, dan jadwal per hari.

const List<String> namaHari = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

/// Satu sesi kuliah. [mulai] dan [selesai] dalam menit sejak 00:00.
class JadwalKuliah {
  final String kode;
  final String nama;
  final int mulai;
  final int selesai;

  const JadwalKuliah({
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

/// Jam mulai inklusif, jam selesai eksklusif (20:30 sudah masuk sesi berikutnya).
StatusKuliah statusKuliah(JadwalKuliah jadwal, DateTime sekarang) {
  final menit = sekarang.hour * 60 + sekarang.minute;
  if (menit < jadwal.mulai) return StatusKuliah.akanDatang;
  if (menit < jadwal.selesai) return StatusKuliah.berlangsung;
  return StatusKuliah.selesai;
}

/// Kunci = DateTime.weekday (Senin = 1 ... Minggu = 7), urut sesuai jam.
const Map<int, List<JadwalKuliah>> jadwalKuliah = {
  DateTime.monday: [
    JadwalKuliah(
      kode: '111500',
      nama: 'Sistem Manajemen Basis Data',
      mulai: 19 * 60,
      selesai: 20 * 60 + 30,
    ),
    JadwalKuliah(
      kode: '111600',
      nama: 'Teknologi Aplikasi Bergerak',
      mulai: 20 * 60 + 30,
      selesai: 22 * 60,
    ),
  ],
  DateTime.tuesday: [
    JadwalKuliah(
      kode: '111100',
      nama: 'Penalaran Komputer',
      mulai: 19 * 60,
      selesai: 20 * 60 + 30,
    ),
    JadwalKuliah(
      kode: '111400',
      nama: 'Simulasi dan Game Komputer',
      mulai: 20 * 60 + 30,
      selesai: 22 * 60,
    ),
  ],
  DateTime.wednesday: [
    JadwalKuliah(
      kode: '110700',
      nama: 'Kriptografi',
      mulai: 20 * 60 + 30,
      selesai: 22 * 60,
    ),
  ],
  DateTime.thursday: [
    JadwalKuliah(
      kode: '000800',
      nama: 'Penulisan dan Publikasi Ilmiah',
      mulai: 19 * 60,
      selesai: 20 * 60 + 30,
    ),
  ],
  DateTime.friday: [
    JadwalKuliah(
      kode: '110600',
      nama: 'Jaringan Nirkabel',
      mulai: 19 * 60,
      selesai: 20 * 60 + 30,
    ),
    JadwalKuliah(
      kode: '111000',
      nama: 'Pemrograman Aplikasi Bergerak',
      mulai: 20 * 60 + 30,
      selesai: 22 * 60,
    ),
  ],
};

/// Format jam "HH:mm" dari sebuah [DateTime].
String formatJam(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

const List<String> namaBulanSingkat = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Contoh: "30 Okt 2026"
String formatTanggal(DateTime t) =>
    '${t.day} ${namaBulanSingkat[t.month - 1]} ${t.year}';

/// Contoh: "Jumat, 30 Okt 2026 • 19:28"
String formatWaktuCatatan(DateTime t) =>
    '${namaHari[t.weekday - 1]}, ${formatTanggal(t)} • ${formatJam(t)}';
