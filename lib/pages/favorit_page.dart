import 'package:flutter/material.dart';
// HAPUS: import 'package:shared_preferences/shared_preferences.dart';
import 'package:mboistats/services/firestore_service.dart'; // <-- TAMBAH: Impor service baru
import 'package:mboistats/theme.dart';
import 'dart:convert'; // <-- Tetap diperlukan untuk dialog
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:html/parser.dart' show parse;
import 'package:html_unescape/html_unescape.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({Key? key}) : super(key: key);

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  // HAPUS: List<Map<String, dynamic>> _favoriteItems = [];
  // HAPUS: bool _isLoading = true;
  bool _didChange = false; // <-- TETAP DIPERLUKAN (untuk refresh HomePage saat pop)

  // TAMBAH: Buat instance dari service kita
  final FirestoreService _firestoreService = FirestoreService();

  // HAPUS: initState() dan _loadFavorites() tidak diperlukan lagi,
  // StreamBuilder akan menangani loading.

  Widget _buildFavoriteItem(BuildContext context, Map<String, dynamic> item) {
    // Tentukan tipe item
    final String itemType = item['type'] ?? 'unknown';
    final bool isPublikasi = itemType == 'publikasi';
    final bool isInfografis = itemType == 'infografis';
    final bool isBrs = itemType == 'brs';

    // Ambil data berdasarkan tipe
    final String title = item['title'] ?? 'Tanpa Judul';
    String imageUrl = '';
    String date = '';
    String typeLabel = 'Lainnya';
    Color typeColor = Colors.grey;

    if (isPublikasi) {
      imageUrl = item['cover'] ?? '';
      date = item['rl_date'] ?? '';
      typeLabel = 'Publikasi';
      typeColor = Colors.blue[700]!;
    } else if (isInfografis) {
      imageUrl = item['img'] ?? '';
      date = item['date'] ?? '';
      typeLabel = 'Infografis';
      typeColor = Colors.green[700]!;
    } else if (isBrs) {
      imageUrl = item['thumbnail'] ?? '';
      date = item['rl_date'] ?? '';
      typeLabel = 'BRS';
      typeColor = Colors.orange[700]!;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: InkWell(
          onTap: () {
            _showItemDialog(
                context,
                item,
                // PERUBAHAN: Saat favorit berubah, kita hanya perlu set _didChange.
                // StreamBuilder akan otomatis memperbarui UI.
                (String updatedPostId, bool newStatus) {
              setState(() {
                _didChange = true;
              });
              // HAPUS: _loadFavorites() atau _favoriteItems.removeWhere()
              // tidak diperlukan lagi.
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 70,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 90,
                        color: Colors.grey[200],
                        child: Icon(Icons.broken_image, color: Colors.grey[400])),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: semibold14.copyWith(color: dark1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Rilis: $date",
                        style: regular12_5.copyWith(color: dark3),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_didChange);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorit Saya'),
          leading: IconButton(
            icon: Image.asset('assets/icons/left-arrow.png', height: 25),
            onPressed: () => Navigator.of(context).pop(_didChange),
          ),
        ),
        // --- PERUBAHAN BESAR DI SINI ---
        // Ganti body lama dengan StreamBuilder
        body: StreamBuilder<List<Map<String, dynamic>>>(
          // 1. Dengarkan stream dari FirestoreService
          stream: _firestoreService.getFavoritesStream(),
          builder: (context, snapshot) {
            // 2. Tampilkan loading spinner saat menunggu
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // 3. Tampilkan error jika ada
            if (snapshot.hasError) {
              print("Error StreamBuilder Favorit: ${snapshot.error}");
              return Center(
                  child: Text('Terjadi kesalahan memuat favorit.',
                      style: regular14.copyWith(color: dark2)));
            }

            // 4. Tampilkan pesan jika data kosong
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'Anda belum memiliki item favorit.',
                  style: regular14.copyWith(color: dark2),
                ),
              );
            }

            // 5. Jika berhasil, ambil data dan bangun ListView
            final favoriteItems = snapshot.data!;
            return ListView.builder(
              itemCount: favoriteItems.length,
              itemBuilder: (context, index) {
                return _buildFavoriteItem(context, favoriteItems[index]);
              },
            );
          },
        ),
        // --- AKHIR PERUBAHAN ---
      ),
    );
  }

  void _showItemDialog(
      BuildContext context,
      Map<String, dynamic> item,
      Function(String postId, bool newStatus) onFavoriteChanged) {
    // --- PERUBAHAN LOGIKA ---
    // Ambil detail item untuk Firestore
    final String itemType = item['type'] ?? 'unknown';
    final String itemTitle = item["title"] ?? "Tanpa Judul";

    // Tambahkan flags berdasarkan tipe sehingga variabel seperti isBrs tersedia
    final bool isPublikasi = itemType == 'publikasi';
    final bool isInfografis = itemType == 'infografis';
    final bool isBrs = itemType == 'brs';

    // HAPUS: String postId = title;
    // HAPUS: String postType = item['type'];
    // HAPUS: String favoriteKey = 'favorite_${postType}_$postId';
    // --- AKHIR PERUBAHAN ---

    bool? _isFavorited;

    showDialog(
      context: context,
      builder: (BuildContext dialogContextInner) {
        return StatefulBuilder(
          builder: (dialogBuilderContext, setDialogState) {
            
            // --- PERUBAHAN LOGIKA ---
            void checkInitialFavoriteStatus() async {
              if (_isFavorited != null) return;
              try {
                // Ganti pengecekan SharedPreferences dengan Firestore
                bool isFav =
                    await _firestoreService.isFavorite(itemType, itemTitle);

                if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  setDialogState(() {
                    _isFavorited = isFav;
                  });
                }
              } catch (e) {
                print("Error checking favorite status: $e");
                if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  setDialogState(() => _isFavorited = false);
                }
              }
            }
            // --- AKHIR PERUBAHAN ---

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                checkInitialFavoriteStatus();
              }
            });

            // --- PERUBAHAN LOGIKA ---
            void toggleFavorite() async {
              if (_isFavorited == null) return;

              try {
                bool newStatus = !_isFavorited!;
                if (newStatus) {
                  // Kirim seluruh data item ke service
                  await _firestoreService.addFavorite(item);
                } else {
                  // Kirim key yang diperlukan untuk menghapus
                  await _firestoreService.removeFavorite(itemType, itemTitle);
                }

                if (ModalRoute.of(dialogBuilderContext)?.isCurrent ?? false) {
                  setDialogState(() {
                    _isFavorited = newStatus;
                  });
                }

                onFavoriteChanged(itemTitle, newStatus);
              } catch (e) {
                print("Error toggling favorite: $e");
              }
            }
            // --- AKHIR PERUBAHAN ---

            Widget dialogContent;
            List<Widget> dialogActions = []; // Tombol Aksi
            List<Widget> mainButtons = []; // Tombol baris pertama

            // Tombol Tutup (Umum)
            mainButtons.add(
              TextButton(
                onPressed: () => Navigator.pop(dialogContextInner),
                child: const Text("Tutup"),
              ),
            );

            // --- KONTEN DAN TOMBOL DINAMIS (TIDAK BERUBAH) ---
            if (isPublikasi || isBrs) {
              dialogContent = SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      parse(HtmlUnescape().convert(item["abstract"] ?? ""))
                              .body
                              ?.text ??
                          '',
                      style: TextStyle(fontSize: 13, color: dark1),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ukuran Berkas: ${item["size"]?.replaceAll('.', ',') ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      "Tanggal Rilis: ${item["rl_date"] ?? 'N/A'}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );

              mainButtons.addAll([
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContextInner);
                    await _downloadFile(context, item["pdf"] ?? "", itemTitle,
                        isPublikasi: true);
                  },
                  child: const Text("Unduh"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContextInner);
                    _openPdfDirectly(context, item["pdf"] ?? "");
                  },
                  child: const Text("Buka PDF"),
                ),
              ]);
            } else {
              dialogContent = SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(item['img'] ?? '',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image,
                                size: 100, color: Colors.grey),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                              height: 150,
                              child: Center(child: CircularProgressIndicator()));
                        }),
                    const SizedBox(height: 8),
                    Text(
                      "Tanggal Rilis: ${item['date'] ?? 'N/A'}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              );

              mainButtons.add(
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContextInner);
                    await _downloadFile(context, item["img"] ?? "", itemTitle,
                        isPublikasi: false);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.download, size: 18),
                      SizedBox(width: 4),
                      Text("Unduh"),
                    ],
                  ),
                ),
              );
            }
            // --- AKHIR KONTEN DINAMIS ---


            // Tombol Favorit (Baris kedua)
            Widget favoriteButton = TextButton(
              onPressed: toggleFavorite,
              child: _isFavorited == null
                  ? Container(
                      width: 20,
                      height: 20,
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isFavorited!
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _isFavorited! ? Colors.red : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isFavorited! ? 'Favorit' : 'Favoritkan',
                          style: TextStyle(
                              color: _isFavorited!
                                  ? Colors.red
                                  : Colors.grey[700]),
                        ),
                      ],
                    ),
            );

            dialogActions = [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: mainButtons,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [favoriteButton],
              )
            ];

            return AlertDialog(
              title: Text(
                itemTitle,
                textAlign: TextAlign.center,
                style: bold16.copyWith(color: dark1),
              ),
              content: dialogContent,
              actionsPadding:
                  EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              actions: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: dialogActions,
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNGSI HELPER (TIDAK BERUBAH) ---
  Future<void> _downloadFile(BuildContext context, String fileUrl, String fileName,
      {required bool isPublikasi}) async {
    if (fileUrl.isEmpty) {
      Fluttertoast.showToast(msg: "URL tidak valid.");
      return;
    }

    if (await _checkPermission()) {
      try {
        final String fileType = isPublikasi ? "Publikasi" : "Infografis";
        Fluttertoast.showToast(
          msg: "Berkas $fileType sedang diunduh.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );

        String extension = ".pdf";
        if (!isPublikasi) {
          try {
            Uri uri = Uri.parse(fileUrl);
            String path = uri.path;
            int lastDot = path.lastIndexOf('.');
            if (lastDot != -1) {
              extension = path.substring(lastDot);
              int queryStart = extension.indexOf('?');
              if (queryStart != -1)
                extension = extension.substring(0, queryStart);
            }
            if (extension.isEmpty || extension.length > 5 || extension == '.php')
              extension = ".jpg";
          } catch (_) {
            extension = ".jpg";
          }
        }

        String safeFileName =
            fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

        FileDownloader.downloadFile(
            url: fileUrl.trim(),
            name: "$safeFileName$extension",
            downloadDestination: DownloadDestinations.publicDownloads,
            onDownloadCompleted: (String path) {
              if (isPublikasi && path.toLowerCase().endsWith('.php')) {
                File downloadedFile = File(path);
                String newPath = path.replaceAll('.php', '.pdf');
                downloadedFile.renameSync(newPath);
              }
              Fluttertoast.showToast(
                msg:
                    '$fileType "$safeFileName$extension" disimpan di Download.',
              );
            },
            onDownloadError: (String error) {
              Fluttertoast.showToast(msg: "Gagal mengunduh: $error");
            });
      } catch (error) {
        Fluttertoast.showToast(msg: "Terjadi kesalahan: $error");
      }
    } else {
      Fluttertoast.showToast(msg: "Izin penyimpanan ditolak.");
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

  void _openPdfDirectly(BuildContext context, String pdfUrl) {
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