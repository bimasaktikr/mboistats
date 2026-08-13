import 'package:flutter/material.dart';
import 'package:mboistats/services/youtube_service.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';

class YouTubeArchivePage extends StatefulWidget {
  const YouTubeArchivePage({Key? key}) : super(key: key);

  @override
  State<YouTubeArchivePage> createState() => _YouTubeArchivePageState();
}

class _YouTubeArchivePageState extends State<YouTubeArchivePage> {
  int? _selectedMonth;
  int? _selectedYear;
  List<int> _availableYears = [];
  List<Map<String, dynamic>> _streams = [];
  bool _isLoading = true;

  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final years = await YouTubeService.getAvailableYears();
    final streams = await YouTubeService.getArchivedStreams(
      month: _selectedMonth,
      year: _selectedYear,
    );

    if (mounted) {
      setState(() {
        _availableYears = years;
        _streams = streams;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyFilter() async {
    setState(() => _isLoading = true);

    final streams = await YouTubeService.getArchivedStreams(
      month: _selectedMonth,
      year: _selectedYear,
    );

    if (mounted) {
      setState(() {
        _streams = streams;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    return '${date.day} ${_monthNames[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : blueNormal,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Youtube',
          style: pjsBold20.copyWith(
            color: isDark ? Colors.white : blueNormal,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Filter Bulan
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFDDE5ED),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedMonth,
                        hint: Text(
                          'Bulan',
                          style: pjsRegular14.copyWith(
                            color: isDark ? Colors.white70 : dark3,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDark ? Colors.white70 : blueNormal,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Semua Bulan',
                              style: pjsRegular14.copyWith(
                                color: isDark ? Colors.white : dark1,
                              ),
                            ),
                          ),
                          ...List.generate(12, (i) {
                            return DropdownMenuItem<int?>(
                              value: i + 1,
                              child: Text(
                                _monthNames[i],
                                style: pjsRegular14.copyWith(
                                  color: isDark ? Colors.white : dark1,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedMonth = val);
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Tahun
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white24 : const Color(0xFFDDE5ED),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedYear,
                        hint: Text(
                          'Tahun',
                          style: pjsRegular14.copyWith(
                            color: isDark ? Colors.white70 : dark3,
                          ),
                        ),
                        isExpanded: true,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: isDark ? Colors.white70 : blueNormal,
                        ),
                        dropdownColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Semua Tahun',
                              style: pjsRegular14.copyWith(
                                color: isDark ? Colors.white : dark1,
                              ),
                            ),
                          ),
                          ..._availableYears.map((year) {
                            return DropdownMenuItem<int?>(
                              value: year,
                              child: Text(
                                year.toString(),
                                style: pjsRegular14.copyWith(
                                  color: isDark ? Colors.white : dark1,
                                ),
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedYear = val);
                          _applyFilter();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _streams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off_outlined,
                              size: 56,
                              color: isDark ? Colors.white38 : dark3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada rekaman siaran pers',
                              style: pjsSemiBold14.copyWith(
                                color: isDark ? Colors.white54 : dark2,
                              ),
                            ),
                            if (_selectedMonth != null || _selectedYear != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Coba ubah filter bulan atau tahun',
                                style: pjsRegular12.copyWith(
                                  color: isDark ? Colors.white38 : dark3,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _streams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final stream = _streams[index];
                          return _buildStreamCard(stream, isDark);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream, bool isDark) {
    final title = stream['title'] ?? 'Siaran Pers BPS Kota Malang';
    final thumbnail = stream['thumbnail_url'] ?? '';
    final videoId = stream['video_id'] ?? '';
    final publishedAt = stream['published_at']?.toString();

    return InkWell(
      onTap: () {
        if (videoId.isNotEmpty) {
          LoggerService.logActivity(
            actionType: 'view_youtube',
            sectorCategory: 'youtube',
            itemName: title,
          );
          Navigator.pushNamed(
            context,
            '/youtube_player',
            arguments: {'videoId': videoId, 'title': title},
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail (kiri)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: SizedBox(
                width: 150,
                height: 100,
                child: thumbnail.isNotEmpty
                    ? Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8F4FD),
                          child: const Icon(Icons.play_circle_outline, color: blueNormal, size: 36),
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8F4FD),
                        child: const Icon(Icons.play_circle_outline, color: blueNormal, size: 36),
                      ),
              ),
            ),
            // Judul & Tanggal (kanan)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: pjsSemiBold14.copyWith(
                        color: isDark ? Colors.white : dark1,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (publishedAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(publishedAt),
                        style: pjsRegular12.copyWith(
                          color: isDark ? Colors.white54 : dark3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
