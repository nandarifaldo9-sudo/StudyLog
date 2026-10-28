# StudyLog — Milestone 3: Penyimpanan SQLite dan CRUD

Aplikasi catatan perkuliahan Android (Flutter). M3 mengganti penyimpanan di memori (M2)
dengan **SQLite**, sehingga catatan **tetap ada setelah aplikasi ditutup**. Dashboard jadwal,
navigasi 4 layar, validasi, dan draft otomatis dari M1/M2 tidak diubah.

> Program Studi Informatika, Universitas Mulia — Pemrograman Aplikasi Bergerak

## Yang berubah dari M2

| Berkas | Perubahan |
|--------|-----------|
| `lib/data/database_helper.dart` | **Baru.** Membuka `studylog.db`, membuat tabel `catatan` |
| `lib/data/catatan_repository.dart` | **Baru.** Kontrak CRUD + `SqliteCatatanRepository` |
| `lib/data/memori_catatan_repository.dart` | **Baru.** Versi memori dengan kontrak sama (untuk pengujian) |
| `lib/models/catatan.dart` | + `toMap()` / `fromMap()` |
| `lib/state/catatan_store.dart` | Memakai repository; `tambah/ubah/hapus` kini `Future`; + `muat()`, `galat` |
| `lib/main.dart` | Store dibuat dengan repository SQLite, lalu `muat()` saat app dibuka |
| `lib/screens/tambah_catatan_page.dart` | `SIMPAN` menunggu SQLite (`await`), tombol nonaktif saat menyimpan, tampil galat |
| `lib/screens/detail_catatan_page.dart` | `HAPUS` menunggu SQLite, tampil galat bila gagal |
| `lib/screens/daftar_catatan_page.dart` | Menampilkan pesan bila memuat database gagal |
| `pubspec.yaml` | + `sqflite`, `path` |
| `test/` | Test store jadi async, + `catatan_model_test.dart`, + tes persistensi |

Tabel `catatan`: `id` (PK, AUTOINCREMENT), `mata_kuliah`, `judul`, `isi`, `waktu` (teks ISO 8601).

Alur data: **Layar → CatatanStore → CatatanRepository → SQLite.** Layar tidak menulis SQL.
Draft otomatis tetap memakai `shared_preferences` (terpisah dari database).

## Menjalankan

```powershell
flutter pub get
flutter analyze
flutter test
flutter run          # pilih emulator/HP Android (sqflite tidak jalan di Chrome/Windows)
```

## Matriks uji manual (isi kolom Hasil)

| ID | Skenario | Langkah | Yang diharapkan | Hasil |
|----|----------|---------|-----------------|-------|
| T1 | Form kosong | TAMBAH CATATAN → SIMPAN | Pesan "wajib diisi" | |
| T2 | Hanya spasi | Isi judul dengan spasi → SIMPAN | Ditolak | |
| T3 | CREATE | Isi judul + isi → SIMPAN | Snackbar sukses, catatan tampil di dashboard dan Daftar | |
| T4 | READ | LIHAT SEMUA CATATAN → buka catatan | Detail cocok dengan input | |
| T5 | UPDATE | Detail → UBAH → ganti judul → SIMPAN PERUBAHAN | Detail dan daftar berubah | |
| T6 | DELETE batal | HAPUS → BATAL | Catatan tetap ada | |
| T7 | DELETE setuju | HAPUS → HAPUS | Catatan hilang | |
| T8 | Persistensi | Tutup total app (swipe dari recent apps), buka lagi | Semua catatan masih ada | |

## Bukti untuk pengumpulan

Screenshot (dashboard, form, daftar, detail, dialog hapus), video demo CRUD + buka ulang app,
commit Git `M3 — SQLite dan CRUD`.
