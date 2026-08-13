import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/components/menus.dart';
import 'package:mboistats/components/recommendations.dart';
import 'package:mboistats/components/recently_viewed.dart';
import 'package:mboistats/services/youtube_service.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _liveStream;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _checkLiveStream();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _checkLiveStream() async {
    final live = await YouTubeService.getLiveStream();
    if (mounted && live != null) {
      final videoId = live['video_id'] as String? ?? '';
      if (videoId.isNotEmpty) {
        setState(() {
          _liveStream = live;
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              showLiveFullscreenButton: true,
              isLive: true,
            ),
          );
        });
      }
    }
  }

  String _getUserName() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final metadata = user.userMetadata;
      if (metadata != null && metadata.containsKey('full_name')) {
        final name = metadata['full_name'].toString();
        if (name.isNotEmpty) {
          return name.split(' ').first;
        }
      }
      return 'Pengguna';
    }
    return 'Tamu';
  }

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
                  child:
                      const Text('Tidak', style: TextStyle(color: blueNormal)),
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

  Widget _buildLiveYouTubeBanner(bool isDark) {
    if (_liveStream == null || _youtubeController == null) {
      return const SizedBox.shrink();
    }

    final title = _liveStream!['title'] ?? 'Siaran Pers BPS Kota Malang';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Container Player
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.red,
                    handleColor: Colors.redAccent,
                  ),
                ),
                // Badge LIVE
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: pjsBold14.copyWith(
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Judul & Link YouTube
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: pjsSemiBold14.copyWith(
                    color: isDark ? Colors.white : dark1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () async {
                  final videoId = _liveStream!['video_id'] ?? '';
                  final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.open_in_new, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        'YouTube',
                        style: pjsSemiBold12.copyWith(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                              '${_getGreeting()}, ${_getUserName()}',
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
                      Menus(),
                      // Live YouTube Banner (kondisional - hanya muncul saat live)
                      _buildLiveYouTubeBanner(isDark),
                      const SizedBox(height: 12),
                      RecommendationSection(),
                      const SizedBox(height: 8),
                      RecentlyViewedSection(),
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
