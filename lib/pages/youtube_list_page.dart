import 'package:flutter/material.dart';
import 'package:mboistats/models/youtube_video.dart';
import 'package:mboistats/services/youtube_service.dart';
import 'package:mboistats/theme.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher_string.dart'; // <-- Pastikan import ini ada

class YoutubeListPage extends StatefulWidget {
  const YoutubeListPage({Key? key}) : super(key: key);

  @override
  _YoutubeListPageState createState() => _YoutubeListPageState();
}

class _YoutubeListPageState extends State<YoutubeListPage> {
  late YoutubeService _youtubeService;

  final List<YoutubeVideo> _videos = [];
  
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalResults = 0;

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  final String _youtubeChannelUrl = 'https://www.youtube.com/@bpskotamalang';

  @override
  void initState() {
    super.initState();
    _youtubeService = YoutubeService(); 
    _fetchPage(1); 
  }

  Future<void> _fetchPage(int pageNumber, {bool isRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    int pageToFetch = isRefresh ? 1 : pageNumber;

    try {
      final result = await _youtubeService.getVideos(
        page: pageToFetch,
        publishedAfter: _startDate, 
        publishedBefore: _endDate,
      );
      
      if (!mounted) return;

      setState(() {
        _videos.clear();
        _videos.addAll(result.videos);
        _currentPage = result.currentPage;
        _totalPages = result.totalPages;
        _totalResults = result.totalResults;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }
  
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime now = DateTime.now();
    DateTime firstDate = DateTime(2010);
    DateTime lastDate = now;

    if (isStartDate) {
      lastDate = _endDate ?? now;
    } else {
      firstDate = _startDate ?? firstDate;
    }

    DateTime initialDate = isStartDate 
        ? (_startDate ?? now) 
        : (_endDate ?? now);
    
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
      _fetchPage(1, isRefresh: true);
    }
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter berdasarkan rentang tanggal:",
            style: semibold14.copyWith(color: dark2)
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today, size: 16, color: blue1),
                  label: Text(
                    _startDate == null ? 'Tanggal Mulai' : _dateFormatter.format(_startDate!),
                    style: regular14.copyWith(color: blue1),
                  ),
                  onPressed: () => _selectDate(context, true),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: blue1.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(Icons.calendar_today, size: 16, color: blue1),
                  label: Text(
                    _endDate == null ? 'Tanggal Akhir' : _dateFormatter.format(_endDate!),
                    style: regular14.copyWith(color: blue1),
                  ),
                  onPressed: () => _selectDate(context, false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: blue1.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          if (_startDate != null || _endDate != null)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: Icon(Icons.close, size: 16, color: Colors.red[700]),
                label: Text(
                  'Hapus Filter',
                  style: regular14.copyWith(color: Colors.red[700]),
                ),
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  _fetchPage(1, isRefresh: true);
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BPS Kota Malang'),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          _buildFilterControls(),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchPage(1, isRefresh: true),
              child: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBodyContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: blue1,
        ),
      );
    }
    if (_isError) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded,
                  color: Colors.grey[400], size: 80),
              const SizedBox(height: 24),
              
              Text(
                'Gagal Memuat Video',
                style: bold18.copyWith(color: dark1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              Text(
                'Mohon maaf, sepertinya ada gangguan koneksi ke server kami. Anda tetap dapat menonton video terbaru langsung di YouTube.',
                style: regular14.copyWith(color: dark2, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blue1, blue2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      launchUrlString(_youtubeChannelUrl, mode: LaunchMode.externalApplication);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Buka Channel YouTube',
                          style: semibold14.copyWith(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _fetchPage(1, isRefresh: true),
                icon: Icon(Icons.refresh, color: blue1),
                label: Text("Coba Muat Ulang", style: semibold14.copyWith(color: blue1)),
              )
            ],
          ),
        ),
      );
    }
    
    if (_videos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off_outlined,
                  color: Colors.grey[600], size: 50),
              const SizedBox(height: 16),
              Text(
                _startDate == null && _endDate == null
                   ? 'Playlist BRS kosong'
                   : 'Tidak ada video ditemukan',
                style: bold16.copyWith(color: dark1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada video BRS yang ditemukan untuk filter ini. Tarik untuk memuat ulang.',
                style: regular14.copyWith(color: dark2),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final video = _videos[index];
                return _buildVideoCard(context, video);
              },
              childCount: _videos.length,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildPaginationControls(),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    if (_isLoading || _totalPages <= 1) return const SizedBox(height: 48);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios,
                size: 18, 
                color: _currentPage <= 1 ? Colors.grey : blue1),
            onPressed: _currentPage <= 1
                ? null
                : () {
                    _fetchPage(_currentPage - 1);
                  },
          ),
          
          Text(
            'Halaman $_currentPage dari $_totalPages',
            style: regular14.copyWith(color: dark2),
          ),
          
          IconButton(
            icon: Icon(Icons.arrow_forward_ios,
                size: 18, 
                color: _currentPage >= _totalPages ? Colors.grey : blue1),
            onPressed: _currentPage >= _totalPages
                ? null
                : () {
                    _fetchPage(_currentPage + 1);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, YoutubeVideo video) {
    String formattedDate = '';
    try {
      final DateTime publishedDate = DateTime.parse(video.publishedAt);
      formattedDate = _dateFormatter.format(publishedDate);
    } catch (e) {
      formattedDate = ''; 
    }

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context)
                .pushNamed('/youtube_player', arguments: video);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12.0),
                        topRight: Radius.circular(12.0),
                      ),
                      child: Image.network(
                        video.thumbnailUrl.isEmpty 
                            ? 'https://via.placeholder.com/320x180.png?text=No+Image' 
                            : video.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                                color: blue1,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.broken_image,
                              color: Colors.grey[400], size: 40),
                        ),
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 30),
                    ),
                    if (video.isLive)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            'LIVE',
                            style: bold16.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: semibold14.copyWith(color: dark1, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      video.channelTitle,
                      style: regular14.copyWith(color: dark2, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate, 
                      style: regular12_5.copyWith(color: dark3, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}