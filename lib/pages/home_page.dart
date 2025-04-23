import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mboistats/components/buttonSection.dart';
import 'package:mboistats/components/carousel_infografis.dart';
import 'package:mboistats/components/carousel_publikasi.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/components/menus.dart';
import 'package:mboistats/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(color: Colors.blue),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          textAlign: TextAlign.justify,
        ),
        actions: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                child: const Text('Tidak', style: TextStyle(color: Colors.blue)),
              ),
              const SizedBox(width: 16), // space between buttons
              OutlinedButton(
                onPressed: () => SystemNavigator.pop(),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)),
                child: const Text('Ya', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 50,
          title: const Text(
            'MBOIStatS+',
            style: TextStyle(color: Colors.black),
          ),
          leading: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset('assets/images/Mbois-stat Logo_Fix Putih.png',
                  width: 40, height: 40),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Yuk lebih dekat dengan BPS Kota Malang', style: bold16.copyWith(color: dark1)),
                    const SizedBox(height: 8.0),
                    Text('Mau cari data apa???', style: regular14.copyWith(color: dark2)),
                  ],
                ),
              ),
              const Menus(),
              ButtonSection(),
              const CarouselPublikasi(),
              const CarouselInfografis(),
            ],
          ),
        ),
        bottomNavigationBar: const Footer(),
      ),
    );
  }
}
