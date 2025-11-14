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
        TextButton(
          child: Text('Nanti Saja', style: semibold14.copyWith(color: dark3)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: blue1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: Text('Login Sekarang', style: semibold14.copyWith(color: Colors.white)),
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop(); 
            navigator.pushNamed('/login'); 
          },
        ),
      ],
    );
  }
}