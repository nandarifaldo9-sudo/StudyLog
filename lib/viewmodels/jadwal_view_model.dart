import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/jadwal.dart';

class JadwalViewModel extends ChangeNotifier {
  static const _kunciPenyimpanan = 'jadwal_kuliah_mingguan_v1';

  Map<int, List<JadwalKuliah>> _mingguan = _salinMingguan(jadwalKuliah);
  Map<String, List<JadwalKuliah>> _khususTanggal = {};

  /// Kunci = tanggal asal (yyyy-MM-dd): kelas mingguan yang tidak berlangsung
  /// pada tanggal itu (dibatalkan atau dipindahkan).
  Map<String, List<PengecualianKelas>> _pengecualian = {};
  bool _sedangMemuat = false;
  String? _galat;
  bool _disposed = false;
  Future<void> _antrianMutasi = Future<void>.value();

  bool get sedangMemuat => _sedangMemuat;
  String? get galat => _galat;

  Future<void> _serialkan(Future<void> Function() operasi) {
    final selesai = Completer<void>();
    _antrianMutasi = _antrianMutasi.then((_) async {
      try {
        await operasi();
        selesai.complete();
      } catch (error, stackTrace) {
        selesai.completeError(error, stackTrace);
      }
    });
    return selesai.future;
  }

  void _beritahu() {
    if (!_disposed) notifyListeners();
  }

  Set<String> get semuaMataKuliah => {
    for (final daftar in _mingguan.values)
      for (final jadwal in daftar) jadwal.nama,
    for (final daftar in _khususTanggal.values)
      for (final jadwal in daftar) jadwal.nama,
  };

  List<JadwalKuliah> jadwalUntukHari(int hari) =>
      List.unmodifiable(_mingguan[hari] ?? const <JadwalKuliah>[]);

  /// Semua kelas pada [tanggal]: mingguan (kecuali yang dikecualikan) + khusus.
  List<JadwalKuliah> jadwalUntukTanggal(DateTime tanggal) {
    final hasil = [
      ...mingguanBerlakuUntukTanggal(tanggal),
      ...kelasKhususUntukTanggal(tanggal),
    ]..sort((a, b) => a.mulai.compareTo(b.mulai));
    return List.unmodifiable(hasil);
  }

  /// Kelas mingguan yang berlaku pada [tanggal] (tanpa kelas khusus).
  List<JadwalKuliah> mingguanBerlakuUntukTanggal(DateTime tanggal) {
    final dikecualikan = {
      for (final p in pengecualianUntukTanggal(tanggal)) p.kode,
    };
    return [
      for (final j in jadwalUntukHari(tanggal.weekday))
        if (!dikecualikan.contains(j.kode)) j,
    ];
  }

  List<PengecualianKelas> pengecualianUntukTanggal(DateTime tanggal) =>
      List.unmodifiable(
        _pengecualian[kunciTanggal(tanggal)] ?? const <PengecualianKelas>[],
      );

  /// Kelas mingguan yang dibatalkan/dipindahkan pada [tanggal], beserta datanya.
  List<(JadwalKuliah, PengecualianKelas)> kelasDikecualikanUntukTanggal(
    DateTime tanggal,
  ) {
    final hasil = <(JadwalKuliah, PengecualianKelas)>[];
    for (final p in pengecualianUntukTanggal(tanggal)) {
      for (final j in jadwalUntukHari(tanggal.weekday)) {
        if (j.kode == p.kode) hasil.add((j, p));
      }
    }
    return hasil;
  }

  List<JadwalKuliah> kelasKhususUntukTanggal(DateTime tanggal) =>
      List.unmodifiable(
        _khususTanggal[kunciTanggal(tanggal)] ?? const <JadwalKuliah>[],
      );

  /// Tanggal asal jika kelas khusus [kode] pada [tanggal] adalah hasil
  /// pemindahan satu pertemuan mingguan; null jika bukan.
  DateTime? asalPindahan(DateTime tanggal, String kode) {
    final kunci = kunciTanggal(tanggal);
    for (final entry in _pengecualian.entries) {
      for (final p in entry.value) {
        if (p.kode == kode && p.keTanggal == kunci) {
          return DateTime.parse(entry.key);
        }
      }
    }
    return null;
  }

