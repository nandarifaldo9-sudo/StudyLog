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
| `lib/viewmodels/catatan_view_model.dart` | Memakai repository; `tambah/ubah/hapus` kini `Future`; + `muat()`, `galat` |
| `lib/main.dart` | Store dibuat dengan repository SQLite, lalu `muat()` saat app dibuka |
| `lib/screens/tambah_catatan_page.dart` | `SIMPAN` menunggu SQLite (`await`), tombol nonaktif saat menyimpan, tampil galat |
| `lib/screens/detail_catatan_page.dart` | `HAPUS` menunggu SQLite, tampil galat bila gagal |
| `lib/screens/daftar_catatan_page.dart` | Menampilkan pesan bila memuat database gagal |
| `pubspec.yaml` | + `sqflite`, `path` |
| `test/` | Test store jadi async, + `catatan_model_test.dart`, + tes persistensi |

Tabel `catatan`: `id` (PK, AUTOINCREMENT), `mata_kuliah`, `judul`, `isi`, `tanggal` (teks ISO 8601).
Database v2: kolom `waktu` (v1) dipindahkan ke `tanggal` lewat migrasi `onUpgrade`.

Alur data: **Layar → CatatanViewModel → CatatanRepository → DatabaseHelper → SQLite.**

## Matriks uji manual (isi kolom Hasil)

| ID | Skenario | Langkah | Ekspektasi | Hasil |
|----|----------|---------|------------|-------|
| T1 — Create | Tambah catatan | Isi judul + isi → SIMPAN | Item baru muncul | |
| T2 — Read | Buka daftar dan detail | LIHAT SEMUA CATATAN → buka catatan | Data sesuai input | |
| T3 — Update | Ubah judul | Detail → UBAH → SIMPAN PERUBAHAN | Data terbaru tampil | |
| T4 — Delete batal | Hapus lalu Batal | HAPUS → BATAL | Item tidak dihapus | |
| T5 — Delete setuju | Hapus lalu konfirmasi | HAPUS → HAPUS | Item hilang | |
| T6 — Persistence | Tutup total & buka lagi | Swipe dari recent apps, buka lagi | Data masih tersedia | |
| T7 — Validasi | Simpan field kosong | SIMPAN dengan judul kosong | Pesan validasi tampil | |

## Bukti untuk pengumpulan

Screenshot (dashboard, form, daftar, detail, dialog hapus), video demo CRUD + buka ulang app,
commit Git `M3 — SQLite dan CRUD`.
