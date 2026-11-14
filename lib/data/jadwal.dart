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

/// Hari libur akademik yang ditandai merah pada kalender semester terlampir.
const Map<String, String> hariLiburAkademik = {
  '2026-08-17': 'Hari Kemerdekaan RI',
  '2026-08-25': 'Hari libur akademik',
  '2026-12-24': 'Hari libur akademik',
  '2026-12-25': 'Hari Natal',
  '2027-01-01': 'Tahun Baru Masehi',
};

String kunciTanggal(DateTime tanggal) =>
    '${tanggal.year.toString().padLeft(4, '0')}-'
    '${tanggal.month.toString().padLeft(2, '0')}-'
    '${tanggal.day.toString().padLeft(2, '0')}';

String? namaHariLibur(DateTime tanggal) =>
    hariLiburAkademik[kunciTanggal(tanggal)] ??
    (tanggal.weekday == DateTime.sunday ? 'Hari Minggu' : null);

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

  Map<String, Object> toJson() => {
    'kode': kode,
    'nama': nama,
    'mulai': mulai,
    'selesai': selesai,
  };

  factory JadwalKuliah.fromJson(Map<String, dynamic> json) => JadwalKuliah(
    kode: json['kode'] as String,
    nama: json['nama'] as String,
    mulai: json['mulai'] as int,
    selesai: json['selesai'] as int,
  );
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

const List<String> namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// Contoh: "13 Nov 2026"
String formatTanggalPendek(DateTime t) =>
    '${t.day} ${namaBulan[t.month - 1].substring(0, 3)} ${t.year}';

String formatWaktuCatatan(DateTime t) =>
    '${namaHari[t.weekday - 1]}, ${formatTanggalPendek(t)} • ${formatJam(t)}';

/// Contoh: "Jumat, 13 November 2026"
String formatTanggalLengkap(DateTime t) =>
    '${namaHari[t.weekday - 1]}, ${t.day} ${namaBulan[t.month - 1]} ${t.year}';

String sapaan(DateTime t) {
  if (t.hour < 11) return 'Selamat pagi';
  if (t.hour < 15) return 'Selamat siang';
  if (t.hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

bool hariSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