  DateTime? tanggalKelasKhususBerikutnya(DateTime sekarang) {
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    final tanggalTersimpan = _khususTanggal.keys.map(DateTime.parse).toList()
      ..sort((a, b) => a.compareTo(b));
    for (final tanggal in tanggalTersimpan) {
      if (tanggal.isBefore(hariIni)) continue;
      final khusus = kelasKhususUntukTanggal(tanggal);
      if (hariSama(tanggal, hariIni)) {
        if (khusus.any(
          (jadwal) => statusKuliah(jadwal, sekarang) == StatusKuliah.akanDatang,
        )) {
          return tanggal;
        }
      } else if (khusus.isNotEmpty) {
        return tanggal;
      }
    }
    return null;
  }

  Future<void> muat() => _serialkan(_muat);

  Future<void> _muat() async {
    _sedangMemuat = true;
    _galat = null;
    _beritahu();
    try {
      final prefs = await SharedPreferences.getInstance();
      final tersimpan = prefs.getString(_kunciPenyimpanan);
      if (tersimpan != null) {
        final decoded = jsonDecode(tersimpan);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Struktur jadwal tidak valid.');
        }
        final mingguan = _bacaMingguan(decoded['mingguan']);
        final khusus = _bacaKelasKhususTanggal(
          decoded['kelasKhususTanggal'] ?? decoded['khususHariLibur'],
        );
        final pengecualian = _bacaPengecualian(decoded['pengecualianTanggal']);
        _validasiMingguan(mingguan);
        _migrasikanKelasKhususYangBertabrakan(mingguan, khusus, pengecualian);
        for (final kunci in {...khusus.keys, ...pengecualian.keys}) {
          _validasiTanggalPada(
            DateTime.parse(kunci),
            mingguan,
            khusus,
            pengecualian,
          );
        }
        _mingguan = mingguan;
        _khususTanggal = khusus;
        _pengecualian = pengecualian;
      }
    } on FormatException catch (e) {
      _galat = 'Jadwal tersimpan tidak dapat dibaca: ${e.message}';
    } on TypeError catch (e) {
      _galat = 'Format jadwal tersimpan tidak valid: $e';
    } on Exception catch (e) {
      _galat = 'Jadwal tersimpan tidak dapat dimuat: $e';
    } finally {
      _sedangMemuat = false;
      _beritahu();
    }
  }

  static void _migrasikanKelasKhususYangBertabrakan(
    Map<int, List<JadwalKuliah>> mingguan,
    Map<String, List<JadwalKuliah>> khusus,
    Map<String, List<PengecualianKelas>> pengecualian,
  ) {
    for (final entry in khusus.entries) {
      final tanggal = DateTime.parse(entry.key);
      final daftarPengecualian = pengecualian.putIfAbsent(entry.key, () => []);
      final daftarMingguan =
          mingguan[tanggal.weekday] ?? const <JadwalKuliah>[];
      for (final mingguanHari in daftarMingguan) {
        final sudahDikecualikan = daftarPengecualian.any(
          (item) => item.kode == mingguanHari.kode,
        );
        final digantikanKelasKhusus = entry.value.any(
          (kelasKhusus) =>
              kelasKhusus.kode == mingguanHari.kode ||
              kelasKhusus.nama.trim() == mingguanHari.nama.trim() ||
              (kelasKhusus.mulai < mingguanHari.selesai &&
                  mingguanHari.mulai < kelasKhusus.selesai),
        );
        if (!sudahDikecualikan && digantikanKelasKhusus) {
          daftarPengecualian.add(PengecualianKelas(kode: mingguanHari.kode));
        }
      }
      if (daftarPengecualian.isEmpty) pengecualian.remove(entry.key);
    }
  }

  Future<void> simpanMataKuliah({
    required int hariBaru,
    required JadwalKuliah jadwal,
    int? hariLama,
    String? kodeLama,
  }) => _serialkan(() async {
    _validasiHari(hariBaru);
    final mingguan = _salinMingguan(_mingguan);
    if (kodeLama != null) {
      if (hariLama == null) {
        throw ArgumentError('Hari asal wajib diisi saat mengubah jadwal.');
      }
      _validasiHari(hariLama);
      final daftarLama = mingguan[hariLama]!;
      final jumlahLama = daftarLama.length;
      daftarLama.removeWhere((item) => item.kode == kodeLama);
      if (daftarLama.length == jumlahLama) {
        throw StateError('Mata kuliah asal tidak ditemukan.');
      }
    }
    if (mingguan.values.any(
      (daftar) => daftar.any((j) => j.kode == jadwal.kode),
    )) {
      throw ArgumentError('Kode mata kuliah sudah digunakan.');
    }
    mingguan[hariBaru]!.add(jadwal);
    _urutkanMingguan(mingguan);
    _validasiMingguan(mingguan);
    await _simpan(mingguan, _khususTanggal);
  });

  Future<void> hapusMataKuliah(int hari, String kode) => _serialkan(() async {
    _validasiHari(hari);
    final mingguan = _salinMingguan(_mingguan);
    final daftar = mingguan[hari]!;
    final jumlahAwal = daftar.length;
    daftar.removeWhere((jadwal) => jadwal.kode == kode);
    if (daftar.length == jumlahAwal) {
      throw StateError('Mata kuliah tidak ditemukan pada hari tersebut.');
    }
    // Pengecualian untuk mata kuliah yang sudah dihapus tidak lagi bermakna.
    final pengecualian = _salinPengecualian(_pengecualian);
    for (final daftarP in pengecualian.values) {
      daftarP.removeWhere((p) => p.kode == kode);
    }
    pengecualian.removeWhere((_, daftarP) => daftarP.isEmpty);
    await _simpan(mingguan, _khususTanggal, pengecualian);
  });

  Future<void> tambahKelasPadaTanggal(DateTime tanggal, JadwalKuliah jadwal) =>
      _serialkan(() async {
        final khusus = _salinKhusus(_khususTanggal);
        final daftar = khusus.putIfAbsent(kunciTanggal(tanggal), () => []);
        if (daftar.any((item) => item.kode == jadwal.kode)) {
          throw ArgumentError(
            'Kode mata kuliah sudah digunakan pada tanggal ini.',
          );
        }
        daftar.add(jadwal);
        _validasiDaftar(daftar);
        _validasiTanggalPada(tanggal, _mingguan, khusus, _pengecualian);
        await _simpan(_mingguan, khusus);
      });

  Future<void> hapusKelasPadaTanggal(
    DateTime tanggal,
    String kode,
  ) => _serialkan(() async {
    final khusus = _salinKhusus(_khususTanggal);
    final kunci = kunciTanggal(tanggal);
    final daftar = khusus[kunci];
    if (daftar == null) {
      throw StateError('Kelas khusus tidak ditemukan pada tanggal tersebut.');
    }
    final jumlahAwal = daftar.length;
    daftar.removeWhere((j) => j.kode == kode);
    if (daftar.length == jumlahAwal) {
      throw StateError('Kelas khusus tidak ditemukan pada tanggal tersebut.');
    }
    if (daftar.isEmpty) khusus.remove(kunci);

    // Jika ini kelas hasil pemindahan, pertemuan asalnya menjadi "dibatalkan".
    final pengecualian = _salinPengecualian(_pengecualian);
    for (final daftarP in pengecualian.values) {
      for (var i = 0; i < daftarP.length; i++) {
        if (daftarP[i].kode == kode && daftarP[i].keTanggal == kunci) {
          daftarP[i] = PengecualianKelas(kode: kode);
        }
      }
    }
    await _simpan(_mingguan, khusus, pengecualian);
  });

  /// Memindahkan SATU pertemuan kelas mingguan (hanya pada [dariTanggal])
  /// ke [keTanggal] dengan jam baru. Jadwal mingguan tidak berubah.
  Future<void> pindahkanKelasSekali({
    required DateTime dariTanggal,
    required String kode,
    required DateTime keTanggal,
    required int mulai,
    required int selesai,
  }) => _serialkan(() async {
    final asli = _kelasMingguanDi(dariTanggal, kode);
    if (selesai <= mulai) {
      throw ArgumentError('Jam selesai harus setelah jam mulai.');
    }
    final tujuan = kunciTanggal(keTanggal);
    final pengecualian = _salinPengecualian(_pengecualian);
    pengecualian
        .putIfAbsent(kunciTanggal(dariTanggal), () => [])
        .add(PengecualianKelas(kode: kode, keTanggal: tujuan));
    final khusus = _salinKhusus(_khususTanggal);
    final daftar = khusus.putIfAbsent(tujuan, () => []);
    if (daftar.any((item) => item.kode == kode)) {
      throw ArgumentError(
        'Mata kuliah ini sudah terjadwal pada tanggal tersebut.',
      );
    }
    daftar.add(
      JadwalKuliah(
        kode: asli.kode,
        nama: asli.nama,
        mulai: mulai,
        selesai: selesai,
      ),
    );
    _validasiTanggalBaru(keTanggal, khusus, pengecualian);
    await _simpan(_mingguan, khusus, pengecualian);
  });

  /// Membatalkan SATU pertemuan kelas mingguan pada [tanggal] saja.
  Future<void> batalkanKelasSekali({
    required DateTime tanggal,
    required String kode,
  }) => _serialkan(() async {
    _kelasMingguanDi(tanggal, kode);
    final pengecualian = _salinPengecualian(_pengecualian);
    pengecualian
        .putIfAbsent(kunciTanggal(tanggal), () => [])
        .add(PengecualianKelas(kode: kode));
    await _simpan(_mingguan, _khususTanggal, pengecualian);
  });

  /// Mengembalikan pertemuan yang dibatalkan/dipindahkan ke keadaan semula.
  Future<void> kembalikanKelas({
    required DateTime tanggal,
    required String kode,
  }) => _serialkan(() async {
    final kunci = kunciTanggal(tanggal);
    final pengecualian = _salinPengecualian(_pengecualian);
    final daftar = pengecualian[kunci];
    final indeks = daftar?.indexWhere((p) => p.kode == kode) ?? -1;
    if (daftar == null || indeks == -1) {
      throw StateError('Pengecualian tidak ditemukan pada tanggal tersebut.');
    }
    final catatan = daftar.removeAt(indeks);
    if (daftar.isEmpty) pengecualian.remove(kunci);

    final khusus = _salinKhusus(_khususTanggal);
    final tujuan = catatan.keTanggal;
    if (tujuan != null) {
      final daftarTujuan = khusus[tujuan];
      daftarTujuan?.removeWhere((j) => j.kode == kode);
      if (daftarTujuan != null && daftarTujuan.isEmpty) khusus.remove(tujuan);
    }
    _validasiTanggalBaru(tanggal, khusus, pengecualian);
    await _simpan(_mingguan, khusus, pengecualian);
  });

  Future<void> tambahKelasHariLibur(DateTime tanggal, JadwalKuliah jadwal) =>
      tambahKelasPadaTanggal(tanggal, jadwal);

  Future<void> hapusKelasHariLibur(DateTime tanggal, String kode) =>
      hapusKelasPadaTanggal(tanggal, kode);

  List<JadwalKuliah> jadwalKhususHariLibur(DateTime tanggal) =>
      kelasKhususUntukTanggal(tanggal);

  JadwalKuliah _kelasMingguanDi(DateTime tanggal, String kode) {
    for (final j in mingguanBerlakuUntukTanggal(tanggal)) {
      if (j.kode == kode) return j;
    }
    throw StateError(
      'Mata kuliah mingguan tidak ditemukan pada tanggal tersebut.',
    );
  }

  Future<void> _simpan(
    Map<int, List<JadwalKuliah>> mingguan,
    Map<String, List<JadwalKuliah>> khusus, [
    Map<String, List<PengecualianKelas>>? pengecualian,
  ]) async {
    if (_galat != null) {
      throw StateError('Jadwal harus berhasil dimuat sebelum diubah.');
    }
    final kecuali = pengecualian ?? _pengecualian;
    final prefs = await SharedPreferences.getInstance();
    final berhasil = await prefs.setString(
      _kunciPenyimpanan,
      jsonEncode({
        'mingguan': {
          for (var hari = DateTime.monday; hari <= DateTime.sunday; hari++)
            '$hari': [for (final jadwal in mingguan[hari]!) jadwal.toJson()],
        },
        'kelasKhususTanggal': {
          for (final entry in khusus.entries)
            entry.key: [for (final jadwal in entry.value) jadwal.toJson()],
        },
        'pengecualianTanggal': {
          for (final entry in kecuali.entries)
            entry.key: [for (final p in entry.value) p.toJson()],
        },
      }),
    );
    if (!berhasil) throw StateError('Jadwal gagal disimpan ke perangkat.');
    _mingguan = mingguan;
    _khususTanggal = khusus;
    _pengecualian = kecuali;
    _galat = null;
    _beritahu();
  }

  static Map<int, List<JadwalKuliah>> _bacaMingguan(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Daftar jadwal mingguan tidak valid.');
    }
    final result = <int, List<JadwalKuliah>>{};
    for (var hari = DateTime.monday; hari <= DateTime.sunday; hari++) {
      final raw = value['$hari'];
      if (raw is! List) {
        throw FormatException('Jadwal hari $hari tidak valid.');
      }
      result[hari] = raw.map(_bacaJadwal).toList();
    }
    return result;
  }

  static Map<String, List<JadwalKuliah>> _bacaKelasKhususTanggal(
    Object? value,
  ) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Daftar jadwal khusus tidak valid.');
    }
    final result = <String, List<JadwalKuliah>>{};
    for (final entry in value.entries) {
      final tanggal = DateTime.tryParse(entry.key);
      if (tanggal == null || kunciTanggal(tanggal) != entry.key) {
        throw FormatException('Tanggal pengecualian ${entry.key} tidak valid.');
      }
      if (entry.value is! List) {
        throw FormatException('Jadwal khusus ${entry.key} tidak valid.');
      }
      result[entry.key] = (entry.value as List).map(_bacaJadwal).toList();
    }
    return result;
  }

  /// Data lama tidak punya kunci ini, jadi null dianggap kosong.
  static Map<String, List<PengecualianKelas>> _bacaPengecualian(Object? value) {
    if (value == null) return {};
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Daftar pengecualian jadwal tidak valid.');
    }
    final hasil = <String, List<PengecualianKelas>>{};
    for (final entry in value.entries) {
      final tanggal = DateTime.tryParse(entry.key);
      if (tanggal == null || kunciTanggal(tanggal) != entry.key) {
        throw FormatException('Tanggal pengecualian ${entry.key} tidak valid.');
      }
      final raw = entry.value;
      if (raw is! List) {
        throw FormatException('Pengecualian ${entry.key} tidak valid.');
      }
      hasil[entry.key] = [for (final item in raw) _bacaPengecualianItem(item)];
    }
    return hasil;
  }

  static PengecualianKelas _bacaPengecualianItem(Object? item) {
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Data pengecualian tidak valid.');
    }
    final kode = item['kode'];
    final ke = item['keTanggal'];
    if (kode is! String || (ke != null && ke is! String)) {
      throw const FormatException('Data pengecualian tidak valid.');
    }
    return PengecualianKelas(kode: kode, keTanggal: ke as String?);
  }

  static JadwalKuliah _bacaJadwal(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Data mata kuliah tidak valid.');
    }
    return JadwalKuliah.fromJson(value);
  }

  static Map<int, List<JadwalKuliah>> _salinMingguan(
    Map<int, List<JadwalKuliah>> source,
  ) => {
    for (var hari = DateTime.monday; hari <= DateTime.sunday; hari++)
      hari: List<JadwalKuliah>.of(source[hari] ?? const <JadwalKuliah>[]),
  };

  static Map<String, List<JadwalKuliah>> _salinKhusus(
    Map<String, List<JadwalKuliah>> source,
  ) => {
    for (final entry in source.entries)
      entry.key: List<JadwalKuliah>.of(entry.value),
  };

  static Map<String, List<PengecualianKelas>> _salinPengecualian(
    Map<String, List<PengecualianKelas>> source,
  ) => {
    for (final entry in source.entries)
      entry.key: List<PengecualianKelas>.of(entry.value),
  };

  static void _urutkanMingguan(Map<int, List<JadwalKuliah>> mingguan) {
    for (final daftar in mingguan.values) {
      daftar.sort((a, b) => a.mulai.compareTo(b.mulai));
    }
  }

  static void _validasiMingguan(Map<int, List<JadwalKuliah>> mingguan) {
    final kode = <String>{};
    for (final daftar in mingguan.values) {
      _validasiDaftar(daftar);
      for (final jadwal in daftar) {
        if (!kode.add(jadwal.kode)) {
          throw const FormatException('Kode mata kuliah duplikat.');
        }
      }
    }
  }

  /// Memeriksa seluruh kelas pada satu tanggal: mingguan (tanpa yang
  /// dikecualikan) digabung dengan kelas khusus. Melempar FormatException.
  static void _validasiTanggalPada(
    DateTime tanggal,
    Map<int, List<JadwalKuliah>> mingguan,
    Map<String, List<JadwalKuliah>> khusus,
    Map<String, List<PengecualianKelas>> pengecualian,
  ) {
    final kunci = kunciTanggal(tanggal);
    final dikecualikan = {
      for (final p in pengecualian[kunci] ?? const <PengecualianKelas>[])
        p.kode,
    };
    final daftar = <JadwalKuliah>[
      for (final j in mingguan[tanggal.weekday] ?? const <JadwalKuliah>[])
        if (!dikecualikan.contains(j.kode)) j,
      ...?khusus[kunci],
    ];
    _validasiDaftar(daftar);
  }

  /// Sama seperti [_validasiTanggalPada], tetapi galatnya berupa
  /// ArgumentError dengan pesan yang mudah dibaca pengguna.
  void _validasiTanggalBaru(
    DateTime tanggal,
    Map<String, List<JadwalKuliah>> khusus,
    Map<String, List<PengecualianKelas>> pengecualian,
  ) {
    try {
      _validasiTanggalPada(tanggal, _mingguan, khusus, pengecualian);
    } on FormatException catch (e) {
      final pesan = e.message;
      throw ArgumentError(
        pesan.contains('duplikat')
            ? 'Mata kuliah ini sudah terjadwal pada tanggal tersebut.'
            : pesan.contains('bertabrakan')
            ? 'Jam bertabrakan dengan mata kuliah lain pada tanggal tersebut.'
            : pesan,
      );
    }
  }

  static void _validasiDaftar(List<JadwalKuliah> daftar) {
    final kode = <String>{};
    final nama = <String>{};
    daftar.sort((a, b) => a.mulai.compareTo(b.mulai));
    for (var i = 0; i < daftar.length; i++) {
      final jadwal = daftar[i];
      if (jadwal.kode.trim().isEmpty ||
          jadwal.nama.trim().isEmpty ||
          jadwal.mulai < 0 ||
          jadwal.selesai > 24 * 60 ||
          jadwal.selesai <= jadwal.mulai) {
        throw const FormatException('Data mata kuliah atau jam tidak valid.');
      }
      if (!kode.add(jadwal.kode)) {
        throw const FormatException(
          'Kode mata kuliah duplikat dalam satu hari.',
        );
      }
      if (!nama.add(jadwal.nama.trim())) {
        throw const FormatException(
          'Nama mata kuliah duplikat dalam satu hari.',
        );
      }
      if (i > 0 && jadwal.mulai < daftar[i - 1].selesai) {
        throw const FormatException('Jam mata kuliah saling bertabrakan.');
      }
    }
  }

  static void _validasiHari(int hari) {
    if (hari < DateTime.monday || hari > DateTime.sunday) {
      throw ArgumentError.value(
        hari,
        'hari',
        'Jadwal mingguan berlaku Senin-Minggu.',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
