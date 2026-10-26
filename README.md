# StudyLog — Milestone 1: Dashboard Jadwal dan Formulir Catatan

Aplikasi catatan perkuliahan Android yang dibangun dengan **Flutter**. Repository ini berisi **Checkpoint Milestone 1 (M1)** proyek StudyLog: form interaktif dengan input, validasi, `setState`, dan umpan balik pengguna, yang dipadukan dengan **dashboard berbasis jadwal kuliah hari ini**.

> Tugas UTS kelompok — Program Studi Informatika, Universitas Mulia
> Mata kuliah: Pemrograman Aplikasi Bergerak

---
## Fitur

### Dashboard
- Menampilkan **hanya mata kuliah yang berlangsung hari ini**, mengikuti hari pada perangkat secara real time, lengkap dengan **kode mata kuliah dan jam kuliah**.
- Info hari, tanggal, dan jam yang diperbarui setiap menit dan saat aplikasi dibuka kembali.
- **Status kuliah otomatis** pada setiap card: *Akan datang*, *Sedang berlangsung*, atau *Selesai*, mengikuti jam saat ini.
- **Kartu "Kuliah saat ini"** dengan tombol **CATAT SEKARANG** yang langsung membuka form untuk mata kuliah yang sedang berlangsung, tanpa perlu memilih.
- Setiap mata kuliah punya **card dengan warna khas**, jumlah catatan, dan tombol **TAMBAH CATATAN** (tetap bisa dipakai untuk mata kuliah hari ini yang belum atau sudah selesai).
- Penanda **"Ada draft"** pada mata kuliah yang masih punya catatan belum selesai.
- Daftar **catatan hari ini** (terbaru di atas) dengan warna sesuai mata kuliahnya.
- Pada **Sabtu dan Minggu** tidak ada jadwal, sehingga dashboard menampilkan keterangan tidak ada kuliah dan tombol tambah catatan tidak tersedia.

### Form Tambah Catatan
- **Tanpa pilihan mata kuliah.** Mata kuliah otomatis mengikuti card yang dipilih di dashboard dan ditampilkan pada header form.
- Dua input: **judul catatan** dan **isi catatan**.
- **Validasi**: field kosong dan field yang hanya berisi spasi ditolak (memakai `trim()`).
- **Umpan balik**: `SnackBar` untuk status gagal maupun berhasil, serta card hasil di dashboard.
- **Draft otomatis** per mata kuliah, tersimpan saat mengetik, saat keluar dari halaman, dan saat aplikasi ditinggalkan. Draft dipulihkan ketika form dibuka lagi, walau aplikasi sempat ditutup total.

---

## Struktur Proyek

```text
studylogform/
├── android/                         # Konfigurasi platform Android (dibuat otomatis)
├── lib/
│   ├── main.dart                    # Titik masuk aplikasi + MaterialApp
│   ├── data/
│   │   ├── jadwal.dart              # Jadwal kuliah, jam, status (akan datang/berlangsung/selesai)
│   │   └── draft_keys.dart          # Kunci penyimpanan draft per mata kuliah
│   ├── models/
│   │   └── catatan.dart             # Model HasilCatatan
│   ├── theme/
│   │   └── warna_mata_kuliah.dart   # Warna unik setiap mata kuliah
│   ├── screens/
│   │   ├── dashboard_page.dart      # Dashboard: jam real time, mata kuliah & catatan hari ini
│   │   └── tambah_catatan_page.dart # Form judul + isi, validasi, draft otomatis
│   └── widgets/
│       ├── mata_kuliah_card.dart    # Card mata kuliah + tombol tambah catatan
│       └── catatan_card.dart        # Card hasil berwarna
├── test/
│   ├── widget_test.dart             # Pengujian widget (14 skenario)
│   └── jadwal_test.dart             # Pengujian unit jadwal dan status (7 skenario)
├── docs/
│   └── screenshots/                 # Bukti screenshot untuk laporan
├── pubspec.yaml                     # Dependensi proyek
└── README.md
