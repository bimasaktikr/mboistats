import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:saf/saf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

import '../theme.dart';

class CarouselPublikasi extends StatefulWidget {
  const CarouselPublikasi({Key? key}) : super(key: key);

  @override
  CarouselPublikasiState createState() => CarouselPublikasiState();
}

class CarouselPublikasiState extends State<CarouselPublikasi> {
  late Saf saf;
  List<Map<String, dynamic>> dataPublikasi = [];
  bool _isLoadingApi = true;

  @override
  void initState() {
    super.initState();
    saf = Saf("mboistats_saf");
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchData() async {
    if (mounted && !_isLoadingApi) {
      setState(() => _isLoadingApi = true);
    }
    try {
      final response = await http.get(Uri.parse(
          'http://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/1/key/9db89e91c3c142df678e65a78c4e547f'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null &&
            data['data'] != null &&
            data['data'].length > 1 &&
            data['data'][1] is List) {
          final publications =
              (data['data'][1] as List).cast<Map<String, dynamic>>();
          if (mounted) {
            setState(() {
              dataPublikasi = publications;
              _isLoadingApi = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoadingApi = false);
        }
      } else {
        if (mounted) setState(() => _isLoadingApi = false);
      }
    } catch (error) {
      if (mounted) setState(() => _isLoadingApi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoadingApi) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (dataPublikasi.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0),
          child: Text('Tidak ada publikasi tersedia.'),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(
            top: 24.0,
            bottom: 16.0,
          ),
          child: Text(
            'PUBLIKASI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CarouselSlider(
          options: CarouselOptions(
            height: 450,
            enlargeCenterPage: true,
            autoPlay: true,
            aspectRatio: 3 / 4,
            viewportFraction: 0.8,
          ),
          items: dataPublikasi.map((item) {
            final String imageUrl = item['cover'] ?? '';
            final String title = item['title'] ?? 'Tanpa Judul';
            return Consumer<SupabaseDbService>(
              builder: (consumerContext, dbService, child) {
                
                final String favoriteKey = dbService.generateItemId('publikasi', title);
                final bool isFavorited = dbService.favoriteIds.contains(favoriteKey);

                return Builder(builder: (BuildContext dialogContext) {
                  return GestureDetector(
                    onTap: () {
                      openDownloadConfirmation(
                        dialogContext, 
                        item,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              width: MediaQuery.of(context).size.width,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                      child: Icon(Icons.broken_image,
                                          size: 40, color: Colors.grey)),
                            ),
                            if (isFavorited) 
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey.shade300, width: 1),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
        try {
          await saf.getDirectoryPermission(isDynamic: true);
        } catch (e) {
          print("Error minta izin SAF (mungkin tidak disupport): $e");
        }
      }
      return permissionStatus.isGranted;
    }
    return true;
  }
  void openDownloadConfirmation(
      BuildContext context, 
      Map<String, dynamic> item,
  ) {

    final String title = item["title"] ?? "Tanpa Judul";
    final String postType = 'publikasi';
    final String pdfUrl = item["pdf"] ?? "";
    final String abstract = item["abstract"] ?? "";
    final String size = item["size"] ?? "N/A";
    final String rlDate = item["rl_date"] ?? "N/A";

    final String favoriteKey = context.read<SupabaseDbService>().generateItemId(postType, title);

    showDialog(
      context: context, 
      builder: (BuildContext dialogContextInner) {
        return Consumer<SupabaseDbService>(
          builder: (dialogConsumerContext, dbService, child) {
          
            final authService = dialogConsumerContext.read<SupabaseAuthService>();
            final bool isCurrentlyFavorited = dbService.favoriteIds.contains(favoriteKey);

            void toggleFavorite() async {
              bool isLoggedIn = authService.isLoggedIn();
              
              if (!isLoggedIn) {
                final navigator = Navigator.of(dialogConsumerContext);
                navigator.pop(); 
                showDialog(
                  context: context, 
                  builder: (context) => const AuthGuardDialog(),
                );
                return; 
              }
              
              try {
                if (isCurrentlyFavorited) {
                  await dbService.removeFavorite(postType, title);
                } else {
                  item['type'] = postType;
                  await dbService.addFavorite(item);
                }
              } catch (e) {
                print("Error toggling favorite: $e");
              }
            }
            
            List<Widget> mainButtons = [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContextInner, false);
                },
                child: const Text("Tutup"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContextInner);
                  await downloadAndShowConfirmation(context, pdfUrl, title);
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
              child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrentlyFavorited
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isCurrentlyFavorited ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isCurrentlyFavorited ? 'Favorit' : 'Favoritkan',
                          style: TextStyle(
                              color: isCurrentlyFavorited
                                  ? Colors.red
                                  : Colors.grey[700]),
                        ),
                      ],
                    ),
            );

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
                            parse(HtmlUnescape().convert(abstract))
                                    .body
                                    ?.text ??
                                '',
                            style: TextStyle(fontSize: 13, color: dark1),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ukuran Berkas: ${size.replaceAll('.', ',')}",
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            "Tanggal Rilis: $rlDate",
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
          },
        );
      },
    );
  }
  Future<void> downloadAndShowConfirmation(
      BuildContext context, String pdfUrl, String fileName) async {
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas publikasi sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        String safeFileName =
            fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
                msg:
                    'Publikasi "$safeFileName.pdf" telah disimpan dalam Folder Download.',
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 1,
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
                timeInSecForIosWeb: 1,
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
          timeInSecForIosWeb: 1,
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
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
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
          Fluttertoast.showToast(
              msg: "Gagal memuat PDF: ${details.description}");
        },
      ),
    );
  }
}