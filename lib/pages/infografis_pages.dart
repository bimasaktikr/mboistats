import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/theme.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

class InfografisPages extends StatefulWidget {
  const InfografisPages({Key? key}) : super(key: key);

  @override
  _InfografisPagesState createState() => _InfografisPagesState();
}

class _InfografisPagesState extends State<InfografisPages> {
  List<Map<String, dynamic>> dataInfografis = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchDataInfografis();
      }
    });
    
    fetchDataInfografis();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchDataInfografis() async {
    // ... (Fungsi ini tidak berubah dari sebelumnya) ...
    if (!hasMore || isLoading) return;
    setState(() => isLoading = true);
    final String apiUrl =
        "http://webapi.bps.go.id/v1/api/list/domain/3573/model/infographic/lang/ind/domain/3573/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse != null &&
            parsedResponse['data'] != null &&
            parsedResponse['data'].length > 1 &&
            parsedResponse['data'][1] is List) {
          final List<dynamic> infografis = parsedResponse["data"][1];
          if (mounted) {
            setState(() {
              if (infografis.isNotEmpty) {
                currentPage++;
                dataInfografis
                    .addAll(List<Map<String, dynamic>>.from(infografis));
              } else {
                 hasMore = false;
              }
              isLoading = false; 
            });
          }
        } else {
          if (mounted) setState(() => { isLoading = false, hasMore = false });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(msg: "Gagal memuat data infografis.");
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- HAPUS 'context.watch' DARI SINI ---
    // final favoriteIds = context.watch<SupabaseDbService>().favoriteIds; // <-- HAPUS

    return Scaffold(
      appBar: AppBar(
        title: const Text('Infografis'),
        leading: IconButton(
          icon: Image.asset('assets/icons/left-arrow.png', height: 25),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading && dataInfografis.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : dataInfografis.isEmpty && !isLoading
              ? const Center(child: Text("Tidak ada infografis tersedia."))
              : GridView.builder(
                  controller: _scrollController,
                  itemCount: dataInfografis.length + (hasMore ? 1 : 0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    if (index == dataInfografis.length) {
                      return hasMore
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox.shrink();
                    }
                    
                    final item = dataInfografis[index];
                    String imageUrl = item["img"] ?? '';
                    String title =
                        item["title"] ?? "Infografis Tanpa Judul $index";
                    
                    // --- PERUBAHAN UTAMA: BUNGKUS CARD DENGAN CONSUMER ---
                    return Consumer<SupabaseDbService>(
                      builder: (consumerContext, dbService, child) {
                        
                        final String favoriteKey = dbService.generateItemId('infografis', title);
                        bool isFavorited = dbService.favoriteIds.contains(favoriteKey);

                        return GestureDetector(
                          onTap: () {
                            openDownloadConfirmation(
                              context, // Gunakan context dari itemBuilder
                              item,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: imageUrl.isEmpty
                                            ? Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.grey[400]))
                                            : Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return const Center(
                                                      child:
                                                          CircularProgressIndicator());
                                                },
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                        color:
                                                            Colors.grey[200],
                                                        child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors
                                                                .grey[400])),
                                              ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
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
                                  // Ikon ini sekarang AKAN SINKRON
                                  if (isFavorited) 
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.grey.shade300,
                                              width: 1),
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
                    // --- AKHIR PERUBAHAN UTAMA ---
                  },
                ),
    );
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
              await downloadAndShowConfirmation(context, tautan, judul);
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
  Future<void> downloadAndShowConfirmation(
      BuildContext context, String imgUrl, String fileName) async {
    if (await _checkPermission()) {
      try {
        Fluttertoast.showToast(
          msg: "Berkas infografis sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.blue,
          textColor: Colors.white,
          fontSize: 16.0,
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
              extension.contains('/') ||
              extension == '.php') extension = ".jpg";
        } catch (_) {
          extension = ".jpg";
        }
        FileDownloader.downloadFile(
            url: imgUrl.trim(),
            name: "$safeFileName$extension",
            downloadDestination: DownloadDestinations.publicDownloads,
            onProgress: (name, double progress) {},
            onDownloadCompleted: (String path) {
              Fluttertoast.showToast(
                msg:
                    'Infografis $safeFileName$extension disimpan di Download.',
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
                msg: "Gagal mengunduh berkas: $error",
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
          msg: "Terjadi kesalahan saat mengunduh: $error",
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
        msg: "Izin penyimpanan ditolak.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
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
      }
      return permissionStatus.isGranted;
    }
    return true;
  }
}