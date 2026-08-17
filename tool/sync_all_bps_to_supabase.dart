import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

const String supabaseUrl = 'https://scjjsselrcynomyhdvyn.supabase.co';
const String supabaseAnonKey = 'sb_publishable_quE-cS4udgmoxFczxJOW9g_FaybcQjW';
const String bpsApiKey = '9db89e91c3c142df678e65a78c4e547f';
const String bpsDomain = '3573'; // Kota Malang

List<String> categorizeTitle(String title) {
  final text = title.toLowerCase();
  final sectors = <String>[];

  if (text.contains('inflasi') ||
      text.contains('pdrb') ||
      text.contains('ekonomi') ||
      text.contains('hotel') ||
      text.contains('penghunian') ||
      text.contains('tpk') ||
      text.contains('pariwisata') ||
      text.contains('wisatawan') ||
      text.contains('industri') ||
      text.contains('perusahaan') ||
      text.contains('usaha') ||
      text.contains('perdagangan') ||
      text.contains('ekspor') ||
      text.contains('impor') ||
      text.contains('konstruksi') ||
      text.contains('transportasi') ||
      text.contains('laju pertumbuhan') ||
      text.contains('keuangan')) {
    sectors.add('perekonomian');
  }

  if (text.contains('kemiskinan') || text.contains('miskin')) {
    sectors.add('kemiskinan');
  }

  if (text.contains('kerja') ||
      text.contains('pengangguran') ||
      text.contains('tpt') ||
      text.contains('tenaga') ||
      text.contains('upah') ||
      text.contains('buruh') ||
      text.contains('angkatan kerja')) {
    sectors.add('tenaga_kerja');
  }

  if (text.contains('ipm') ||
      text.contains('pembangunan manusia') ||
      text.contains('sekolah') ||
      text.contains('harapan hidup') ||
      text.contains('melek huruf') ||
      text.contains('pendidikan') ||
      text.contains('gender') ||
      text.contains('ketimpangan') ||
      text.contains('kesehatan')) {
    sectors.add('ipm');
  }

  if (text.contains('penduduk') ||
      text.contains('kecamatan') ||
      text.contains('dalam angka') ||
      text.contains('demografi') ||
      text.contains('kelahiran') ||
      text.contains('kematian') ||
      text.contains('migrasi') ||
      text.contains('sensus') ||
      text.contains('potensi desa') ||
      text.contains('statistik daerah')) {
    sectors.add('kependudukan');
  }

  if (text.contains('panen') ||
      text.contains('padi') ||
      text.contains('beras') ||
      text.contains('pertanian') ||
      text.contains('tanaman') ||
      text.contains('ternak') ||
      text.contains('perikanan') ||
      text.contains('hortikultura') ||
      text.contains('cabai') ||
      text.contains('jagung')) {
    sectors.add('pertanian');
  }

  if (text.contains('pengeluaran') ||
      text.contains('kesejahteraan') ||
      text.contains('gini') ||
      text.contains('konsumsi') ||
      text.contains('sosial') ||
      text.contains('rumah tangga') ||
      text.contains('susenas')) {
    sectors.add('kesejahteraan');
  }

  if (sectors.isEmpty) {
    sectors.add('perekonomian');
  }

  return sectors;
}

Future<void> upsertBatchToSupabase(List<Map<String, dynamic>> items) async {
  if (items.isEmpty) return;

  // De-duplicate within the batch itself to prevent PostgreSQL 21000 error
  final uniqueMap = <String, Map<String, dynamic>>{};
  for (var item in items) {
    uniqueMap[item['item_name']] = item;
  }
  final uniqueItems = uniqueMap.values.toList();

  final url = Uri.parse('$supabaseUrl/rest/v1/contents?on_conflict=item_name');
  final response = await http.post(
    url,
    headers: {
      'apikey': supabaseAnonKey,
      'Authorization': 'Bearer $supabaseAnonKey',
      'Content-Type': 'application/json',
      'Prefer': 'resolution=merge-duplicates',
    },
    body: json.encode(uniqueItems),
  );

  if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
    print('  -> Sukses upsert ${uniqueItems.length} item ke Supabase');
  } else {
    print('  -> Error upsert batch: ${response.statusCode} - ${response.body}');
  }
}

