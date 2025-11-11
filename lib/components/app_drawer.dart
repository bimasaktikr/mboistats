import 'package:flutter/material.dart';
import 'package:mboistats/services/auth_service_custom.dart';
import 'package:mboistats/theme.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onRefreshNeeded;

  const AppDrawer({
    Key? key,
    required this.onRefreshNeeded,
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  // Gunakan instance singleton
  final AuthServiceCustom _authService = AuthServiceCustom.instance;
  String _username = 'Tamu';
  String _email = 'Selamat datang!';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await _authService.getUsername();
    final email = await _authService.getEmail();
    if (mounted) {
      setState(() {
        _username = username ?? 'Tamu';
        _email = email ?? 'Selamat datang!';
      });
    }
  }

  // Fungsi untuk logout
  Future<void> _logout(BuildContext context) async {
    // 1. Simpan navigator SEBELUM melakukan operasi async
    final navigator = Navigator.of(context);

    // 2. Panggil fungsi signout dari service
    await _authService.signOut();

    // 3. Beri tahu HomePage untuk me-refresh carousel (menghilangkan ikon hati)
    widget.onRefreshNeeded();

    // 4. Cukup tutup drawer
    if (navigator.canPop()) {
      navigator.pop(); // HANYA tutup drawer
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
              Navigator.pop(context); // Tutup drawer
              final dynamic result =
                  await Navigator.pushNamed(context, '/favorit');
              // Jika ada perubahan di halaman favorit (misal, item dihapus),
              // beri tahu HomePage untuk refresh juga.
              if (result == true) {
                widget.onRefreshNeeded();
              }
            },
          ),

          // --- PERUBAHAN: Tombol Logout Modern ---
          // Gunakan Expanded untuk mendorong tombol ke bawah
          const Expanded(
            child: SizedBox(),
          ),

          // Tombol Logout baru yang lebih modern
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              label: Text(
                'Logout',
                style: semibold14.copyWith(color: Colors.white),
              ),
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: red, // Warna merah untuk aksi "destruktif"
                minimumSize: const Size(double.infinity, 48), // Lebar penuh
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2, // Sedikit bayangan
              ),
            ),
          ),
          // Hapus ListTile Logout yang lama
          // const Divider(),
          // const Spacer(),
          // ListTile(
          //   leading: Icon(Icons.logout, color: dark2),
          //   title: Text('Logout', style: regular14.copyWith(color: dark1)),
          //   onTap: () => _logout(context),
          // ),
          // const SizedBox(height: 20),
          // --- AKHIR PERUBAHAN ---
        ],
      ),
    );
  }
}