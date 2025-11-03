import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mboistats/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    // --- KREDENSIAL LOKAL (MOCK) ---
    // Kredensial palsu untuk login
    const String mockUsername = 'admin';
    const String mockPassword = '12345';
    // ---------------------------------

    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading API

    if (_usernameController.text == mockUsername && _passwordController.text == mockPassword) {
      // Jika berhasil, simpan status login
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', mockUsername); // Simpan username jika perlu

      // Navigasi ke Halaman Utama dan hapus riwayat navigasi
      Navigator.pushReplacementNamed(context, '/main');
      
    } else {
      // Jika gagal, tampilkan pesan
      Fluttertoast.showToast(
        msg: "Username atau Password salah",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo Aplikasi Anda
              Image.asset(
                'assets/images/Mbois-stat Logo_Fix Putih.png',
                height: 120,
              ),
              const SizedBox(height: 16),
              Text(
                'Selamat Datang di MBOIStatS+',
                textAlign: TextAlign.center,
                style: bold18.copyWith(color: dark1),
              ),
              Text(
                'Silakan login untuk melanjutkan',
                textAlign: TextAlign.center,
                style: regular14.copyWith(color: dark2),
              ),
              const SizedBox(height: 48),

              // Kolom Username
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Kolom Password
              TextField(
                controller: _passwordController,
                obscureText: true, // Sembunyikan password
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tombol Login
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Colors.blue, // Sesuaikan dengan tema Anda
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
