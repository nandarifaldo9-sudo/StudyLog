# StudyLog — Milestone 2: Navigasi Empat Layar dan State Lintas Layar

Aplikasi catatan perkuliahan Android yang dibangun dengan **Flutter**. Repository ini berisi **Checkpoint Milestone 2 (M2)** proyek StudyLog: navigasi empat layar (Beranda, Daftar, Detail, Form) dengan `Navigator`, serta state lintas layar yang dikelola oleh `ChangeNotifier` + `Provider`, di atas **dashboard berbasis jadwal kuliah hari ini** dan **form catatan** dari M1.

> Tugas UTS kelompok — Program Studi Informatika, Universitas Mulia
> Mata kuliah: Pemrograman Aplikasi Bergerak

---
## Fitur

### Dashboard (Beranda)
- Menampilkan **hanya mata kuliah yang berlangsung hari ini**, mengikuti hari pada perangkat secara real time, lengkap dengan **kode mata kuliah dan jam kuliah**.
- Info hari, tanggal, dan jam yang diperbarui setiap menit dan saat aplikasi dibuka kembali.
- **Status kuliah otomatis** pada setiap card: *Akan datang*, *Sedang berlangsung*, atau *Selesai*, mengikuti jam saat ini.
- **Kartu "Kuliah saat ini"** dengan tombol **CATAT SEKARANG** yang langsung membuka form untuk mata kuliah yang sedang berlangsung, tanpa perlu memilih.
- Setiap mata kuliah punya **card dengan warna khas**, jumlah catatan, dan tombol **TAMBAH CATATAN** (tetap bisa dipakai untuk mata kuliah hari ini yang belum atau sudah selesai).
- Penanda **"Ada draft"** pada mata kuliah yang masih punya catatan belum selesai.
- Daftar **catatan hari ini** (terbaru di atas) dengan warna sesuai mata kuliahnya; **setiap card dapat diketuk** untuk membuka layar Detail.
- Tombol **LIHAT SEMUA CATATAN** untuk membuka layar Daftar (selalu tersedia, termasuk pada Sabtu dan Minggu).
- Pada **Sabtu dan Minggu** tidak ada jadwal, sehingga dashboard menampilkan keterangan tidak ada kuliah dan tombol tambah catatan tidak tersedia.

### Daftar Catatan *(baru di M2)*
- Menampilkan **semua catatan dari seluruh mata kuliah** (terbaru di atas) dengan warna sesuai mata kuliahnya.
- Mengetuk sebuah card membuka layar **Detail** catatan tersebut.
- Menampilkan keterangan kosong jika belum ada catatan.
- Daftar **diperbarui otomatis** ketika catatan ditambah, diubah, atau dihapus dari layar mana pun.

### Detail Catatan *(baru di M2)*
- Menampilkan mata kuliah (berwarna), judul, hari dan jam pembuatan, serta **isi lengkap** catatan.
- Tombol **UBAH** membuka form dalam mode ubah, dengan judul dan isi terisi dari catatan yang dipilih.
- Tombol **HAPUS** menampilkan **dialog konfirmasi** (BATAL / HAPUS). Jika disetujui, catatan dihapus dan aplikasi kembali ke layar sebelumnya.
- Perubahan langsung terlihat di layar Detail, Daftar, dan Beranda.

### Form Catatan (Tambah dan Ubah)
- **Tanpa pilihan mata kuliah.** Mata kuliah otomatis mengikuti card yang dipilih di dashboard (atau catatan yang diubah) dan ditampilkan pada header form.
- Dua input: **judul catatan** dan **isi catatan**.
- **Validasi**: field kosong dan field yang hanya berisi spasi ditolak (memakai `trim()`).
- **Umpan balik**: `SnackBar` untuk status gagal maupun berhasil (disimpan, diperbarui, dihapus), serta card hasil di dashboard.
- **Draft otomatis** per mata kuliah pada mode tambah, tersimpan saat mengetik, saat keluar dari halaman, dan saat aplikasi ditinggalkan. Draft dipulihkan ketika form dibuka lagi, walau aplikasi sempat ditutup total. Mode ubah tidak memakai draft.

### Navigasi dan State
- Alur layar memakai `Navigator.push` (membuka layar) dan `Navigator.pop` (kembali), sehingga **back stack** berjalan sesuai urutan halaman:

```text
Beranda ──► Form (tambah)
   │
   └──► Daftar ──► Detail ──► Form (ubah)
```

- State catatan dipusatkan pada `CatatanStore` (`ChangeNotifier`). `ChangeNotifierProvider` membagikan satu objek store ke seluruh aplikasi, dan layar yang memakai `context.watch` dibangun ulang setiap `notifyListeners()` dipanggil.
- Form, Daftar, dan Detail tidak lagi mengelola datanya sendiri-sendiri, sehingga sumber datanya konsisten.

### Catatan tentang Lifecycle
- Daftar catatan disimpan **sementara di memori** (RAM). Rotasi layar dan hot reload tidak menghapus data, tetapi **full restart atau menutup total aplikasi menghapus seluruh catatan**.
- **Draft** tetap ada setelah aplikasi ditutup total karena disimpan di `shared_preferences`.
- Penyimpanan permanen untuk catatan akan dikerjakan pada M3 dengan SQLite.

---

## Struktur Proyek

```text
studylogform/
├── android/                         # Konfigurasi platform Android (dibuat otomatis)
├── lib/
│   ├── main.dart                    # Titik masuk aplikasi + ChangeNotifierProvider + MaterialApp
│   ├── data/
│   │   ├── jadwal.dart              # Jadwal kuliah, jam, status (akan datang/berlangsung/selesai)
│   │   └── draft_keys.dart          # Kunci penyimpanan draft per mata kuliah
│   ├── models/
│   │   └── catatan.dart             # Model HasilCatatan (id, mata kuliah, judul, isi, waktu)
│   ├── state/
│   │   └── catatan_store.dart       # CatatanStore (ChangeNotifier): tambah, ubah, hapus, cari
│   ├── theme/
│   │   └── warna_mata_kuliah.dart   # Warna unik setiap mata kuliah
│   ├── screens/
│   │   ├── dashboard_page.dart      # Beranda: jam real time, mata kuliah & catatan hari ini
│   │   ├── daftar_catatan_page.dart # Daftar: semua catatan
│   │   ├── detail_catatan_page.dart # Detail: isi catatan, tombol UBAH dan HAPUS
│   │   └── tambah_catatan_page.dart # Form judul + isi (mode tambah/ubah), validasi, draft otomatis
│   └── widgets/
│       ├── mata_kuliah_card.dart    # Card mata kuliah + tombol tambah catatan
│       └── catatan_card.dart        # Card hasil berwarna (dapat diketuk)
├── test/
│   ├── widget_test.dart             # Pengujian widget M1 (14 skenario)
│   ├── jadwal_test.dart             # Pengujian unit jadwal dan status (7 skenario)
│   ├── catatan_store_test.dart      # Pengujian unit CatatanStore (4 skenario)
│   └── navigasi_test.dart           # Pengujian navigasi, ubah, dan hapus (4 skenario)
├── docs/
│   └── screenshots/                 # Bukti screenshot untuk laporan
├── pubspec.yaml                     # Dependensi proyek (provider, shared_preferences)
└── README.md
```