Future<void> syncBrs() async {
  print('\n=== 1. SYNCING BRS (Berita Resmi Statistik) ===');
  int page = 1;
  int totalPages = 1;
  int totalFetched = 0;

  while (page <= totalPages) {
    final url = 'https://webapi.bps.go.id/v1/api/list/model/pressrelease/lang/ind/domain/$bpsDomain/page/$page/key/$bpsApiKey';
    try {
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final parsed = json.decode(res.body);
        if (parsed['status'] == 'OK') {
          totalPages = parsed['data'][0]['pages'] ?? totalPages;
          final list = List<Map<String, dynamic>>.from(parsed['data'][1] ?? []);
          
          final batch = <Map<String, dynamic>>[];
          for (var item in list) {
            final title = (item['title'] ?? item['judul'] ?? '').toString().trim();
            if (title.isEmpty) continue;
            final cover = (item['thumbnail'] ?? item['img'] ?? item['cover'] ?? '').toString();
            final pdf = (item['pdf'] ?? item['dl'] ?? '').toString();
            
            batch.add({
              'item_name': title,
              'sector_categories': categorizeTitle(title),
              'action_type': 'view_pdf',
              'cover_url': cover,
              'content_url': pdf,
            });
          }
          
          await upsertBatchToSupabase(batch);
          totalFetched += batch.length;
          print('BRS Halaman $page/$totalPages ($totalFetched item)...');
        }
      }
    } catch (e) {
      print('Error fetching BRS page $page: $e');
    }
    page++;
    await Future.delayed(const Duration(milliseconds: 150));
  }
  print('=== BRS Selesai! Total: $totalFetched item ===');
}

Future<void> syncPublikasi() async {
  print('\n=== 2. SYNCING PUBLIKASI ===');
  int page = 1;
  int totalPages = 1;
  int totalFetched = 0;

  while (page <= totalPages) {
    final url = 'https://webapi.bps.go.id/v1/api/list/domain/$bpsDomain/model/publication/lang/ind/page/$page/key/$bpsApiKey';
    try {
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final parsed = json.decode(res.body);
        if (parsed['status'] == 'OK') {
          totalPages = parsed['data'][0]['pages'] ?? totalPages;
          final list = List<Map<String, dynamic>>.from(parsed['data'][1] ?? []);
          
          final batch = <Map<String, dynamic>>[];
          for (var item in list) {
            final title = (item['title'] ?? item['judul'] ?? '').toString().trim();
            if (title.isEmpty) continue;
            final cover = (item['cover'] ?? item['img'] ?? item['thumbnail'] ?? '').toString();
            final pdf = (item['pdf'] ?? item['dl'] ?? '').toString();
            
            batch.add({
              'item_name': title,
              'sector_categories': categorizeTitle(title),
              'action_type': 'view_pdf',
              'cover_url': cover,
              'content_url': pdf,
            });
          }
          
          await upsertBatchToSupabase(batch);
          totalFetched += batch.length;
          print('Publikasi Halaman $page/$totalPages ($totalFetched item)...');
        }
      }
    } catch (e) {
      print('Error fetching Publikasi page $page: $e');
    }
    page++;
    await Future.delayed(const Duration(milliseconds: 150));
  }
  print('=== Publikasi Selesai! Total: $totalFetched item ===');
}

Future<void> syncInfografis() async {
  print('\n=== 3. SYNCING INFOGRAFIS ===');
  int page = 1;
  int totalPages = 1;
  int totalFetched = 0;

  while (page <= totalPages) {
    final url = 'https://webapi.bps.go.id/v1/api/list/domain/$bpsDomain/model/infographic/lang/ind/domain/$bpsDomain/page/$page/key/$bpsApiKey';
    try {
      final res = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0'});
      if (res.statusCode == 200) {
        final parsed = json.decode(res.body);
        if (parsed['status'] == 'OK') {
          totalPages = parsed['data'][0]['pages'] ?? totalPages;
          final list = List<Map<String, dynamic>>.from(parsed['data'][1] ?? []);
          
          final batch = <Map<String, dynamic>>[];
          for (var item in list) {
            final title = (item['title'] ?? item['judul'] ?? '').toString().trim();
            if (title.isEmpty) continue;
            final img = (item['img'] ?? item['thumbnail'] ?? item['cover'] ?? '').toString();
            final dl = (item['dl'] ?? item['img'] ?? '').toString();
            
            batch.add({
              'item_name': title,
              'sector_categories': categorizeTitle(title),
              'action_type': 'download_file',
              'cover_url': img,
              'content_url': dl,
            });
          }
          
          await upsertBatchToSupabase(batch);
          totalFetched += batch.length;
          print('Infografis Halaman $page/$totalPages ($totalFetched item)...');
        }
      }
    } catch (e) {
      print('Error fetching Infografis page $page: $e');
    }
    page++;
    await Future.delayed(const Duration(milliseconds: 150));
  }
  print('=== Infografis Selesai! Total: $totalFetched item ===');
}

void main() async {
  print('Memulai proses Sinkronisasi Lengkap Data BPS Kota Malang ke Supabase contents...');
  final stopwatch = Stopwatch()..start();

  await syncBrs();
  await syncPublikasi();
  await syncInfografis();

  stopwatch.stop();
  print('\n🎉 SINKRONISASI SELESAI dalam ${stopwatch.elapsed.inSeconds} detik!');
  exit(0);
}
