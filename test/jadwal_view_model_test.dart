import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/data/jadwal.dart';
import 'package:studylogform/viewmodels/jadwal_view_model.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'kelas libur dari format penyimpanan sebelumnya tetap terbaca',
    () async {
      const kelasLibur = JadwalKuliah(
        kode: 'SPC899',
        nama: 'Kelas Libur Lama',
        mulai: 19 * 60,
        selesai: 20 * 60,
      );
      SharedPreferences.setMockInitialValues({
        'jadwal_kuliah_mingguan_v1': jsonEncode({
          'mingguan': {
            for (var hari = DateTime.monday; hari <= DateTime.sunday; hari++)
              '$hari': [
                for (final jadwal
                    in jadwalKuliah[hari] ?? const <JadwalKuliah>[])
                  jadwal.toJson(),
              ],
          },
          'khususHariLibur': {
            '2026-08-17': [kelasLibur.toJson()],
          },
        }),
      });

      final vm = JadwalViewModel();
      await vm.muat();

      expect(
        vm.jadwalUntukTanggal(DateTime(2026, 8, 17)).single.kode,
        kelasLibur.kode,
      );
      expect(vm.galat, isNull);
    },
  );

  test(
    'hari libur kosong kecuali kelas tanggal tersebut di-override',
    () async {
      final vm = JadwalViewModel();
      await vm.muat();
      final tanggalLibur = DateTime(2026, 8, 17);
      final kelas = const JadwalKuliah(
        kode: 'SPC900',
        nama: 'Kelas Pengganti',
        mulai: 19 * 60,
        selesai: 20 * 60,
      );

      expect(vm.jadwalUntukTanggal(tanggalLibur), isEmpty);
      expect(vm.jadwalUntukTanggal(DateTime(2026, 8, 24)), hasLength(2));

      await vm.tambahKelasPadaTanggal(tanggalLibur, kelas);
      expect(vm.jadwalUntukTanggal(tanggalLibur).map((item) => item.kode), [
        kelas.kode,
      ]);

      final dimuatUlang = JadwalViewModel();
      await dimuatUlang.muat();
      expect(
        dimuatUlang.jadwalUntukTanggal(tanggalLibur).map((item) => item.kode),
        [kelas.kode],
      );

      await dimuatUlang.hapusKelasPadaTanggal(tanggalLibur, kelas.kode);
      expect(dimuatUlang.jadwalUntukTanggal(tanggalLibur), isEmpty);
    },
  );

  test(
    'kelas tanggal tertentu ditambahkan tanpa mengubah jadwal mingguan',
    () async {
      final vm = JadwalViewModel();
      await vm.muat();
      final tanggal = DateTime(2026, 10, 26);
      final kelas = const JadwalKuliah(
        kode: 'SPC901',
        nama: 'Kelas Satu Kali',
        mulai: 18 * 60,
        selesai: 18 * 60 + 30,
      );

      await vm.tambahKelasPadaTanggal(tanggal, kelas);
      expect(vm.jadwalUntukTanggal(tanggal), hasLength(3));
      expect(vm.jadwalUntukTanggal(DateTime(2026, 11, 2)), hasLength(2));

      final dimuatUlang = JadwalViewModel();
      await dimuatUlang.muat();
      expect(dimuatUlang.jadwalUntukTanggal(tanggal), hasLength(3));
      expect(
        dimuatUlang.kelasKhususUntukTanggal(tanggal).single.kode,
        kelas.kode,
      );

      await dimuatUlang.hapusKelasPadaTanggal(tanggal, kelas.kode);
      expect(dimuatUlang.jadwalUntukTanggal(tanggal), hasLength(2));
    },
  );

  test(
    'jadwal mingguan yang dipindahkan tersimpan setelah dimuat ulang',
    () async {
      final vm = JadwalViewModel();
      await vm.muat();
      final jadwal = vm.jadwalUntukHari(DateTime.monday).first;

      await vm.simpanMataKuliah(
        hariBaru: DateTime.wednesday,
        hariLama: DateTime.monday,
        kodeLama: jadwal.kode,
        jadwal: jadwal,
      );

      final dimuatUlang = JadwalViewModel();
      await dimuatUlang.muat();
      expect(
        dimuatUlang
            .jadwalUntukHari(DateTime.monday)
            .any((item) => item.kode == jadwal.kode),
        isFalse,
      );
      expect(
        dimuatUlang.jadwalUntukHari(DateTime.wednesday).first.kode,
        jadwal.kode,
      );
    },
  );

  test('jadwal bertabrakan ditolak tanpa mengubah jadwal tersimpan', () async {
    final vm = JadwalViewModel();
    await vm.muat();
    final jadwal = vm.jadwalUntukHari(DateTime.monday).first;

    await expectLater(
      vm.simpanMataKuliah(
        hariBaru: DateTime.tuesday,
        hariLama: DateTime.monday,
        kodeLama: jadwal.kode,
        jadwal: jadwal,
      ),
      throwsFormatException,
    );

    expect(
      vm
          .jadwalUntukHari(DateTime.monday)
          .any((item) => item.kode == jadwal.kode),
      isTrue,
    );
    expect(
      vm
          .jadwalUntukHari(DateTime.tuesday)
          .any((item) => item.kode == jadwal.kode),
      isFalse,
    );
  });

  test(
    'kelas khusus berikutnya mengabaikan kelas mingguan yang masih akan datang',
    () async {
      final vm = JadwalViewModel();
      await vm.muat();
      final hariIni = DateTime(2026, 10, 26);
      const kelasSudahLewat = JadwalKuliah(
        kode: 'SPC902',
        nama: 'Kelas Hari Ini',
        mulai: 18 * 60,
        selesai: 18 * 60 + 30,
      );
      const kelasBesok = JadwalKuliah(
        kode: 'SPC903',
        nama: 'Kelas Besok',
        mulai: 18 * 60,
        selesai: 18 * 60 + 30,
      );

      await vm.tambahKelasPadaTanggal(hariIni, kelasSudahLewat);
      await vm.tambahKelasPadaTanggal(DateTime(2026, 10, 27), kelasBesok);

      expect(
        vm.tanggalKelasKhususBerikutnya(DateTime(2026, 10, 26, 19, 45)),
        DateTime(2026, 10, 27),
      );
      vm.dispose();
    },
  );

  test('penyimpanan jadwal berurutan tidak menimpa perubahan lain', () async {
    final vm = JadwalViewModel();
    await vm.muat();
    final tanggal = DateTime(2026, 10, 26);

    await Future.wait([
      vm.tambahKelasPadaTanggal(
        tanggal,
        const JadwalKuliah(
          kode: 'SPC904',
          nama: 'Kelas Tambahan A',
          mulai: 16 * 60,
          selesai: 16 * 60 + 30,
        ),
      ),
      vm.tambahKelasPadaTanggal(
        tanggal,
        const JadwalKuliah(
          kode: 'SPC905',
          nama: 'Kelas Tambahan B',
          mulai: 17 * 60,
          selesai: 17 * 60 + 30,
        ),
      ),
    ]);

    expect(
      vm.kelasKhususUntukTanggal(tanggal).map((jadwal) => jadwal.kode),
      containsAll(['SPC904', 'SPC905']),
    );
    vm.dispose();
  });

  test('dispose sebelum pemuatan selesai tidak melempar', () async {
    final vm = JadwalViewModel();
    final pemuatan = vm.muat();
    vm.dispose();

    await expectLater(pemuatan, completes);
  });

  test('jadwal rusak tidak tertimpa oleh perubahan baru', () async {
    const dataRusak = '{bukan json';
    SharedPreferences.setMockInitialValues({
      'jadwal_kuliah_mingguan_v1': dataRusak,
    });
    final vm = JadwalViewModel();
    await vm.muat();

    await expectLater(
      vm.tambahKelasPadaTanggal(
        DateTime(2026, 8, 17),
        const JadwalKuliah(
          kode: 'SPC906',
          nama: 'Kelas Baru',
          mulai: 18 * 60,
          selesai: 19 * 60,
        ),
      ),
      throwsStateError,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('jadwal_kuliah_mingguan_v1'),
      dataRusak,
    );
    vm.dispose();
  });
}
