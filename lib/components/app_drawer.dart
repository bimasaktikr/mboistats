import 'package:flutter/material.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:mboistats/theme.dart';
// --- TAMBAHAN IMPORT ---
import 'package:provider/provider.dart';
// --- AKHIR TAMBAHAN ---

class AppDrawer extends StatefulWidget {
  // --- PERBAIKAN DI SINI ---
  // Hapus parameter 'onRefreshNeeded'
  // final VoidCallback onRefreshNeeded;

  const AppDrawer({
    Key? key,
    // required this.onRefreshNeeded, // <-- HAPUS INI
  }) : super(key: key);
  // --- AKHIR PERBAIKAN ---

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _username = 'Tamu';
  String _email = 'Selamat datang!';

  @override
  void initState() {
    super.initState();
    // Kita bisa ambil authService dari context
    // karena kita sudah menyediakannya di main.dart
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    // --- PERBAIKAN: Ambil service dari context ---
    final authService = context.read<SupabaseAuthService>();
    // --- AKHIR PERBAIKAN ---
    
    final username = authService.getUsername();
    final email = authService.getEmail();
    if (mounted) {
      setState(() {
        _username = username ?? 'Tamu';
        _email = email ?? 'Selamat datang!';
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    // --- PERBAIKAN: Ambil service dari context ---
    final authService = context.read<SupabaseAuthService>();
    // --- AKHIR PERBAIKAN ---

    await authService.signOut();

    // HAPUS: widget.onRefreshNeeded();
    // Tidak perlu lagi, provider akan menangani update UI secara otomatis

    if (navigator.canPop()) {
      navigator.pop(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    String avatarLetter =
        _username.isNotEmpty ? _username[0].toUpperCase() : 'T';

    return Drawer(
      child: Column(
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              _username,
              style: bold18.copyWith(color: Colors.white),
            ),
            accountEmail: Text(
              _email,
              style: regular14.copyWith(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                avatarLetter,
                style: bold18.copyWith(fontSize: 32, color: blue1),
              ),
            ),
            decoration: BoxDecoration(
              color: blue1,
            ),
          ),
          ListTile(
            leading: Icon(Icons.favorite, color: Colors.red[600]),
            title: Text('Favorit Saya', style: regular14.copyWith(color: dark1)),
            onTap: () async {
              Navigator.pop(context); 
              
              // --- PERBAIKAN: Hapus 'await' dan 'onRefreshNeeded' ---
              // Cukup navigasi saja. Provider akan mengurus sisanya.
              Navigator.pushNamed(context, '/favorit');
              // HAPUS: final dynamic result = await ...
              // HAPUS: if (result == true) { ... }
              // --- AKHIR PERBAIKAN ---
            },
          ),
          const Expanded(
            child: SizedBox(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout, color: Colors.white), // <-- Tambahkan ikon
              label: Text(
                'Logout',
                style: semibold14.copyWith(color: Colors.white),
              ),
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: red, 
                minimumSize: const Size(double.infinity, 48), 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2, 
              ),
            ),
          ),
        ],
      ),
    );
  }
}