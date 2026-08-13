import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mboistats/theme.dart';

class YouTubePlayerPage extends StatefulWidget {
  final String videoId;
  final String title;

  const YouTubePlayerPage({
    Key? key,
    required this.videoId,
    required this.title,
  }) : super(key: key);

  @override
  State<YouTubePlayerPage> createState() => _YouTubePlayerPageState();
}

class _YouTubePlayerPageState extends State<YouTubePlayerPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _openInYouTube() async {
    final url = Uri.parse('https://www.youtube.com/watch?v=${widget.videoId}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: blueNormal,
        progressColors: const ProgressBarColors(
          playedColor: blueNormal,
          handleColor: blueActive,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : dark1,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Live Youtube',
              style: pjsBold18.copyWith(
                color: isDark ? Colors.white : dark1,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: blueNormal,
                  size: 22,
                ),
                tooltip: 'Buka di YouTube',
                onPressed: _openInYouTube,
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // YouTube Player
                player,

                const SizedBox(height: 16),

                // Judul Video
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    widget.title,
                    style: pjsBold18.copyWith(
                      color: isDark ? Colors.white : dark1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Tombol Buka di YouTube
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: _openInYouTube,
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text('Buka di Aplikasi YouTube'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
