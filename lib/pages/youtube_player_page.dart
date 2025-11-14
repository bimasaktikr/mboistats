import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mboistats/models/youtube_video.dart';
import 'package:mboistats/theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:intl/intl.dart';

class YoutubePlayerPage extends StatefulWidget {
  const YoutubePlayerPage({Key? key}) : super(key: key);

  @override
  _YoutubePlayerPageState createState() => _YoutubePlayerPageState();
}

class _YoutubePlayerPageState extends State<YoutubePlayerPage> {
  late YoutubePlayerController _controller;
  late YoutubeVideo _video; // Simpan seluruh objek video
  bool _isPlayerReady = false;
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final video = ModalRoute.of(context)!.settings.arguments as YoutubeVideo?;

    if (video == null) {
      Navigator.of(context).pop();
      return;
    }

    _video = video; // Simpan video

    _controller = YoutubePlayerController(
      initialVideoId: _video.id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        controlsVisibleAtStart: true, 
      ),
    )..addListener(listener);
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
      });
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = '';
    try {
      final DateTime publishedDate = DateTime.parse(_video.publishedAt);
      formattedDate = _dateFormatter.format(publishedDate);
    } catch (e) {
      formattedDate = 'Tanggal tidak diketahui';
    }
    return YoutubePlayerBuilder(
      onEnterFullScreen: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      },
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: blue1,
        onReady: () {
          _isPlayerReady = true;
        },
      ),
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              _video.isLive ? 'Siaran Langsung' : 'Putar Video',
              style: bold16.copyWith(color: dark1, fontSize: 16),
            ),
            leading: IconButton(
              icon: Image.asset('assets/icons/left-arrow.png', height: 25),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16), // Jarak dari AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: player, // 'player' dari YoutubePlayerBuilder
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _video.title,
                        style: bold18.copyWith(color: dark1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: dark3, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _video.channelTitle,
                            style: regular14.copyWith(color: dark2),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.calendar_today_outlined,
                              color: dark3, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: regular14.copyWith(color: dark2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Deskripsi',
                        style: bold16.copyWith(color: dark1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _video.description.isEmpty
                            ? 'Tidak ada deskripsi.'
                            : _video.description,
                        style: regular14.copyWith(color: dark2, height: 1.5),
                      ),
                      const SizedBox(height: 32), // Padding di bawah
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}