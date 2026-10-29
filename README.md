## Pengembangan pilihan: Pencarian (PjBL)

Fitur pilihan kelompok dari opsi PjBL: **A — Pencarian** kata kunci judul atau mata kuliah.

- Kolom cari ada di layar **Semua Catatan**, dengan tombol hapus pencarian.
- Pencocokan **judul atau mata kuliah**, tidak membedakan huruf besar/kecil. Isi catatan tidak ikut dicari.
- Hasil langsung berubah saat mengetik, dengan jumlah hasil dan pesan saat tidak ada yang cocok.
- Logika ada di `CatatanStore.telusuri()` (penyaringan pada daftar yang sudah dimuat dari SQLite), sehingga layar tidak berisi logika pencarian.
- Berkas: `lib/state/catatan_store.dart` (+ `telusuri`), `lib/screens/daftar_catatan_page.dart` (+ kolom cari), `test/pencarian_test.dart` (baru).

| No | Skenario | Langkah | Yang diharapkan | Hasil |
|----|----------|---------|-----------------|-------|
| 1 | Cari judul | Daftar → ketik sebagian judul | Hanya catatan yang cocok tampil | |
| 2 | Cari mata kuliah | Daftar → ketik sebagian nama mata kuliah | Semua catatan mata kuliah itu tampil | |
| 3 | Tidak ditemukan | Daftar → ketik kata acak | Pesan "Tidak ada catatan yang cocok" | |
| 4 | Hapus pencarian | Tekan ✕ pada kolom cari | Semua catatan tampil kembali | |
| 5 | Pencarian + CRUD | Cari → buka Detail → UBAH/HAPUS → kembali | Daftar hasil ikut diperbarui | |
