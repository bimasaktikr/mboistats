import 'package:flutter/material.dart';

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

    // Ambil nama rute halaman yang sedang aktif
    final currentRoute = ModalRoute.of(context)!.settings.name;

    // Tentukan _selectedIndex berdasarkan nama rute halaman yang sedang aktif
    if (currentRoute == '/berita') {
      _selectedIndex = 1;
    } else if (currentRoute == '/contact') {
      _selectedIndex = 2;
    } else {
      _selectedIndex = 0; // Default ke Beranda jika tidak ada rute yang cocok
    }
  }

  void _onItemTapped(int index) {
    // Jangan lakukan apa-apa jika halaman sudah aktif
    if (index == _selectedIndex) return; 

    setState(() {
      _selectedIndex = index;
    });

    switch (_selectedIndex) {
      case 0:
        // --- PERUBAHAN DI SINI ---
        // Ganti 'pushNamed' menjadi 'pushReplacementNamed'
        // agar tidak menumpuk halaman
        Navigator.of(context)
            .pushReplacementNamed('/main'); // Ganti dengan rute yang sesuai
        break;
      case 1:
        // --- PERUBAHAN DI SINI ---
        Navigator.of(context)
            .pushReplacementNamed('/berita'); // Ganti dengan rute yang sesuai
        break;
      case 2:
        // --- PERUBAHAN DI SINI ---
        Navigator.of(context)
            .pushReplacementNamed('/contact'); // Ganti dengan rute yang sesuai
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN DI SINI ---
    // Hapus seluruh wrapper 'WillPopScope'
    // Biarkan 'HomePage' yang mengelola tombol 'back'
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: [
        BottomNavigationBarItem(
          icon: Icon(
            Icons.home,
            color: _selectedIndex == 0 ? Colors.blue : null, // Home
          ),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.newspaper_outlined,
            color: _selectedIndex == 1 ? Colors.blue : null, // News
          ),
          label: 'BRS',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            Icons.contacts,
            color: _selectedIndex == 2 ? Colors.blue : null, // Contact
          ),
          label: 'Kontak',
        ),
      ],
    );
    // --- AKHIR PERUBAHAN ---
  }
}
