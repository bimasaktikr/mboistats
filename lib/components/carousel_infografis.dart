import 'package:flutter/material.dart';
// HAPUS: 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
// HAPUS: 'dart:io';
// HAPUS: 'package:permission_handler/permission_handler.dart';
// HAPUS: 'package:fluttertoast/fluttertoast.dart';
import 'package:mboistats/services/supabase_db_service.dart';
import 'package:mboistats/services/supabase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:mboistats/components/auth_guard.dialog.dart';

import '../theme.dart';
// --- TAMBAHAN BARU ---
import 'package:mboistats/utils/download_helper.dart'; // Import helper baru kita

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

  // CATATAN: Ini juga nanti akan diganti memanggil BpsApiService
  Future<void> fetchData() async {
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
            return Consumer<SupabaseDbService>(
              builder: (consumerContext, dbService, child) {
                
                final String favoriteKey = dbService.generateItemId('infografis', title);
                final bool isFavorited = dbService.favoriteIds.contains(favoriteKey);

                return Builder(
                  builder: (BuildContext dialogContext) {
                    return GestureDetector(
                      onTap: () {
                        // --- PERUBAHAN DI SINI ---
                        // Panggil helper
                        final authService = consumerContext.read<SupabaseAuthService>();

                        DownloadHelper.showInfografisDialog(
                          context: consumerContext, 
                          title: title, 
                          imageUrl: item['img'] ?? '', 
                          releaseDate: item['date'] ?? 'N/A', 
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
                                dbService.removeFavorite('infografis', title);
                              } else {
                                item['type'] = 'infografis'; 
                                dbService.addFavorite(item);
                              }
                            } catch (e) {
                              print("Error toggling favorite: $e");
                            }
                          }, 
                          isCurrentlyFavorited: isFavorited
                        );
                        // --- AKHIR PERUBAHAN ---
                      },
                      child: Container(
                        // ... (Tampilan card tidak berubah) ...
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
                  },
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // HAPUS: Semua metode di bawah ini telah dipindahkan ke DownloadHelper
  // Future<bool> _checkPermission() { ... }
  // void openDownloadConfirmation(...) { ... }
  // Future<void> downloadAndShowConfirmation(...) { ... }
}