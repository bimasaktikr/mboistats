import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mboistats/services/bps_api_service.dart';
import 'package:mboistats/theme.dart';

/// Reusable Native Flutter Widget untuk menampilkan data BPS Web API
/// Menggantikan WebView HTML + ApexCharts dengan Native fl_chart & DataTable.
class BpsNativeDataPage extends StatefulWidget {
  final String title;
  final int varId;
  final int maxYears;

  const BpsNativeDataPage({
    Key? key,
    required this.title,
    required this.varId,
    this.maxYears = 10,
  }) : super(key: key);

  @override
  State<BpsNativeDataPage> createState() => _BpsNativeDataPageState();
}

class _BpsNativeDataPageState extends State<BpsNativeDataPage> {
  BpsDataResult? _data;
  bool _isLoading = true;
  String? _errorMessage;

  // Curated color palette untuk grafik seri BPS
  final List<Color> _seriesColors = const [
    Color(0xFF4472C4),
    Color(0xFFED7D31),
    Color(0xFFA5A5A5),
    Color(0xFFFFC000),
    Color(0xFF5B9BD5),
    Color(0xFF70AD47),
    Color(0xFF264478),
    Color(0xFF9E480E),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await BpsApiService.fetchData(
        varId: widget.varId,
        maxYears: widget.maxYears,
      );
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
        title: Text(widget.title),
        leading: IconButton(
          icon: Image.asset(
            'assets_v2/icons/back_arrow.png',
            width: 24,
            height: 24,
            color: isDark ? Colors.white : null,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: blueNormal))
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    await _fetchData();
                  },
                  child: _buildContent(isDark),
                ),
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
            Text('Gagal memuat data BPS', style: pjsBold16),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', style: pjsRegular14, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Title & Unit Card
        _buildTitleCard(data, isDark),
        const SizedBox(height: 16),

        // Line Chart (fl_chart)
        _buildChartCard(data, isDark, bgCard),
        const SizedBox(height: 16),

        // Data Table (Native Flutter DataTable)
        _buildDataTableCard(data, isDark, bgCard),
        const SizedBox(height: 12),

        // Source Note
        if (data.source.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              data.source,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.white54 : dark3,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTitleCard(BpsDataResult data, bool isDark) {
    final displayTitle = data.title.isNotEmpty ? data.title : widget.title;

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
            displayTitle.toUpperCase(),
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
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(data.series.length, (i) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _seriesColors[i % _seriesColors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    data.series[i].label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : dark2,
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16),

          // Native fl_chart
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
                          _formatAxisValue(value),
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
                          '$label\n${_formatValue(spot.y)} ${data.unit}',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(headerColor),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                dataTextStyle: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF7F6000),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                columnSpacing: 16,
                columns: [
                  const DataColumn(
                    label: Expanded(
                      child: Text('TAHUN', textAlign: TextAlign.center),
                    ),
                  ),
                  ...data.series.map((s) => DataColumn(
                        label: Expanded(
                          child: Text(s.label.toUpperCase(), textAlign: TextAlign.center),
                        ),
                      )),
                ],
                rows: List.generate(data.years.length, (rowIdx) {
                  final reverseIdx = data.years.length - 1 - rowIdx;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      rowIdx % 2 == 0 ? rowColor1 : rowColor2,
                    ),
                    cells: [
                      DataCell(Center(child: Text(data.years[reverseIdx]))),
                      ...data.series.map((s) {
                        final val = s.values[reverseIdx];
                        return DataCell(Center(
                          child: Text(
                            val != null ? _formatValue(val) : '-',
                            textAlign: TextAlign.center,
                          ),
                        ));
                      }),
                    ],
                  );
                }),
              ),
            ),
          );
        },
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
    if (maxVal <= 20) return 4;
    if (maxVal <= 100) return 20;
    if (maxVal <= 1000) return 200;
    if (maxVal <= 100000) return 20000;
    return maxVal / 5;
  }

  String _formatValue(double val) {
    if (val >= 1000000) {
      return (val / 1000000).toStringAsFixed(2);
    } else if (val >= 1000) {
      return (val / 1000).toStringAsFixed(2);
    }
    return val.toStringAsFixed(2);
  }

  String _formatAxisValue(double val) {
    if (val >= 1000000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(1);
  }
}
