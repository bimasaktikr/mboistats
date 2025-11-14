import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart'; // <-- Impor tema untuk warna

class Footer extends StatefulWidget {
  const Footer({Key? key}) : super(key: key);

  @override
  _FooterState createState() => _FooterState();
}

class _FooterState extends State<Footer> {
  int _selectedIndex = 0; // Indeks awal (Beranda)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRoute = ModalRoute.of(context)!.settings.name;
    if (currentRoute == '/berita') {
      _selectedIndex = 1;
    } else if (currentRoute == '/contact') {
      _selectedIndex = 2;
    } else {
      _selectedIndex = 0;
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed('/main');
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed('/berita');
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed('/contact');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0),

        decoration: BoxDecoration(
          color: Colors.white, // Latar belakang putih SOLID
          borderRadius:
              BorderRadius.circular(20.0), // Sudut yang membulat
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1), // Bayangan halus
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent, // WAJIB, agar tembus ke Container
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: blue1,
            unselectedItemColor: dark2,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            elevation: 0, // WAJIB, hapus bayangan/latar belakang bawaan
            selectedFontSize: 12.0,
            unselectedFontSize: 12.0,

            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.newspaper_outlined),
                activeIcon: Icon(Icons.newspaper),
                label: 'BRS',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.contacts_outlined),
                activeIcon: Icon(Icons.contacts),
                label: 'Kontak',
              ),
            ],
          ),
        ),
      ),
    );
  }
}