import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studylogform/data/memori_catatan_repository.dart';
import 'package:studylogform/main.dart';
import 'package:studylogform/models/catatan.dart';
import 'package:studylogform/viewmodels/catatan_view_model.dart';
import 'package:studylogform/widgets/catatan_card.dart';

void main() {
  late CatatanViewModel vm;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final repo = MemoriCatatanRepository();
    await repo.tambah(
      mataKuliah: 'Kriptografi',
      judul: 'A',
      isi: 'a',
      waktu: DateTime(2026, 10, 26, 19),
    );
    await repo.tambah(
      mataKuliah: 'Kriptografi',
      judul: 'B',
      isi: 'b',
      waktu: DateTime(2026, 10, 27, 19),
    );
    await repo.tambah(
      mataKuliah: 'Jaringan Nirkabel',
      judul: 'C',
      isi: 'c',
      waktu: DateTime(2026, 10, 28, 19),
    );
    vm = CatatanViewModel(repo);
    await vm.muat();
  });

  List<String> judul(List<HasilCatatan> catatan) =>
      catatan.map((c) => c.judul).toList();

  test('terbaru: catatan paling baru di atas', () {
    expect(judul(vm.telusuri('')), ['C', 'B', 'A']);
  });

  test('terlama: urutan dibalik', () {
    expect(judul(vm.telusuri('', urutan: UrutanCatatan.terlama)), [
      'A',
      'B',
      'C',
    ]);
  });

  test('urutan tetap berlaku bersama pencarian', () {
    expect(judul(vm.telusuri('Kriptografi', urutan: UrutanCatatan.terlama)), [
      'A',
      'B',
    ]);
    expect(judul(vm.telusuri('Kriptografi')), ['B', 'A']);
  });

  testWidgets('menu urutan mengubah hasil dan bekerja bersama pencarian', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = MemoriCatatanRepository();
    await repo.tambah(
      mataKuliah: 'Kriptografi',
      judul: 'A',
      isi: 'a',
      waktu: DateTime(2026, 10, 26, 19),
    );
    await repo.tambah(
      mataKuliah: 'Kriptografi',
      judul: 'B',
      isi: 'b',
      waktu: DateTime(2026, 10, 27, 19),
    );
    await repo.tambah(
      mataKuliah: 'Jaringan Nirkabel',
      judul: 'C',
      isi: 'c',
      waktu: DateTime(2026, 10, 28, 19),
    );
    await tester.pumpWidget(
      StudyLogApp(now: () => DateTime(2026, 10, 28, 8), repository: repo),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('LIHAT SEMUA CATATAN'));
    await tester.pumpAndSettle();

    List<String> judulKartu() => tester
        .widgetList<CatatanCard>(find.byType(CatatanCard))
        .map((card) => card.data.judul)
        .toList();

    expect(judulKartu(), ['C', 'B', 'A']);
    expect(find.text('Total 3 catatan • Terbaru dulu'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menuUrutan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terlama dulu'));
    await tester.pumpAndSettle();
    expect(judulKartu(), ['A', 'B', 'C']);
    expect(find.text('Total 3 catatan • Terlama dulu'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('kolomCari')), 'Kriptografi');
    await tester.pumpAndSettle();
    expect(judulKartu(), ['A', 'B']);
    expect(find.text('2 catatan ditemukan'), findsOneWidget);

    await tester.tap(find.byKey(const Key('menuUrutan')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terbaru dulu'));
    await tester.pumpAndSettle();
    expect(judulKartu(), ['B', 'A']);
    expect(find.text('Total 3 catatan • Terbaru dulu'), findsOneWidget);
  });
}
