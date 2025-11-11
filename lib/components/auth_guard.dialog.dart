import 'package:flutter/material.dart';
import 'package:mboistats/theme.dart';

class AuthGuardDialog extends StatelessWidget {
  const AuthGuardDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: blue1),
          const SizedBox(width: 10),
          Text(
            'Fitur Khusus Anggota',
            style: bold16.copyWith(color: dark1, fontSize: 17),
          ),
        ],
      ),
      content: Text(
        'Anda harus login terlebih dahulu untuk dapat menyimpan item ke favorit.',
        style: regular14.copyWith(color: dark2, height: 1.5),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        // Tombol "Nanti Saja"
        TextButton(
          child: Text('Nanti Saja', style: semibold14.copyWith(color: dark3)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        // Tombol "Login"
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text('Login Sekarang', style: semibold14.copyWith(color: Colors.white)),
          
          // --- PERBAIKAN DI SINI ---
          onPressed: () {
            // 1. Ambil instance Navigator SEBELUM pop()
            final navigator = Navigator.of(context);
            
            // 2. Tutup dialog saat ini menggunakan navigator
            navigator.pop(); 
            
            // 3. Arahkan ke Halaman Login menggunakan navigator yang aman
            navigator.pushNamed('/login'); 
          },
          // --- AKHIR PERBAIKAN ---
        ),
      ],
    );
  }
}