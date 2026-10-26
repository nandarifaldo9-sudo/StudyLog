import 'package:flutter_test/flutter_test.dart';
import 'package:studylogform/data/jadwal.dart';
import 'package:studylogform/theme/warna_mata_kuliah.dart';

void main() {
  const sesi = JadwalKuliah(
    kode: '111500',
    nama: 'Sistem Manajemen Basis Data',
    mulai: 19 * 60,
    selesai: 20 * 60 + 30,
  );

  group('statusKuliah', () {
    test('sebelum jam mulai: akan datang', () {
      expect(
        statusKuliah(sesi, DateTime(2026, 10, 26, 18, 59)),
        StatusKuliah.akanDatang,
      );
    });

    test('tepat jam mulai: berlangsung', () {
      expect(
        statusKuliah(sesi, DateTime(2026, 10, 26, 19, 0)),
        StatusKuliah.berlangsung,
      );
    });

    test('semenit sebelum selesai: masih berlangsung', () {
      expect(
        statusKuliah(sesi, DateTime(2026, 10, 26, 20, 29)),
        StatusKuliah.berlangsung,
      );
    });

    test('tepat jam selesai: selesai', () {
      expect(
        statusKuliah(sesi, DateTime(2026, 10, 26, 20, 30)),
        StatusKuliah.selesai,
      );
    });
  });

  group('jadwalKuliah', () {
    test('tidak ada jadwal pada Sabtu dan Minggu', () {
      expect(jadwalKuliah[DateTime.saturday], isNull);
      expect(jadwalKuliah[DateTime.sunday], isNull);
    });

    test('setiap mata kuliah punya warna dan warnanya unik', () {
      final semua = [
        for (final hari in jadwalKuliah.values) ...hari.map((j) => j.nama),
      ];
      expect(semua.toSet().length, semua.length);
      for (final nama in semua) {
        expect(warnaMataKuliah.containsKey(nama), isTrue, reason: nama);
      }
      expect(warnaMataKuliah.values.toSet().length, warnaMataKuliah.length);
    });

    test('sesi dalam satu hari tidak bertabrakan', () {
      for (final hari in jadwalKuliah.values) {
        for (var i = 1; i < hari.length; i++) {
          expect(hari[i].mulai >= hari[i - 1].selesai, isTrue);
        }
      }
    });
  });
}
