import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service untuk mengambil dan mem-parsing data dari BPS Web API
/// URL Pattern: https://webapi.bps.go.id/v1/api/list/model/data/domain/{domain}/var/{varId}/th/1:/key/{apiKey}
///
/// Struktur JSON Response BPS:
/// {
///   "var": [{"val": 434, "label": "...", "unit": "Persen", "note": "Sumber: BPS Kota Malang"}],
///   "vervar": [{"val": 1, "label": "Q-to-Q"}, {"val": 2, "label": "Y-on-Y"}, ...],
///   "tahun": [{"val": 2015, "label": "2015"}, {"val": 2016, "label": "2016"}, ...],
///   "datacontent": {"43410000152015": 5.61, "43410000152016": 5.30, ...}
/// }
///
/// Key format datacontent: "{varId}{vervarVal}{domain5digit}{tahunVal}"
class BpsApiService {
  static const String _baseUrl = 'https://webapi.bps.go.id/v1/api/list';
  static const String _apiKey = '9db89e91c3c142df678e65a78c4e547f';
  static const String _domain = '3573'; // Kota Malang

  /// Mengambil data statistik dari BPS Web API
  /// [varId] = ID variabel statistik (misal: 434 = Laju Pertumbuhan Ekonomi)
  /// [maxYears] = Jumlah tahun terakhir yang ditampilkan (default: 10)
  static Future<BpsDataResult> fetchData({
    required int varId,
    int maxYears = 10,
  }) async {
    final url = '$_baseUrl/model/data/domain/$_domain/var/$varId/th/1:/key/$_apiKey';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return BpsDataResult.fromJson(json, maxYears: maxYears);
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Gagal mengambil data BPS: $e');
    }
  }
}

/// Model hasil parsing data BPS Web API
class BpsDataResult {
  final String title;       // Nama variabel (misal: "Laju Pertumbuhan Ekonomi")
  final String unit;        // Satuan (misal: "Persen")
  final String source;      // Sumber data (misal: "BPS Kota Malang")
  final List<String> years; // Label tahun ["2015", "2016", ...]
  final List<BpsSeriesData> series; // Data per kategori/vervar

  BpsDataResult({
    required this.title,
    required this.unit,
    required this.source,
    required this.years,
    required this.series,
  });

  factory BpsDataResult.fromJson(Map<String, dynamic> json, {int maxYears = 10}) {
    // 1. Parse metadata variabel
    final varList = json['var'] as List<dynamic>;
    final title = varList.isNotEmpty ? (varList[0]['label'] ?? '') : '';
    final unit = varList.isNotEmpty ? (varList[0]['unit'] ?? '') : '';
    final source = varList.isNotEmpty ? (varList[0]['note'] ?? '') : '';

    // 2. Parse kategori/vervar (kolom data: Q-to-Q, Y-on-Y, C-to-C, dll)
    final vervarList = json['vervar'] as List<dynamic>;
    final vervarLabels = vervarList.map((v) => v['label'] as String).toList();
    final vervarVals = vervarList.map((v) => v['val'].toString()).toList();

    // 3. Parse tahun
    final tahunList = json['tahun'] as List<dynamic>;
    final allYears = tahunList.map((t) => t['label'] as String).toList();
    final allYearVals = tahunList.map((t) => t['val'].toString()).toList();

    // Ambil N tahun terakhir saja
    final startIdx = allYears.length > maxYears ? allYears.length - maxYears : 0;
    final years = allYears.sublist(startIdx);
    final yearVals = allYearVals.sublist(startIdx);

    // 4. Parse datacontent (bisa berupa Map<String, dynamic>)
    final datacontentRaw = json['datacontent'];
    final Map<String, dynamic> datacontent = (datacontentRaw is Map) 
        ? Map<String, dynamic>.from(datacontentRaw) 
        : {};
    final List<dynamic> dcValuesList = datacontent.values.toList();

    // 5. Buat series data per vervar
    final varId = varList.isNotEmpty ? varList[0]['val'].toString() : '';
    final totalYearsCount = allYears.length;
    final List<BpsSeriesData> series = [];

    for (int v = 0; v < vervarVals.length; v++) {
      final List<double?> values = [];
      final vervarVal = vervarVals[v];

      for (int y = 0; y < yearVals.length; y++) {
        final yearVal = yearVals[y];
        final fullYearIndex = startIdx + y; // Index tahun pada allYears

        double? value;

        // Metrik 1: Key matching persis sesuai skema BPS Web API
        // Pattern utama BPS: {vervarVal}{varId}0{tahunVal}0
        final possibleKeys = [
          '$vervarVal${varId}0${yearVal}0',
          '$vervarVal$varId$yearVal',
          '$varId$vervarVal$yearVal',
          '$vervarVal${varId}0$yearVal',
          '$varId${vervarVal}0$yearVal',
          '$varId${vervarVal}000015$yearVal',
        ];

        for (final k in possibleKeys) {
          if (datacontent.containsKey(k)) {
            final raw = datacontent[k];
            value = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
            if (value != null) break;
          }
        }

        // Metrik 2: Fallback posisi urutan array (sama seperti Object.values di JS html)
        if (value == null && dcValuesList.isNotEmpty) {
          final posIndex = (v * totalYearsCount) + fullYearIndex;
          if (posIndex >= 0 && posIndex < dcValuesList.length) {
            final raw = dcValuesList[posIndex];
            value = (raw is num) ? raw.toDouble() : double.tryParse(raw.toString());
          }
        }

        values.add(value);
      }
      series.add(BpsSeriesData(label: vervarLabels[v], values: values));
    }

    return BpsDataResult(
      title: title,
      unit: unit,
      source: source,
      years: years,
      series: series,
    );
  }
}

/// Data satu seri/kolom (misal: "Q-to-Q" atau "Y-on-Y")
class BpsSeriesData {
  final String label;
  final List<double?> values;

  BpsSeriesData({required this.label, required this.values});
}
