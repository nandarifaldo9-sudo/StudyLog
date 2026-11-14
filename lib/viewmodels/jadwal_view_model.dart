import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/jadwal.dart';

class JadwalViewModel extends ChangeNotifier {
  static const _kunciPenyimpanan = 'jadwal_kuliah_mingguan_v1';

  Map<int, List<JadwalKuliah>> _mingguan = _salinMingguan(jadwalKuliah);
  Map<String, List<JadwalKuliah>> _khususTanggal = {};
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

  List<JadwalKuliah> jadwalUntukTanggal(DateTime tanggal) {
    final khusus = kelasKhususUntukTanggal(tanggal);
    if (namaHariLibur(tanggal) != null) return khusus;
    final hasil = [...jadwalUntukHari(tanggal.weekday), ...khusus];
    hasil.sort((a, b) => a.mulai.compareTo(b.mulai));
    return List.unmodifiable(hasil);
  }

  List<JadwalKuliah> kelasKhususUntukTanggal(DateTime tanggal) =>
      List.unmodifiable(
        _khususTanggal[kunciTanggal(tanggal)] ?? const <JadwalKuliah>[],
      );

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
        _validasiMingguan(mingguan);
        for (final entry in khusus.entries) {
          final tanggal = DateTime.parse(entry.key);
          final jadwalTanggal = <JadwalKuliah>[
            if (namaHariLibur(tanggal) == null) ...mingguan[tanggal.weekday]!,
            ...entry.value,
          ];
          _validasiDaftar(jadwalTanggal);
          _validasiDaftar(entry.value);
        }
        _mingguan = mingguan;
        _khususTanggal = khusus;
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

  Future<void> hapusMataKuliah(int hari, String kode) =>
      _serialkan(() async {
    _validasiHari(hari);
    final mingguan = _salinMingguan(_mingguan);
    final daftar = mingguan[hari]!;
    final jumlahAwal = daftar.length;
    daftar.removeWhere((jadwal) => jadwal.kode == kode);
    if (daftar.length == jumlahAwal) {
      throw StateError('Mata kuliah tidak ditemukan pada hari tersebut.');
    }
    await _simpan(mingguan, _khususTanggal);
  });

  Future<void> tambahKelasPadaTanggal(
    DateTime tanggal,
    JadwalKuliah jadwal,
  ) => _serialkan(() async {
    final khusus = _salinKhusus(_khususTanggal);
    final daftar = khusus.putIfAbsent(kunciTanggal(tanggal), () => []);
    if (daftar.any((item) => item.kode == jadwal.kode)) {
      throw ArgumentError('Kode mata kuliah sudah digunakan pada tanggal ini.');
    }
    daftar.add(jadwal);
    _validasiDaftar(daftar);
    if (namaHariLibur(tanggal) == null) {
      _validasiDaftar([...jadwalUntukHari(tanggal.weekday), ...daftar]);
    }
    await _simpan(_mingguan, khusus);
  });

  Future<void> hapusKelasPadaTanggal(DateTime tanggal, String kode) =>
      _serialkan(() async {
    final khusus = _salinKhusus(_khususTanggal);
    final daftar = khusus[kunciTanggal(tanggal)];
    if (daftar == null) {
      throw StateError('Kelas khusus tidak ditemukan pada tanggal tersebut.');
    }
    final jumlahAwal = daftar.length;
    daftar.removeWhere((j) => j.kode == kode);
    if (daftar.length == jumlahAwal) {
      throw StateError('Kelas khusus tidak ditemukan pada tanggal tersebut.');
    }
    if (daftar.isEmpty) khusus.remove(kunciTanggal(tanggal));
    await _simpan(_mingguan, khusus);
  });

  Future<void> tambahKelasHariLibur(DateTime tanggal, JadwalKuliah jadwal) =>
      tambahKelasPadaTanggal(tanggal, jadwal);

  Future<void> hapusKelasHariLibur(DateTime tanggal, String kode) =>
      hapusKelasPadaTanggal(tanggal, kode);

  List<JadwalKuliah> jadwalKhususHariLibur(DateTime tanggal) =>
      kelasKhususUntukTanggal(tanggal);

  Future<void> _simpan(
    Map<int, List<JadwalKuliah>> mingguan,
    Map<String, List<JadwalKuliah>> khusus,
  ) async {
    if (_galat != null) {
      throw StateError('Jadwal harus berhasil dimuat sebelum diubah.');
    }
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
      }),
    );
    if (!berhasil) throw StateError('Jadwal gagal disimpan ke perangkat.');
    _mingguan = mingguan;
    _khususTanggal = khusus;
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
    if (hari < DateTime.monday || hari > DateTime.saturday) {
      throw ArgumentError.value(
        hari,
        'hari',
        'Jadwal mingguan berlaku Senin-Sabtu.',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
