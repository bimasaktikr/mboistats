import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'dart:convert';
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublikasiFullPage extends StatefulWidget {
  const PublikasiFullPage({Key? key}) : super(key: key);

  @override
  State<PublikasiFullPage> createState() => _PublikasiFullPageState();
}

class _PublikasiFullPageState extends State<PublikasiFullPage> {
  List<Map<String, dynamic>> _dataPublikasi = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  String _selectedSector = 'semua';

  final List<Map<String, String>> _sectorFilters = const [
    {'key': 'semua', 'label': 'Semua Sektor'},
    {'key': 'pertanian', 'label': 'Pertanian'},
    {'key': 'perekonomian', 'label': 'Perekonomian'},
    {'key': 'tenaga_kerja', 'label': 'Tenaga Kerja'},
    {'key': 'ipm', 'label': 'IPM'},
    {'key': 'kemiskinan', 'label': 'Kemiskinan'},
    {'key': 'kependudukan', 'label': 'Kependudukan'},
    {'key': 'kesejahteraan', 'label': 'Kesejahteraan'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDataPublikasi();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchDataPublikasi();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _extractYear(String title) {
    final matches = RegExp(r'\b(20\d{2}|19\d{2})\b').allMatches(title);
    if (matches.isNotEmpty) {
      return int.tryParse(matches.last.group(0) ?? '') ?? 0;
    }
    return 0;
  }

  int _compareByNewest(Map<String, dynamic> a, Map<String, dynamic> b) {
    final dateA = (a['rl_date'] ?? a['sch_date'] ?? a['created_at'] ?? '').toString();
    final dateB = (b['rl_date'] ?? b['sch_date'] ?? b['created_at'] ?? '').toString();
    final comp = dateB.compareTo(dateA);
    if (comp != 0) return comp;

    final yearA = _extractYear((a['title'] ?? '').toString());
    final yearB = _extractYear((b['title'] ?? '').toString());
    return yearB.compareTo(yearA);
  }

  List<Map<String, dynamic>> get _filteredPublikasi {
    if (_selectedSector == 'semua') return _dataPublikasi;
    return _dataPublikasi.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final sector = LoggerService.classifySector(title).toLowerCase();
      return sector == _selectedSector.toLowerCase() ||
          title.contains(_selectedSector.toLowerCase());
    }).toList();
  }

  Future<void> _fetchDataPublikasi() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final from = (_currentPage - 1) * 20;
      final to = from + 19;

      var query = Supabase.instance.client
          .from('contents')
          .select(_selectedSector != 'semua' ? '*, contents_has_categories!inner(categories_id_category)' : '*')
          .or('content_type.eq.publikasi,action_type.eq.view_publikasi_pdf');

      const sectorToCategoryId = {
        'perekonomian': 1, 'tenaga_kerja': 2, 'ipm': 3,
        'kemiskinan': 4, 'kependudukan': 5, 'pertanian': 6, 'kesejahteraan': 7,
      };

