import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/firestore_service.dart';
import 'dart:async'; 

// --- 1. TAMBAHKAN IMPORT AUTH SERVICE ---
import 'package:mboistats/services/auth_service_custom.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

import '../theme.dart';

class CarouselInfografis extends StatefulWidget {
  const CarouselInfografis({Key? key}) : super(key: key);

  @override
  CarouselInfografisState createState() => CarouselInfografisState();
}

class CarouselInfografisState extends State<CarouselInfografis> {
  List<Map<String, dynamic>> dataInfografis = [];
  bool _isLoadingApi = true;
  final FirestoreService _firestoreService = FirestoreService();

  // --- 2. TAMBAHKAN REFERENSI KE AUTH SERVICE ---
  final AuthServiceCustom _authService = AuthServiceCustom.instance;
  
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    
    fetchData();

    // --- 3. UBAH LOGIKA INIT ---
    _subscribeToFavorites();
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
    _subscribeToFavorites();
  }

  // --- 6. BUAT METODE SUBSCRIPTION TERPISAH ---
  void _subscribeToFavorites() {
    _favoriteSubscription?.cancel();
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
          'http://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/key/9db89e91c3c142df678e65a78c4e547f'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null &&
            data['data'] != null &&
            data['data'].length > 1 &&
            data['data'][1] is List) {
          final infographic =
              (data['data'][1] as List).cast<Map<String, dynamic>>();

          if (mounted) {
            setState(() {
              dataInfografis = infographic;
              _isLoadingApi = false;
            });
          }
        } else {
          print('Struktur data API infografis tidak sesuai.');
          if (mounted) setState(() => _isLoadingApi = false);
        }
      } else {
        print('Gagal mendapatkan data infografis. Kode: ${response.statusCode}');
        if (mounted) setState(() => _isLoadingApi = false);
      }
    } catch (error) {
      print('Error fetch data infografis: $error');
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
    if (dataInfografis.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 50.0),
          child: Text('Tidak ada infografis tersedia.'),
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
            'INFOGRAFIS',
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
          items: dataInfografis.map((item) {
            final String imageUrl = item['img'] ?? '';
            final String title = item['title'] ?? 'Tanpa Judul';

            final String favoriteKey = 'favorite_infografis_$title';
            final bool isFavorited = _favoriteIds.contains(favoriteKey);

            return Builder(
              builder: (BuildContext dialogContext) {
                return GestureDetector(
                  onTap: () {
                    openDownloadConfirmation(
                      dialogContext, // <-- context dari Builder
                      item,
                      isFavorited, // Kirim status favorit saat ini
                      (String updatedPostId, bool newStatus) {
                        final index = dataInfografis.indexWhere(
                            (i) => (i['title'] ?? '') == updatedPostId);
                        if (index != -1 && mounted) {
                          setState(() {
                            dataInfografis[index]['isFavorited'] = newStatus;
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
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  void openDownloadConfirmation(
    BuildContext context, // <-- Ini adalah 'dialogContext' dari Builder
    Map<String, dynamic> item,
    bool isCurrentlyFavorited, // <-- Terima status favorit saat ini
    Function(String postId, bool newStatus) onFavoriteChanged,
  ) {
    // Ekstrak data
    final String tautan = item['img'] ?? '';
    final String judul = item['title'] ?? 'Tanpa Judul';
    final String tglrilis = item['date'] ?? 'N/A';
    final String postId = judul;
    final String postType = 'infografis';

    print("DEBUG: Membuka dialog untuk postId: $postId, postType: $postType");

    bool? _isFavoritedInDialog = isCurrentlyFavorited;

    showDialog(
      context: context, // Gunakan context dari Builder
      builder: (BuildContext dialogContextInner) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            
            void toggleFavorite() async {
              // Auth Guard
              bool isLoggedIn = AuthServiceCustom.instance.isLoggedIn();
              if (!isLoggedIn) {
                final navigator = Navigator.of(dialogBuilderContext);
                navigator.pop(); 
                showDialog(
                  context: context, 
                  builder: (context) => const AuthGuardDialog(),
                );
                return;
              }

              // Lanjutkan jika login
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

            Future<void> handleDownload() async {
              Navigator.pop(dialogContextInner);
              await downloadAndShowConfirmation(this.context, tautan, judul);
            }

            List<Widget> mainButtons = [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContextInner);
                },
                child: const Text("Tutup"),
              ),
              TextButton(
                onPressed: handleDownload,
                child: Row(
                  children: const [
                    Icon(Icons.download, size: 18),
                    SizedBox(width: 4),
                    Text("Unduh"),
                  ],
                ),
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
                judul,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(tautan,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 100, color: Colors.grey),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()));
                        }),
                    const SizedBox(height: 8),
                    Text(
                      "Tanggal Rilis: $tglrilis",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
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

  // ... (Fungsi helper tidak berubah) ...
  Future<void> downloadAndShowConfirmation(BuildContext buildContext,
      String imgUrl, String fileName) async {
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas infografis sedang diunduh.",
        );

        String safeFileName =
            fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
        String extension = ".jpg";
        try {
          Uri uri = Uri.parse(imgUrl);
          String path = uri.path;
          int lastDot = path.lastIndexOf('.');
          if (lastDot != -1) {
            extension = path.substring(lastDot);
            int queryStart = extension.indexOf('?');
            if (queryStart != -1)
              extension = extension.substring(0, queryStart);
          }
          if (extension.isEmpty ||
              extension.length > 5 ||
              extension == '.php') extension = ".jpg";
        } catch (_) {
          extension = ".jpg";
        }

        FileDownloader.downloadFile(
            url: imgUrl.trim(),
            name: "$safeFileName$extension",
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (name, progress) {},
            onDownloadCompleted: (String path) {
              print('File downloaded to: $path');
              Fluttertoast.showToast(
                msg:
                    'Infografis $safeFileName$extension disimpan di Download.',
              );
            },
            onDownloadError: (String error) {
              print('Download Error: $error');
              Fluttertoast.showToast(
                msg: "Gagal mengunduh: $error",
              );
            });
      } catch (error) {
        print('Download Exception: $error');
        Fluttertoast.showToast(
          msg: "Terjadi kesalahan: $error",
        );
      }
    } else {
      Fluttertoast.showToast(
        msg: "Izin penyimpanan ditolak.",
      );
    }
  }
}