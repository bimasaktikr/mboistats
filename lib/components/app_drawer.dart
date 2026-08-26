import 'package:flutter/material.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:mboistats/theme.dart';
// --- TAMBAHAN IMPORT ---
import 'package:provider/provider.dart';

class AppDrawer extends StatefulWidget {

  const AppDrawer({
    Key? key,
  }) : super(key: key);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _username = 'Tamu';
  String _email = 'Selamat datang!';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authService = context.read<SupabaseAuthService>();
    
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
    final authService = context.read<SupabaseAuthService>();

    await authService.signOut();

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
              Navigator.pushNamed(context, '/favorit');
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