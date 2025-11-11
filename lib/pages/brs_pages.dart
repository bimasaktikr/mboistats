import 'package:flutter/material.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/components/footer.dart';
import 'package:mboistats/theme.dart';
import 'package:saf/saf.dart';
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:html/parser.dart' show parse;
import 'package:mboistats/services/firestore_service.dart';
import 'dart:async';
import 'package:mboistats/services/auth_service_custom.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
  final AuthServiceCustom _authService = AuthServiceCustom.instance;
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    saf = Saf("mboistats_saf");
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchDataBRS();
      }
    });
    fetchDataBRS();
    _subscribeToFavorites();
    _authService.currentUser.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _authService.currentUser.removeListener(_onAuthStateChanged);
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged() {
    _subscribeToFavorites();
  }

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

  Future<void> fetchDataBRS() async {
    if (!hasMore || isLoading) return;
    setState(() {
      isLoading = true;
    });

    final String apiUrl =
        "http://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/3573/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse != null &&
            parsedResponse['data'] != null &&
            parsedResponse['data'].length > 1 &&
            parsedResponse['data'][1] is List) {
          final brs =
              List<Map<String, dynamic>>.from(parsedResponse["data"][1]);
          if (mounted) {
            setState(() {
              if (brs.isNotEmpty) {
                dataBRS.addAll(brs);
                currentPage++;
              } else {
                hasMore = false;
              }
              isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => {isLoading = false, hasMore = false});
        }
      } else {
        if (mounted) setState(() => isLoading = false);
        Fluttertoast.showToast(msg: "Gagal memuat data BRS.");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Gagal memuat data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        // --- PERUBAIKAN DI SINI ---
        // 1. Matikan panah 'back' otomatis
        automaticallyImplyLeading: false,
        // 2. Hapus logo dari 'leading'
        leading: null, 
        // 3. Set rata kiri
        centerTitle: false, 
        // 4. Gunakan Row yang sama dengan HomePage
        title: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            Image.asset(
              'assets/images/Mbois-stat Logo_Fix Putih.png',
              width: 40, 
              height: 40,
            ),
            const SizedBox(width: 8), // Jarak konsisten 8
            const Text(
              'MBOIStatS+',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
        // --- AKHIR PERUBAIKAN ---
      ),
      body: Stack(
        children: [
          isLoading && dataBRS.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : dataBRS.isEmpty && !isLoading
                  ? const Center(child: Text("Tidak ada BRS tersedia."))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: dataBRS.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == dataBRS.length) {
                          return hasMore
                              ? const Center(child: CircularProgressIndicator())
                              : const SizedBox.shrink();
                        }
                        return _buildBRSCard(context, index);
                      },
                    ),
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Footer(),
          ),
        ],
      ),
    );
  }

  Widget _buildBRSCard(BuildContext context, int index) {
    return Builder(builder: (BuildContext itemContext) {
      final item = dataBRS[index];
      final String title = item['title'] ?? 'BRS Tanpa Judul $index';
      final String favoriteKey = 'favorite_brs_$title';
      final bool isFavorited = _favoriteIds.contains(favoriteKey);

      return GestureDetector(
        onTap: () {
          showDownloadDialog(
              itemContext, item, isFavorited,
              (String updatedPostId, bool newStatus) {
            final itemIndex = dataBRS
                .indexWhere((i) => (i['title'] ?? '') == updatedPostId);
            if (itemIndex != -1 && mounted) {
              setState(() {
                dataBRS[itemIndex]['isFavorited'] = newStatus;
              });
            }
          });
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
                        item['thumbnail'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.fill,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image,
                                    color: Colors.grey[400])),
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
                            maxLines: 5,
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
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1),
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
    });
  }

  void showDownloadDialog(
      BuildContext context,
      Map<String, dynamic> item,
      bool isCurrentlyFavorited,
      Function(String postId, bool newStatus) onFavoriteChanged) {
    final String title = item["title"] ?? "Tanpa Judul";
    final String postId = title;
    final String postType = 'brs';
    final String pdfUrl = item["pdf"] ?? "";
    final String abstract = item["abstract"] ?? "";
    final String size = item["size"] ?? "N/A";
    final String rlDate = item["rl_date"] ?? "N/A";

    bool? _isFavoritedInDialog = isCurrentlyFavorited;

    showDialog(
      context: context,
      builder: (BuildContext dialogContextInner) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            void toggleFavorite() async {
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
                          color: _isFavoritedInDialog!
                              ? Colors.red
                              : Colors.grey[600],
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
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          Text(
                            "Tanggal Rilis: $rlDate",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
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
          msg: "Berkas BRS sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
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
                  'BRS "$safeFileName.pdf" telah disimpan dalam Folder Download.',
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
          },
        );
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
        } catch (e) {
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
          Fluttertoast.showToast(
              msg: "Gagal memuat PDF: ${details.description}");
        },
      ),
    );
  }
}