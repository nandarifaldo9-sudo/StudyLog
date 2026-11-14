import 'package:shared_preferences/shared_preferences.dart';

/// Kunci penyimpanan draft: satu draft untuk setiap mata kuliah.
String kDraftJudul(String mk) => 'draft_judul_$mk';
String kDraftIsi(String mk) => 'draft_isi_$mk';

/// Mengembalikan nama mata kuliah (dari [daftar]) yang masih punya draft.
Future<Set<String>> muatMataKuliahBerdraft(Iterable<String> daftar) async {
  final prefs = await SharedPreferences.getInstance();
  final ada = <String>{};
  for (final nama in daftar) {
    final judul = prefs.getString(kDraftJudul(nama)) ?? '';
    final isi = prefs.getString(kDraftIsi(nama)) ?? '';
    if (judul.trim().isNotEmpty || isi.trim().isNotEmpty) ada.add(nama);
  }
  return ada;
}