      if (_selectedSector != 'semua' && sectorToCategoryId.containsKey(_selectedSector)) {
        query = query.eq('contents_has_categories.categories_id_category', sectorToCategoryId[_selectedSector]!);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final list = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          if (list.isNotEmpty) {
            _dataPublikasi.addAll(list.map((item) => {
              'title': item['title'] ?? item['item_name'],
              'cover': item['cover_url'],
              'pdf': item['content_url'],
              'created_at': item['created_at'],
            }));
            _currentPage++;
          }
          if (list.length < 20) {
            _hasMore = false;
          }
          _isLoading = false;
        });
      }
      return;
    } catch (e) {
      print("Error fetching Publikasi from Supabase: $e");
    }

    // Fallback to BPS API
    final String apiUrl =
        "https://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/$_currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: {'User-Agent': 'Mozilla/5.0'});
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse["data"] != null && parsedResponse["data"][1] != null) {
          final List<dynamic> publikasi = parsedResponse["data"][1];
          if (publikasi.isEmpty) {
            setState(() => _hasMore = false);
          } else {
            final list = List<Map<String, dynamic>>.from(publikasi);
            setState(() {
              _currentPage++;
              _dataPublikasi.addAll(list);
              _dataPublikasi.sort(_compareByNewest);
            });
          }
        } else {
          setState(() => _hasMore = false);
        }
      } else {
        setState(() => _hasMore = false);
      }
    } catch (_) {
      // Handle error quietly
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = _dataPublikasi;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom header matching mockup: back arrow + title text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets_v2/icons/back_arrow.png',
                      width: 24,
                      height: 24,
                      color: isDark ? blueLighter : blueHover,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Publikasi',
                    style: pjsBold20.copyWith(
                      color: isDark ? blueLighter : blueHover,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Sector Filter Chips
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _sectorFilters.map((sector) {
                    final isSelected = _selectedSector == sector['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          sector['label']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : dark1),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: blueNormal,
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? blueNormal : dark4,
                            width: 1,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedSector = sector['key']!;
                            _dataPublikasi.clear();
                            _currentPage = 1;
                            _hasMore = true;
                          });
                          _fetchDataPublikasi();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Grid content
            Expanded(
              child: displayList.isEmpty && _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada Publikasi di sektor ini.',
                            style: pjsRegular14.copyWith(color: dark3),
                          ),
                        )
                      : GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.58,
                          ),
                          itemCount: displayList.length + (_hasMore && _selectedSector == 'semua' ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayList.length) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final item = displayList[index];
                            final String coverUrl = item['cover'] ?? '';
                            final String pdfUrl = item['pdf'] ?? '';
                            final String title = item['title'] ?? 'Publikasi BPS';

                            return InkWell(
                              onTap: () {
                                if (pdfUrl.isNotEmpty) {
                                  _showPublikasiConfirmDialog(
                                    context: context,
                                    title: title,
                                    pdfUrl: pdfUrl,
                                    coverUrl: coverUrl,
                                    abstractText: item['abstract'] ?? item['ringkasan'],
                                    releaseDate: item['rl_date'] ?? item['created_at']?.toString().split('T')[0],
                                    size: item['size'],
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      child: coverUrl.isNotEmpty
                                          ? Image.network(
                                              coverUrl,
                                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Center(
                                                child: Icon(
                                                  Icons.book,
                                                  color: dark3,
                                                  size: 40,
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.book,
                                                color: dark3,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    title,
                                    style: pjsRegular14.copyWith(
                                      color: isDark ? Colors.white : dark1,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Footer(),
    );
  }

  void _showPublikasiConfirmDialog({
    required BuildContext context,
    required String title,
    required String pdfUrl,
    String? coverUrl,
    String? abstractText,
    String? releaseDate,
    String? size,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: pjsBold16.copyWith(color: dark1),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (abstractText != null && abstractText.isNotEmpty)
                  Text(
                    abstractText,
                    style: TextStyle(fontSize: 13, color: dark1),
                    textAlign: TextAlign.justify,
                  )
                else
                  Text(
                    title,
                    style: TextStyle(fontSize: 13, color: dark1),
                    textAlign: TextAlign.justify,
                  ),
                const SizedBox(height: 8),
                if (size != null && size.isNotEmpty)
                  Text(
                    "Ukuran Berkas: ${size.replaceAll('.', ',')}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                if (releaseDate != null && releaseDate.isNotEmpty)
                  Text(
                    "Tanggal Rilis: $releaseDate",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Tutup"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _downloadAndOpenPdf(pdfUrl, title, coverUrl);
                  },
                  child: const Text("Unduh"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    LoggerService.logActivity(
                      actionType: 'view_pdf',
                      contentType: 'publikasi',
                      sectorCategory: LoggerService.classifySector(title),
                      itemName: title,
                      coverUrl: coverUrl,
                      contentUrl: pdfUrl,
                    );
                    Navigator.pushNamed(
                      context,
                      '/pdf_viewer',
                      arguments: {'pdfUrl': pdfUrl, 'title': title},
                    );
                  },
                  child: const Text("Buka PDF"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadAndOpenPdf(String pdfUrl, String fileName, String? coverUrl) async {
    final cleanSector = LoggerService.classifySector(fileName);

    if (Platform.isIOS) {
      try {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas...",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        final response = await http.get(Uri.parse(pdfUrl));
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
          final filePath = '${dir.path}/$cleanName.pdf';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: cleanSector,
            itemName: fileName,
            coverUrl: coverUrl,
            contentUrl: pdfUrl,
          );

          await OpenFile.open(filePath);
        } else {
          throw Exception("Gagal mengunduh berkas dari server.");
        }
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Gagal mengunduh: $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
      return;
    }

    try {
      Fluttertoast.showToast(
        msg: "Memulai unduhan...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );

      final cleanName = fileName.replaceAll(RegExp(r'[^\w\s\-\.]'), '_');
      await FileDownloader.downloadFile(
        url: pdfUrl,
        name: cleanName.endsWith('.pdf') ? cleanName : '$cleanName.pdf',
        onDownloadCompleted: (String path) {
          LoggerService.logActivity(
            actionType: 'download_file',
            sectorCategory: cleanSector,
            itemName: fileName,
            coverUrl: coverUrl,
            contentUrl: pdfUrl,
          );
          Fluttertoast.showToast(
            msg: "Unduhan selesai.",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.blue,
            textColor: Colors.white,
          );
        },
        onDownloadError: (String error) {
          Fluttertoast.showToast(
            msg: "Gagal mengunduh: $error",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        },
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Gagal mengunduh: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
