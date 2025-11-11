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
import 'package:mboistats/services/firestore_service.dart';
import 'dart:async';

// --- 1. TAMBAHKAN IMPORT AUTH SERVICE ---
import 'package:mboistats/services/auth_service_custom.dart';
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
  final FirestoreService _firestoreService = FirestoreService();

  // --- 2. TAMBAHKAN REFERENSI KE AUTH SERVICE ---
  final AuthServiceCustom _authService = AuthServiceCustom.instance;
  
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    saf = Saf("mboistats_saf");
    
    fetchData();

    // --- 3. UBAH LOGIKA INIT ---
    // Panggil metode subscription yang baru
    _subscribeToFavorites();
    // Dengarkan perubahan auth
    _authService.currentUser.addListener(_onAuthStateChanged);
    // --- AKHIR PERUBAHAN ---
  }

  @override
  void dispose() {
    // --- 4. HENTIKAN LISTENER DAN SUBSCRIPTION ---
    _authService.currentUser.removeListener(_onAuthStateChanged);
    _favoriteSubscription?.cancel();
    // --- AKHIR PERUBAHAN ---
    
    super.dispose();
  }

  // --- 5. BUAT HANDLER PERUBAHAN AUTH ---
  void _onAuthStateChanged() {
    // Panggil _subscribeToFavorites lagi saat auth berubah
    // (misalnya, saat user logout)
    _subscribeToFavorites();
  }

  // --- 6. BUAT METODE SUBSCRIPTION TERPISAH ---
  void _subscribeToFavorites() {
    // Batalkan subscription lama jika ada
    _favoriteSubscription?.cancel();
    
    // Buat subscription baru. 
    // Getter 'favoriteIdsStream' akan mengecek status auth saat ini.
    // Jika logout, ia akan mengembalikan Stream.value({}).
    _favoriteSubscription = _firestoreService.favoriteIdsStream.listen((ids) {
      if (mounted) {
        setState(() {
          _favoriteIds = ids;
        });
      }
    });
  }
  // --- AKHIR PERUBAHAN ---

  Future<void> fetchData() async {
    if (mounted && !_isLoadingApi) {
      setState(() {
        _isLoadingApi = true;
      });
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
          print('Struktur data API publikasi tidak sesuai.');
          if (mounted) setState(() => _isLoadingApi = false);
        }
      } else {
        print('Gagal mendapatkan data publikasi. Kode: ${response.statusCode}');
        if (mounted) setState(() => _isLoadingApi = false);
      }
    } catch (error) {
      print('Error fetch data publikasi: $error');
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

            // Dapatkan status favorit dari state lokal (_favoriteIds)
            final String favoriteKey = 'favorite_publikasi_$title';
            final bool isFavorited = _favoriteIds.contains(favoriteKey);

            return Builder(builder: (BuildContext dialogContext) {
              return GestureDetector(
                onTap: () {
                  openDownloadConfirmation(
                    dialogContext, // <-- Perhatikan: context dari Builder
                    item,
                    isFavorited, // Kirim status favorit saat ini
                    (String updatedPostId, bool newStatus) {
                      // Callback ini tidak lagi diperlukan karena ada stream,
                      // tapi kita biarkan untuk update instan
                      final index = dataPublikasi.indexWhere(
                          (i) => (i['title'] ?? '') == updatedPostId);
                      if (index != -1 && mounted) {
                        setState(() {
                          dataPublikasi[index]['isFavorited'] = newStatus;
                        });
                      }
                    }
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
                        if (isFavorited) // Gunakan 'isFavorited' dari build method
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
      BuildContext context, // <-- Ini adalah 'dialogContext' dari Builder
      Map<String, dynamic> item,
      bool isCurrentlyFavorited, // <-- Terima status favorit saat ini
      Function(String postId, bool newStatus) onFavoriteChanged) {

    final String title = item["title"] ?? "Tanpa Judul";
    final String postId = title;
    final String postType = 'publikasi';
    final String pdfUrl = item["pdf"] ?? "";
    final String abstract = item["abstract"] ?? "";
    final String size = item["size"] ?? "N/A";
    final String rlDate = item["rl_date"] ?? "N/A";

    bool? _isFavoritedInDialog = isCurrentlyFavorited;

    showDialog(
      context: context, // Gunakan context dari Builder
      builder: (BuildContext dialogContextInner) {
        return StatefulBuilder(builder: (dialogBuilderContext, setDialogState) {
          
          void toggleFavorite() async {
            // Cek status login (Auth Guard)
            bool isLoggedIn = AuthServiceCustom.instance.isLoggedIn();
            if (!isLoggedIn) {
              final navigator = Navigator.of(dialogBuilderContext);
              navigator.pop(); // Tutup dialog saat ini
              // Tampilkan dialog login
              showDialog(
                context: context, // Gunakan context dari Builder (yang juga context utama)
                builder: (context) => const AuthGuardDialog(),
              );
              return; // Hentikan
            }
            
            // Jika login, lanjutkan seperti biasa
            if (_isFavoritedInDialog == null) return;
            try {
              bool newStatus = !_isFavoritedInDialog!;
              if (newStatus) {
                item['type'] = postType;
                await _firestoreService.addFavorite(item);
              } else {
                await _firestoreService.removeFavorite(postType, postId);
              }

              if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                setDialogState(() {
                  _isFavoritedInDialog = newStatus;
                });
              }
              
              onFavoriteChanged(postId, newStatus);
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
            child: _isFavoritedInDialog == null
                ? Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isFavoritedInDialog!
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _isFavoritedInDialog! ? Colors.red : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isFavoritedInDialog! ? 'Favorit' : 'Favoritkan',
                        style: TextStyle(
                            color: _isFavoritedInDialog!
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
        });
      },
    );
  }

  // ... (Fungsi helper tidak berubah) ...
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