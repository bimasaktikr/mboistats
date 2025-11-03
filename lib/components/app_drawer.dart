import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  // --- TAMBAHKAN: Fungsi callback ---
  final VoidCallback onRefreshNeeded;
  
  const AppDrawer({
    Key? key, 
    required this.onRefreshNeeded, // Wajibkan callback
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _username = 'Tamu'; // Default username

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // Memuat username dari SharedPreferences
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    // Cek mounted untuk keamanan async
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'Tamu';
      });
    }
  }

  // Fungsi untuk logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
    await prefs.remove('username');

    // Navigasi ke halaman login dan hapus semua halaman sebelumnya
    // Pastikan context masih valid
    if (Navigator.of(context).canPop()) {
       Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          // Header Drawer yang lebih bagus
          UserAccountsDrawerHeader(
            accountName: Text(
              _username,
              style: bold18.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              _username == 'admin' ? 'admin@bps.go.id' : 'Selamat datang!',
              style: regular14.copyWith(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'T',
                style: bold18.copyWith(fontSize: 32, color: blue1),
              ),
            ),
            decoration: BoxDecoration(
              color: blue1, // Gunakan warna tema Anda
            ),
          ),
          
          // Menu Favorit
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.red[600]),
            title: Text('Favorit Saya', style: regular14.copyWith(color: dark1)),
            onTap: () async {
              // --- PERBAIKAN DI SINI ---
              Navigator.pop(context); // Tutup drawer
              
              // Tunggu hasil dari halaman favorit
              final dynamic result = await Navigator.pushNamed(context, '/favorit');
              
              // Jika hasilnya 'true' (artinya ada perubahan), panggil callback
              if (result == true) {
                widget.onRefreshNeeded(); // Panggil fungsi refresh dari HomePage
              }
              // --- AKHIR PERUBAHAN ---
            },
          ),
          
          const Divider(),

          // Spacer agar Logout menempel di bawah
          const Spacer(), 

          // Menu Logout
          ListTile(
            leading: Icon(Icons.logout, color: dark2),
            title: Text('Logout', style: regular14.copyWith(color: dark1)),
            onTap: () => _logout(context),
          ),
          
          // Padding bawah agar tidak terlalu mepet
          const SizedBox(height: 20), 
        ],
      ),
    );
  }
}

