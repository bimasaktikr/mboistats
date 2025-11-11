import 'package:flutter/material.dart';
import 'package:mboistats/components/app_drawer.dart';
import 'package:mboistats/components/buttonSection.dart';
import 'package:mboistats/components/carousel_infografis.dart';
import 'package:mboistats/components/carousel_publikasi.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/components/menus.dart';
import 'package:mboistats/theme.dart';
import 'package:flutter/services.dart';
import 'package:mboistats/services/youtube_service.dart';
import 'package:mboistats/models/youtube_video.dart';
import 'dart:async';
import 'package:mboistats/services/auth_service_custom.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<CarouselPublikasiState> _publikasiKey =
      GlobalKey<CarouselPublikasiState>();
  final GlobalKey<CarouselInfografisState> _infografisKey =
      GlobalKey<CarouselInfografisState>();

  final YoutubeService _youtubeService = YoutubeService();
  bool _isLive = false;
  bool _isLoadingLiveStatus = true;

  late AnimationController _animationController;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkLiveStatus();

    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkLiveStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkLiveStatus() async {
    if (!_isLoadingLiveStatus && mounted) {
      setState(() {
        _isLoadingLiveStatus = true;
      });
    }

    try {
      final result = await _youtubeService.getVideos(page: 1);
      bool liveStatus = false;
      if (result.videos.isNotEmpty) {
        liveStatus = result.videos[0].isLive;
      }
      if (mounted) {
        setState(() {
          _isLive = liveStatus;
          _isLoadingLiveStatus = false;
          if (_isLive) {
            _animationController.repeat(reverse: true);
          } else {
            _animationController.stop();
          }
        });
      }
    } catch (e) {
      print("Error cek status live di HomePage: $e");
      if (mounted) {
        setState(() {
          _isLoadingLiveStatus = false;
          _isLive = false;
        });
      }
    }
  }

  void _refreshCarousels() {
    print("DEBUG: Refreshing carousels from HomePage...");
    if (_publikasiKey.currentState != null && mounted) {
      _publikasiKey.currentState?.fetchData();
    }
    if (_infografisKey.currentState != null && mounted) {
      _infografisKey.currentState?.fetchData();
    }
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
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                  ),
                  child:
                      const Text('Tidak', style: TextStyle(color: Colors.blue)),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: OutlinedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blue),
                  ),
                  child: const Text('Ya', style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  Widget _buildYoutubeBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE62117), Color(0xFFC41106)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 12.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/youtube_list');
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32.0,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BPS KOTA MALANG',
                      style: semibold12_5.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Video Pers & Live',
                      style: bold16.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Klik untuk menonton',
                      style: regular12_5.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingLiveStatus)
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(left: 8),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                )
              else if (_isLive)
                FadeTransition(
                  opacity: _animationController,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'LIVE',
                      style: bold16.copyWith(
                        color: const Color(0xFFE62117),
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AuthServiceCustom.instance.currentUser,
      builder: (context, User? user, _) {
        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 50,
              centerTitle: false,
              
              // --- PERUBAIKAN DINAMIS DI SINI ---
              // Jika user TIDAK null (login), titleSpacing = 0.0 (rapat)
              // Jika user null (logout), titleSpacing = 16.0 (ada padding kiri)
              titleSpacing: user != null ? 0.0 : 16.0,
              // --- AKHIR PERUBAIKAN ---

              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/Mbois-stat Logo_Fix Putih.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'MBOIStatS+',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              actions: [
                if (user == null)
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 12.0, top: 8, bottom: 8),
                    child: ElevatedButton(
                      child: Text(
                        'Login',
                        style: semibold14.copyWith(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: blue1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
              ],
            ),
            drawer: user != null
                ? AppDrawer(onRefreshNeeded: _refreshCarousels)
                : null,
            body: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                        child: _buildYoutubeBanner(context),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Yuk lebih dekat dengan BPS Kota Malang',
                                style: bold16.copyWith(color: dark1)),
                            const SizedBox(height: 8.0),
                            Text('Mau cari data apa???',
                                style: regular14.copyWith(color: dark2)),
                          ],
                        ),
                      ),
                      const Menus(),
                      ButtonSection(),
                      CarouselPublikasi(key: _publikasiKey),
                      CarouselInfografis(key: _infografisKey),
                    ],
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Footer(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}