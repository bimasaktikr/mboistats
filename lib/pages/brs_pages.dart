import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/components/global_pdf_viewer.dart';
import 'package:mboistats/theme.dart';
import 'package:saf/saf.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' show parse;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mboistats/services/logger_service.dart';
import 'package:mboistats/services/recommendation_service.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BeritaPages extends StatefulWidget {
  const BeritaPages({Key? key}) : super(key: key);

  @override
  _BeritaPageState createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPages> {
  late Saf saf;
  List<Map<String, dynamic>> dataBRS = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
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
    fetchDataBRS();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        fetchDataBRS();
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
    final dateA = (a['rl_date'] ?? a['created_at'] ?? '').toString();
    final dateB = (b['rl_date'] ?? b['created_at'] ?? '').toString();
    final comp = dateB.compareTo(dateA);
    if (comp != 0) return comp;

    final yearA = _extractYear((a['title'] ?? '').toString());
    final yearB = _extractYear((b['title'] ?? '').toString());
    return yearB.compareTo(yearA);
  }

  Future<void> fetchDataBRS() async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

    try {
      final from = (currentPage - 1) * 20;
      final to = from + 19;

      var query = Supabase.instance.client
          .from('contents')
          .select(_selectedSector != 'semua' ? '*, contents_has_categories!inner(categories_id_category)' : '*')
          .or('content_type.eq.brs,action_type.eq.view_brs_pdf');

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
            dataBRS.addAll(list.map((item) => {
              'title': item['title'] ?? item['item_name'],
              'thumbnail': item['cover_url'],
              'pdf': item['content_url'],
              'created_at': item['created_at'],
            }));
            currentPage++;
          }
          if (list.length < 20) {
            hasMore = false;
          }
          isLoading = false;
        });
      }
      return;
    } catch (e) {
      print("Error fetching BRS from Supabase: $e");
    }

    // Fallback to BPS API if Supabase fails
    try {
      final String apiUrl = "https://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/3573/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";
      final response = await http.get(Uri.parse(apiUrl), headers: {'User-Agent': 'Mozilla/5.0'});

      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        final brs = List<Map<String, dynamic>>.from(parsedResponse["data"][1]);

        if (mounted) {
          setState(() {
            if (brs.isNotEmpty) {
              dataBRS.addAll(brs);
              dataBRS.sort(_compareByNewest);
              currentPage++;
            } else {
              hasMore = false;
            }
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String truncateText(String text, int maxLength) {
    if (text.length > maxLength) {
      return '${text.substring(0, maxLength)}...';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = dataBRS;

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
                    'Berita Resmi Statistik',
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
                            dataBRS.clear();
                            currentPage = 1;
                            hasMore = true;
                          });
                          fetchDataBRS();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Grid content
            Expanded(
              child: displayList.isEmpty && isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : displayList.isEmpty
                      ? Center(
                          child: Text(
                            'Tidak ada BRS di sektor ini.',
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
                          itemCount: displayList.length + (hasMore && _selectedSector == 'semua' ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == displayList.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final item = displayList[index];
                            final title = (item["title"] ?? '').toString();
                            final thumbnail = (item['thumbnail'] ?? '').toString();
                            final pdfUrl = (item["pdf"] ?? '').toString();

                            return InkWell(
                              onTap: () => showDownloadDialog(context, pdfUrl, index),
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
                                      child: thumbnail.isNotEmpty
                                          ? Image.network(
                                              thumbnail,
                                              headers: const {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'},
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Center(
                                                child: Icon(
                                                  Icons.newspaper,
                                                  color: dark3,
                                                  size: 40,
                                                ),
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.newspaper,
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

  void showDownloadDialog(BuildContext context, String pdfUrl, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            dataBRS[index]["title"],
            textAlign: TextAlign.center,
            style: bold16.copyWith(color: dark1),
          ),
          content: SingleChildScrollView(
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dataBRS[index]["abstract"] != null && (dataBRS[index]["abstract"] as String).isNotEmpty
                            ? (parse(HtmlUnescape().convert(dataBRS[index]["abstract"])).body?.text ?? '')
                            : (dataBRS[index]["title"] ?? ''),
                        style: TextStyle(fontSize: 13, color: dark1),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 8),
                      if (dataBRS[index]["size"] != null)
                        Text(
                          "Ukuran Berkas: ${(dataBRS[index]["size"] as String).replaceAll('.', ',')}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey
                          ),
                        ),
                      if (dataBRS[index]["rl_date"] != null || dataBRS[index]["created_at"] != null)
                        Text(
                          "Tanggal Rilis: ${dataBRS[index]["rl_date"] ?? dataBRS[index]["created_at"]?.toString().split('T')[0] ?? ''}",
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey
                          ),
                        ),
                    ],
                  ),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    String fileName = dataBRS[index]["title"];
                    await downloadAndShowConfirmation(context, pdfUrl, fileName);
                  },
                  child: const Text("Unduh"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    String fileName = dataBRS[index]["title"];
                    LoggerService.logActivity(
                      actionType: 'view_pdf',
                      contentType: 'brs',
                      sectorCategory: LoggerService.classifySector(fileName),
                      itemName: fileName,
                      coverUrl: dataBRS[index]["thumbnail"],
                      contentUrl: pdfUrl,
                    );
                    openPdfDirectly(context, pdfUrl, fileName);
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

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
    final item = dataBRS.firstWhere((x) => x['pdf'] == pdfUrl, orElse: () => {});
    final coverUrl = item['thumbnail'] as String?;

    if (Platform.isIOS) {
      try {
        Fluttertoast.showToast(
          msg: "Menyiapkan berkas BRS...",
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
            sectorCategory: LoggerService.classifySector(fileName),
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

    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas BRS sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        String cleanFileName = fileName;
        if (!cleanFileName.toLowerCase().endsWith('.pdf')) {
          cleanFileName = '$cleanFileName.pdf';
        }

        FileDownloader.downloadFile(
          url: pdfUrl,
          name: cleanFileName,
          downloadDestination: DownloadDestinations.publicDownloads,
          onProgress: (fileName, double progress) {},
          onDownloadCompleted: (String path) {
            // Fallback rename jika file terunduh dengan ekstensi .php karena redirect server BPS
            final decodedPath = Uri.decodeFull(path);
            if (decodedPath.endsWith('.php')) {
              try {
                final file = File(decodedPath);
                final newPath = decodedPath.replaceAll('.php', '.pdf');
                if (file.existsSync()) {
                  file.renameSync(newPath);
                } else {
                  // Coba gunakan path mentah jika file disimpan dengan %20 literal
                  final rawFile = File(path);
                  final rawNewPath = path.replaceAll('.php', '.pdf');
                  if (rawFile.existsSync()) {
                    rawFile.renameSync(rawNewPath);
                  }
                }
              } catch (e) {
                print("Gagal me-rename file: $e");
              }
            }

            // Catat log aktivitas ke Supabase
            LoggerService.logActivity(
              actionType: 'download_file',
              sectorCategory: LoggerService.classifySector(fileName),
              itemName: fileName,
              coverUrl: coverUrl,
              contentUrl: pdfUrl,
            );

            Fluttertoast.showToast(
              msg: 'Berita Resmi Statistik (BRS) "$fileName" telah disimpan.',
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          },
          onDownloadError: (String error) {
            Fluttertoast.showToast(
              msg: "Gagal mengunduh berkas.",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              fontSize: 16.0,
            );
          },
        );
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Terjadi kesalahan saat mengunduh. \$error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Aplikasi belum diizinkan untuk mengakses penyimpanan.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return true;
      }
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  void openPdfDirectly(BuildContext context, String pdfUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GlobalPDFViewer(pdfUrl: pdfUrl, title: title),
      ),
    );
  }
}

class PDFViewer extends StatelessWidget {
  final String pdfUrl;

  const PDFViewer({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
      ),
      body: SfPdfViewer.network(pdfUrl),
    );
  }
}