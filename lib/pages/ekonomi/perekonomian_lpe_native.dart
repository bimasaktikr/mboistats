import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mboistats/services/bps_api_service.dart';
import 'package:mboistats/theme.dart';

/// Versi NATIVE FLUTTER dari halaman Laju Pertumbuhan Ekonomi
/// Menggantikan WebView HTML + ApexCharts dengan Flutter Widget + fl_chart
///
/// Perbandingan Arsitektur:
/// [WebView] HTML file → localhost HTTP server → Chromium engine → ApexCharts JS → Canvas render
/// [Native]  HTTP GET JSON → Dart model → fl_chart LineChart widget → Skia/Impeller GPU render
class LajuPertumbuhanNative extends StatefulWidget {
  const LajuPertumbuhanNative({Key? key}) : super(key: key);

  @override
  State<LajuPertumbuhanNative> createState() => _LajuPertumbuhanNativeState();
}

class _LajuPertumbuhanNativeState extends State<LajuPertumbuhanNative> {
  BpsDataResult? _data;
  bool _isLoading = true;
  String? _errorMessage;

  // Warna seri chart (sama dengan warna di HTML ApexCharts: biru, oranye, abu)
  final List<Color> _seriesColors = [
    const Color(0xFF4472C4),
    const Color(0xFFED7D31),
    const Color(0xFFA5A5A5),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // var 434 = Laju Pertumbuhan Ekonomi Kota Malang
      final result = await BpsApiService.fetchData(varId: 434, maxYears: 10);
      if (mounted) {
        setState(() {
          _data = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laju Pertumbuhan Ekonomi'),
        leading: IconButton(
          icon: Image.asset('assets_v2/icons/back_arrow.png', width: 24, height: 24,
            color: isDark ? Colors.white : null),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: blueNormal))
          : _errorMessage != null
              ? _buildError()
              : _buildContent(isDark),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Gagal memuat data', style: pjsBold16),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', style: pjsRegular14, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                _fetchData();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final data = _data!;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul & Satuan
          _buildTitleCard(data, isDark, bgCard),
          const SizedBox(height: 16),

          // Grafik Garis (Line Chart) - Native fl_chart
          _buildChartCard(data, isDark, bgCard),
          const SizedBox(height: 16),

          // Tabel Data - Native Flutter DataTable
          _buildDataTableCard(data, isDark, bgCard),
          const SizedBox(height: 12),

          // Sumber Data
          if (data.source.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                data.source,
                style: pjsRegular14.copyWith(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : dark3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Card judul & deskripsi variabel
  Widget _buildTitleCard(BpsDataResult data, bool isDark, Color bgCard) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7F6000).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            data.title.toUpperCase(),
            style: pjsBold16.copyWith(
              color: const Color(0xFF7F6000),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (data.unit.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '(${data.unit})',
              style: pjsRegular14.copyWith(color: const Color(0xFF7F6000), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          if (data.series.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data.series.map((s) => s.label).join(', '),
              style: pjsRegular14.copyWith(color: const Color(0xFF7F6000), fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Card grafik garis menggunakan fl_chart (menggantikan ApexCharts JS)
  Widget _buildChartCard(BpsDataResult data, bool isDark, Color bgCard) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(data.series.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: _seriesColors[i % _seriesColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.series[i].label,
                    style: pjsRegular14.copyWith(fontSize: 11,
                      color: isDark ? Colors.white70 : dark2),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Line Chart
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(data),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.years.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              data.years[idx],
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white54 : const Color(0xFF7F6000),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : dark3,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: _buildLineBars(data),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final seriesIdx = spot.barIndex;
                        final label = data.series[seriesIdx].label;
                        return LineTooltipItem(
                          '$label\n${spot.y.toStringAsFixed(2)}%',
                          TextStyle(
                            color: _seriesColors[seriesIdx % _seriesColors.length],
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuat line bar data untuk fl_chart
  List<LineChartBarData> _buildLineBars(BpsDataResult data) {
    return List.generate(data.series.length, (seriesIdx) {
      final seriesData = data.series[seriesIdx];
      final spots = <FlSpot>[];

      for (int i = 0; i < seriesData.values.length; i++) {
        final val = seriesData.values[i];
        if (val != null) {
          spots.add(FlSpot(i.toDouble(), val));
        }
      }

      final color = _seriesColors[seriesIdx % _seriesColors.length];

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, bar, index) =>
              FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0),
        ),
        belowBarData: BarAreaData(show: false),
      );
    });
  }

  /// Card tabel data (menggantikan HTML <table>)
  Widget _buildDataTableCard(BpsDataResult data, bool isDark, Color bgCard) {
    final headerColor = const Color(0xFF7F6000);
    final rowColor1 = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFDBCFAF);
    final rowColor2 = isDark ? const Color(0xFF333333) : const Color(0xFFDBB958);

    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(headerColor),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          dataTextStyle: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF7F6000),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          columnSpacing: 20,
          columns: [
            const DataColumn(label: Text('TAHUN')),
            ...data.series.map((s) => DataColumn(
                  label: Text(s.label.toUpperCase(), textAlign: TextAlign.center),
                )),
          ],
          rows: List.generate(data.years.length, (rowIdx) {
            // Urutan terbalik: tahun terbaru di atas
            final reverseIdx = data.years.length - 1 - rowIdx;
            return DataRow(
              color: WidgetStateProperty.all(
                rowIdx % 2 == 0 ? rowColor1 : rowColor2,
              ),
              cells: [
                DataCell(Text(data.years[reverseIdx])),
                ...data.series.map((s) {
                  final val = s.values[reverseIdx];
                  return DataCell(Text(
                    val != null ? val.toStringAsFixed(2) : '-',
                    textAlign: TextAlign.center,
                  ));
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _calculateInterval(BpsDataResult data) {
    double maxVal = 0;
    for (final s in data.series) {
      for (final v in s.values) {
        if (v != null && v.abs() > maxVal) maxVal = v.abs();
      }
    }
    if (maxVal <= 5) return 1;
    if (maxVal <= 20) return 2;
    if (maxVal <= 50) return 5;
    return 10;
  }
}
