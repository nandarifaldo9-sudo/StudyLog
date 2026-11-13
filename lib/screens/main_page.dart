import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'jadwal_page.dart';
import 'daftar_catatan_page.dart';
import 'tambah_dari_daftar.dart';

class MainPage extends StatefulWidget {
  final DateTime Function()? now;
  const MainPage({super.key, this.now});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    DashboardPage(now: widget.now),
    const JadwalPage(),
    DaftarCatatanPage(now: widget.now),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () {
          // Panggil fungsi yang akan mengecek jadwal hari ini
          bukaFormDariDaftar(
            context,
            pesanSukses: 'Catatan berhasil disimpan',
            now: widget.now,
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildTabItem(Icons.home_outlined, Icons.home, 'Home', 0),
            _buildTabItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Jadwal', 1),
            const SizedBox(width: 48),
            _buildTabItem(Icons.list_alt_outlined, Icons.list_alt, 'Catatan', 2),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData iconOutlined, IconData iconFilled, String label, int index) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? iconFilled : iconOutlined, color: color),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}