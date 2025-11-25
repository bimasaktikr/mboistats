import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mboistats/theme.dart';
// HAPUS: 'package:saf/saf.dart';
import 'dart:convert';
// HAPUS: 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
// HAPUS: 'dart:io';
// HAPUS: 'package:permission_handler/permission_handler.dart';
// HAPUS: 'package:flutter_file_downloader/flutter_file_downloader.dart';
// HAPUS: 'package:html_unescape/html_unescape.dart';
// HAPUS: 'package:html/parser.dart' show parse;
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

// --- TAMBAHAN BARU ---
import 'package:mboistats/utils/download_helper.dart'; // Import helper baru kita

class PublikasiPage extends StatefulWidget {
  const PublikasiPage({Key? key}) : super(key: key);

  @override
  _PublikasiPageState createState() => _PublikasiPageState();
}

class _PublikasiPageState extends State<PublikasiPage> {
  // HAPUS: late Saf saf;
  List<Map<String, dynamic>> dataPublikasi = [];
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // HAPUS: saf = Saf("mboistats_saf");
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchDataPublikasi();
      }
    });
    fetchDataPublikasi();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  // CATATAN: Ini juga nanti akan diganti memanggil BpsApiService
  Future<void> fetchDataPublikasi() async {
    if (!hasMore || isLoading) return;
    setState(() => isLoading = true);
    final String apiUrl =
        "http://webapi.bps.go.id/v1/api/list/domain/3573/model/publication/lang/ind/page/$currentPage/key/9db89e91c3c142df678e65a78c4e547f";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final parsedResponse = json.decode(response.body);
        if (parsedResponse != null &&
            parsedResponse['data'] != null &&
            parsedResponse['data'].length > 1 &&
            parsedResponse['data'][1] is List) {
          final publikasi =
              List<Map<String, dynamic>>.from(parsedResponse["data"][1]);
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
          if (mounted) setState(() => {isLoading = false, hasMore = false});
        }
      } else {
        if (mounted) setState(() => isLoading = false);
        Fluttertoast.showToast(msg: "Gagal memuat data publikasi.");
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      Fluttertoast.showToast(msg: "Gagal memuat data: $e");
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
              ? const Center(child: Text("Tidak ada publikasi tersedia."))
              : GridView.builder(
                  // ... (GridView tidak berubah) ...
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 3 / 4,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  itemCount: dataPublikasi.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == dataPublikasi.length) {
                      return hasMore
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox.shrink();
                    }
                    
                    final item = dataPublikasi[index];
                    final String title =
                        item['title'] ?? 'Publikasi Tanpa Judul $index';
                    return Consumer<SupabaseDbService>(
                      builder: (consumerContext, dbService, child) {
                        
                        final String favoriteKey = dbService.generateItemId('publikasi', title);
                        final bool isFavorited = dbService.favoriteIds.contains(favoriteKey);

                        return GestureDetector(
                          onTap: () {
                            // --- PERUBAHAN DI SINI ---
                            // Panggil helper
                            final authService = consumerContext.read<SupabaseAuthService>();

                            DownloadHelper.showPublikasiDialog(
                              context: consumerContext, 
                              title: title, 
                              postType: 'publikasi', 
                              pdfUrl: item["pdf"] ?? "", 
                              abstract: item["abstract"] ?? "", 
                              size: item["size"] ?? "N/A", 
                              releaseDate: item["rl_date"] ?? "N/A", 
                              onToggleFavorite: () {
                                // Logika ini dipindahkan dari dalam dialog lama
                                bool isLoggedIn = authService.isLoggedIn();
                                if (!isLoggedIn) {
                                  Navigator.pop(consumerContext); // Tutup dialog
                                  showDialog(
                                    context: context, // Tampilkan dialog Auth
                                    builder: (context) => const AuthGuardDialog(),
                                  );
                                  return;
                                }
                                try {
                                  if (isFavorited) {
                                    dbService.removeFavorite('publikasi', title);
                                  } else {
                                    item['type'] = 'publikasi'; 
                                    dbService.addFavorite(item);
                                  }
                                } catch (e) {
                                  print("Error toggling favorite: $e");
                                }
                              }, 
                              isCurrentlyFavorited: isFavorited,
                            );
                            // --- AKHIR PERUBAHAN ---
                          },
                          child: Container(
                            // ... (Tampilan card tidak berubah) ...
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
                                        child: Image.network(
                                          item['cover'] ?? '',
                                          width: double.infinity,
                                          fit: BoxFit.fill,
                                          loadingBuilder:
                                              (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                      color: Colors.grey[200],
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
                  },
                ),
    );
  }

  // HAPUS: Semua metode di bawah ini telah dipindahkan ke DownloadHelper
  // void showDownloadDialog(...) { ... }
  // Future<void> downloadAndShowConfirmation(...) { ... }
  // Future<bool> _checkPermission() { ... }
  // void openPdfDirectly(...) { ... }
  // HAPUS: class PDFViewer { ... }
}