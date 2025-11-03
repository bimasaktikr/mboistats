import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/theme.dart';
import 'package:saf/saf.dart'; 
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' show parse;
import 'package:shared_preferences/shared_preferences.dart';

class PublikasiPage extends StatefulWidget {
  const PublikasiPage({Key? key}) : super(key: key);

  @override
  _PublikasiPageState createState() => _PublikasiPageState();
}

class _PublikasiPageState extends State<PublikasiPage> {
  late Saf saf; 
  List<Map<String, dynamic>> dataPublikasi = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    saf = Saf("mboistats_saf"); 
    fetchDataPublikasi();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        fetchDataPublikasi();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchDataPublikasi() async {
    setState(() {
      isLoading = true;
    });

    final String apiUrl = "http://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
         if (parsedResponse != null && parsedResponse['data'] != null && parsedResponse['data'].length > 1 && parsedResponse['data'][1] is List) {
            final publikasi = List<Map<String, dynamic>>.from(parsedResponse["data"][1]);

            SharedPreferences prefs = await SharedPreferences.getInstance();
            for (var item in publikasi) {
              final String postId = item['title'] ?? ''; 
              if (postId.isEmpty) {
                  item['isFavorited'] = false;
                  continue;
              }
              final String favoriteKey = 'favorite_publikasi_$postId';
              item['isFavorited'] = prefs.containsKey(favoriteKey);
            }

            if (mounted) { 
              setState(() {
                if (publikasi.isNotEmpty) {
                  dataPublikasi.addAll(publikasi);
                  currentPage++;
                } else {
                  hasMore = false;
                }
                isLoading = false;
              });
            }
        } else {
           print("Struktur data API publikasi tidak valid atau kosong.");
           if (mounted) setState(() { isLoading = false; hasMore = false; });
        }
      } else {
        if (mounted) { 
          setState(() {
            isLoading = false;
          });
        }
         Fluttertoast.showToast(msg: "Gagal memuat data publikasi.");
      }
    } catch(e) {
       print("Error fetchDataPublikasi: $e");
       if (mounted) { 
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg: "Gagal memuat data: $e");
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publikasi'),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading && dataPublikasi.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : dataPublikasi.isEmpty && !isLoading
              ? Center(child: Text("Tidak ada publikasi tersedia."))
              : GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3 / 4,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  itemCount: dataPublikasi.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == dataPublikasi.length) {
                      return hasMore
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox.shrink();
                    }

                    return Builder(
                      builder: (BuildContext itemContext) {
                        
                        final item = dataPublikasi[index];
                        final String title = item['title'] ?? 'Publikasi Tanpa Judul $index';
                        final String postId = title;
                        final bool isFavorited = item['isFavorited'] ?? false;

                        return GestureDetector(
                          onTap: () {
                            showDownloadDialog(
                              itemContext, 
                              item, 
                              (String updatedPostId, bool newStatus) {
                                final itemIndex = dataPublikasi.indexWhere((i) => (i['title'] ?? '') == updatedPostId);
                                if (itemIndex != -1 && mounted) { 
                                  setState(() {
                                    dataPublikasi[itemIndex]['isFavorited'] = newStatus;
                                  });
                                }
                              }
                            );
                          },
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
                            child: ClipRRect( 
                              borderRadius: BorderRadius.circular(12.0),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: Image.network(
                                          item['cover'] ?? '', 
                                          width: double.infinity,
                                          fit: BoxFit.fill,
                                          loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(child: CircularProgressIndicator());
                                          },
                                          errorBuilder: (context, error, stackTrace) =>
                                             Container(color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: dark1,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isFavorited)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white, 
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.grey.shade300, width: 1),
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 18, 
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }

  void showDownloadDialog(
    BuildContext context, 
    Map<String, dynamic> item, 
    Function(String postId, bool newStatus) onFavoriteChanged
  ) {
    final String title = item["title"] ?? "Tanpa Judul";
    final String postId = title;
    final String postType = 'publikasi'; 
    final String pdfUrl = item["pdf"] ?? "";
    final String abstract = item["abstract"] ?? "";
    final String size = item["size"] ?? "N/A";
    final String rlDate = item["rl_date"] ?? "N/A";

    bool? _isFavorited; 
    final String favoriteKey = 'favorite_${postType}_$postId';

    showDialog(
      context: context, 
      builder: (BuildContext dialogContextInner) { 
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) { 
            
            void checkInitialFavoriteStatus() async {
              if (_isFavorited != null) return; 
              try {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bool nowFavorited = prefs.containsKey(favoriteKey);
                 if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                    setDialogState(() {
                      _isFavorited = nowFavorited;
                    });
                 }
              } catch (e) {
                print("Error checking favorite status: $e");
                 if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                    setDialogState(() => _isFavorited = false);
                 }
              }
            }

            WidgetsBinding.instance?.addPostFrameCallback((_) {
               if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  checkInitialFavoriteStatus();
               }
            });

            void toggleFavorite() async {
              if (_isFavorited == null) return;
              try {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bool newStatus = !_isFavorited!; 
                if (newStatus) {
                  item['type'] = postType; 
                  item['favorited_at'] = DateTime.now().toIso8601String(); 
                  String jsonData = jsonEncode(item);
                  await prefs.setString(favoriteKey, jsonData);
                } else {
                  await prefs.remove(favoriteKey);
                }
                
                if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  setDialogState(() {
                    _isFavorited = newStatus; 
                  });
                }
                
                onFavoriteChanged(postId, newStatus); 

              } catch (e) {
                print("Error toggling favorite: $e");
              }
            }
            
            // --- PERUBAHAN TATA LETAK DI SINI ---
            List<Widget> mainButtons = [
              TextButton(
                onPressed: () => Navigator.pop(dialogContextInner), 
                child: const Text("Tutup"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContextInner); 
                  String fileName = title;
                  await downloadAndShowConfirmation(context, pdfUrl, fileName);
                },
                child: const Text("Unduh"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContextInner); 
                  openPdfDirectly(context, pdfUrl);
                },
                child: const Text("Buka PDF"),
              ),
            ];

            Widget favoriteButton = TextButton(
              onPressed: toggleFavorite, 
              child: _isFavorited == null
                ? Container(width: 20, height: 20, margin: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFavorited! ? Icons.favorite : Icons.favorite_border, 
                        color: _isFavorited! ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFavorited! ? 'Favorit' : 'Favoritkan', 
                        style: TextStyle(color: _isFavorited! ? Colors.red : Colors.grey[700]),
                      ),
                    ],
                  ),
            );
            // --- AKHIR PERUBAHAN TATA LETAK ---

            return AlertDialog(
              title: Text(
                title,
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
                            parse(HtmlUnescape().convert(abstract)).body?.text ?? '',
                            style: TextStyle(fontSize: 13, color: dark1),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ukuran Berkas: ${size.replaceAll('.', ',')}",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey
                            ),
                          ),
                          Text(
                            "Tanggal Rilis: $rlDate",
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
              actionsPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: mainButtons,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [favoriteButton],
                    )
                  ],
                )
              ],
            );
          }
        );
      },
    );
  }

  Future<void> downloadAndShowConfirmation(BuildContext context, String pdfUrl, String fileName) async {
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas publikasi sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        
        String safeFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        FileDownloader.downloadFile(
            url: pdfUrl,
            name: "$safeFileName.pdf",
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (fileName, double progress) {},
            onDownloadCompleted: (String path) {
              if (path.toLowerCase().endsWith('.php')) {
                  File downloadedFile = File(path);
                  String newPath = path.replaceAll('.php', '.pdf');
                  downloadedFile.renameSync(newPath);
              }

              Fluttertoast.showToast(
                msg: 'Publikasi "$safeFileName.pdf" telah disimpan dalam Folder Download.',
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
                backgroundColor: Colors.red,
                textColor: Colors.white,
                fontSize: 16.0,
              );
            });
      } catch (error) {
        Fluttertoast.showToast(
          msg: "Terjadi kesalahan saat mengunduh. $error",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Aplikasi belum diizinkan untuk mengakses penyimpanan.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;

      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
        try {
           await saf.getDirectoryPermission(isDynamic: true);
        } catch(e) {
           print("Error minta izin SAF (mungkin tidak disupport): $e");
        }
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  void openPdfDirectly(BuildContext context, String pdfUrl) {
    if (pdfUrl.isEmpty) {
       Fluttertoast.showToast(msg: "URL PDF tidak valid.");
       return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewer(pdfUrl: pdfUrl),
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
        leading: IconButton( 
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SfPdfViewer.network(
        pdfUrl,
         onDocumentLoadFailed: (details) {
            print("PDF Load Failed: ${details.description}");
            Fluttertoast.showToast(msg: "Gagal memuat PDF: ${details.description}");
        },
      ),
    );
  }
}

