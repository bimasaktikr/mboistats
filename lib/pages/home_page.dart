import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/components/menus.dart';
import 'package:mboistats/components/recommendations.dart';
import 'package:mboistats/components/recently_viewed.dart';
import 'package:mboistats/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi';
    if (hour < 15) return 'Selamat siang';
    if (hour < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(color: blueActive),
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
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: blueNormal),
                  ),
                  child: const Text('Tidak', style: TextStyle(color: blueNormal)),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: blueNormal),
                  ),
                  child: const Text('Ya', style: TextStyle(color: blueNormal)),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teal gradient header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 20,
                    right: 20,
                    bottom: 50,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1F7BA4), Color(0xFF2AA9E1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              '${_getGreeting()}, Jennie',
                              style: pjsBold20.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kamu mau cari data apa hari ini?',
                              style: pjsRegular14.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets_v2/icons/bps_2.png',
                        width: 110,
                        height: 110,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                          'assets/images/Mbois-stat Logo_Fix Putih.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ],
                  ),
                ),
                // Body content shifted up by 35px to overlap header bottom smoothly
                Transform.translate(
                  offset: const Offset(0, -35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Menus(),
                      const SizedBox(height: 12),
                      const RecommendationSection(),
                      const SizedBox(height: 8),
                      const RecentlyViewedSection(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const Footer(),
      ),
    );
  }
}
