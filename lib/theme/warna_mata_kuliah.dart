import 'package:flutter/material.dart';

/// Satu warna unik untuk setiap mata kuliah.
const Map<String, Color> warnaMataKuliah = {
  'Sistem Manajemen Basis Data': Color(0xFF1565C0), // biru
  'Teknologi Aplikasi Bergerak': Color(0xFF00897B), // teal
  'Penalaran Komputer': Color(0xFFEF6C00), // oranye
  'Simulasi dan Game Komputer': Color(0xFF6A1B9A), // ungu
  'Kriptografi': Color(0xFFC62828), // merah
  'Penulisan dan Publikasi Ilmiah': Color(0xFF2E7D32), // hijau
  'Jaringan Nirkabel': Color(0xFFAD1457), // pink
  'Pemrograman Aplikasi Bergerak': Color(0xFF5D4037), // coklat
};

Color warnaUntuk(String mataKuliah) =>
    warnaMataKuliah[mataKuliah] ?? Colors.grey;
