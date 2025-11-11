import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mboistats/theme.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/firestore_service.dart';
import 'dart:async'; 

// --- 1. TAMBAHKAN IMPORT AUTH SERVICE ---
import 'package:mboistats/services/auth_service_custom.dart';
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
  final FirestoreService _firestoreService = FirestoreService();

  // --- 2. TAMBAHKAN REFERENSI KE AUTH SERVICE ---
  final AuthServiceCustom _authService = AuthServiceCustom.instance;

  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;

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
    
    // --- 3. UBAH LOGIKA INIT ---
    _subscribeToFavorites();
    _authService.currentUser.addListener(_onAuthStateChanged);
    // --- AKHIR PERUBAHAN ---
  }

  @override
  void dispose() {
    _scrollController.dispose();
    
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

  Future<void> fetchDataInfografis() async {
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
          print("Struktur data API infografis tidak valid atau kosong.");
          if (mounted) setState(() => { isLoading = false, hasMore = false });
        }
      } else {
        print('Gagal load data infografis: ${response.statusCode}');
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetchDataInfografis: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: "Gagal memuat data infografis.");
        setState(() => isLoading = false);
      }
    }
  }

  void openDownloadConfirmation(
    BuildContext context,
    Map<String, dynamic> item,
    bool isCurrentlyFavorited, // <-- Terima status favorit saat ini
    Function(String postId, bool newStatus) onFavoriteChanged,
  ) {
    final String tautan = item['img'] ?? '';
    final String judul = item['title'] ?? 'Tanpa Judul';
    final String tglrilis = item['date'] ?? 'N/A';
    final String postId = judul;
    final String postType = 'infografis';

    print("DEBUG: Fungsi openDownloadConfirmation dipanggil untuk: $judul");

    bool? _isFavoritedInDialog = isCurrentlyFavorited;

    showDialog(
      context: context,
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
                  print("DEBUG: Disimpan ke favorit (Firestore): $postId");
                } else {
                  await _firestoreService.removeFavorite(postType, postId);
                  print("DEBUG: Dihapus dari favorit (Firestore): $postId");
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

  Future<void> downloadAndShowConfirmation(
      BuildContext context, String imgUrl, String fileName) async {
    // ... (Fungsi helper tidak berubah) ...
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

  @override
  Widget build(BuildContext context) {
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

                    return Builder(
                      builder: (BuildContext itemContext) {
                        final item = dataInfografis[index];
                        String imageUrl = item["img"] ?? '';
                        String title =
                            item["title"] ?? "Infografis Tanpa Judul $index";
                        
                        final String favoriteKey = 'favorite_infografis_$title';
                        bool isFavorited = _favoriteIds.contains(favoriteKey);

                        return GestureDetector(
                          onTap: () {
                            print(
                                "DEBUG: onTap terdeteksi untuk item: $title");

                            openDownloadConfirmation(
                              itemContext,
                              item,
                              isFavorited, // Kirim status favorit saat ini
                              (String updatedPostId, bool newStatus) {
                                final itemIndex = dataInfografis.indexWhere(
                                    (i) => (i['title'] ?? '') == updatedPostId);
                                if (itemIndex != -1 && mounted) {
                                  setState(() {
                                    dataInfografis[itemIndex]['isFavorited'] =
                                        newStatus;
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
                                  if (isFavorited) // Gunakan 'isFavorited' dari build method
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
                  },
                ),
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
}