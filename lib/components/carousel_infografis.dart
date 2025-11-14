import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
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
  
  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchData() async {
    // ... (Fungsi ini tidak berubah dari sebelumnya) ...
    if (mounted && !_isLoadingApi) {
      setState(() => _isLoadingApi = true);
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
    // --- HAPUS 'context.watch' DARI SINI ---
    // final favoriteIds = context.watch<SupabaseDbService>().favoriteIds; // <-- HAPUS

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

            // --- PERUBAHAN UTAMA: BUNGKUS CARD DENGAN CONSUMER ---
            return Consumer<SupabaseDbService>(
              builder: (consumerContext, dbService, child) {
                
                final String favoriteKey = dbService.generateItemId('infografis', title);
                final bool isFavorited = dbService.favoriteIds.contains(favoriteKey);

                return Builder(
                  builder: (BuildContext dialogContext) {
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
                              // Ikon ini sekarang AKAN SINKRON
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
                  },
                );
              },
            );
            // --- AKHIR PERUBAHAN UTAMA ---
          }).toList(),
        ),
      ],
    );
  }

  Future<bool> _checkPermission() async {
    // ... (Fungsi helper permission tidak berubah) ...
    if (Platform.isAndroid || Platform.isIOS) {
      var permissionStatus = await Permission.storage.status;
      if (permissionStatus.isDenied) {
        permissionStatus = await Permission.storage.request();
      }
      return permissionStatus.isGranted;
    }
    return true;
  }

  // --- Fungsi showDownloadDialog TIDAK BERUBAH dari sebelumnya ---
  // (Karena sudah menggunakan Consumer di dalamnya)
  void openDownloadConfirmation(
    BuildContext context, 
    Map<String, dynamic> item,
  ) {
    final String tautan = item['img'] ?? '';
    final String judul = item['title'] ?? 'Tanpa Judul';
    final String tglrilis = item['date'] ?? 'N/A';
    final String postType = 'infografis'; 

    final String favoriteKey = context.read<SupabaseDbService>().generateItemId(postType, judul);

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
                  await dbService.removeFavorite(postType, judul);
                } else {
                  item['type'] = postType; 
                  await dbService.addFavorite(item);
                }
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
                onPressed: () => Navigator.pop(dialogContextInner),
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
                judul,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              content: SingleChildScrollView(
                child: Row(
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(tautan,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                    height: 150,
                                    child: Center(
                                        child: CircularProgressIndicator()));
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image,
                                      size: 100, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(
                            "Tanggal Rilis: $tglrilis",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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


  // ... (Fungsi helper download dan checkPermission tidak berubah) ...
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