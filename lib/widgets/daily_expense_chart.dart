import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DailyExpenseChart extends StatefulWidget {
  final Map<String, double> data;

  const DailyExpenseChart({super.key, required this.data});

  @override
  State<DailyExpenseChart> createState() => _DailyExpenseChartState();
}

class _DailyExpenseChartState extends State<DailyExpenseChart> {
  final Set<int> _showingTooltips = {};

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final cardColor = theme.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = theme.isDarkMode ? Colors.white : Colors.black87;

    if (widget.data.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: theme.isDarkMode ? Colors.grey[700] : Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                "No expense data",
                style: TextStyle(
                  fontSize: 14,
                  color: theme.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final entries = widget.data.entries.map((e) {
      final d = DateTime.parse(e.key);
      return MapEntry(d.day.toDouble(), e.value);
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = entries.map((e) => FlSpot(e.key, e.value)).toList();
    final minX = entries.first.key;
    final maxX = entries.last.key;
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    const leftReserved = 48.0;
    const rightReserved = 12.0;
    const topReserved = 16.0;
    const bottomReserved = 28.0;

    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: theme.isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart,
                color: theme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Expenses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              final animatedSpots = spots
                  .map((s) => FlSpot(s.x, ui.lerpDouble(0, s.y, progress)!))
                  .toList();

              final animatedBar = LineChartBarData(
                spots: animatedSpots,
                isCurved: true,
                color: theme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                    radius: 4,
                    color: theme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.isDarkMode
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withOpacity(0.2),
                      theme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );

              return SizedBox(
                height: 220,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY * 1.15,
                      clipData: const FlClipData(
                          top: false, bottom: false, left: false, right: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            (maxY * 1.15 / 4).clamp(1, maxY * 1.15),
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.isDarkMode
                                ? Colors.grey.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false, reservedSize: topReserved),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false, reservedSize: rightReserved),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: leftReserved,
                            interval: (maxY * 1.15 / 4).clamp(1, maxY * 1.15),
                            getTitlesWidget: (val, _) {
                              final v = val.toInt();
                              if (v >= 1000) {
                                return Text("${v ~/ 1000}K",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    ));
                              }
                              return Text("$v",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.isDarkMode
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: bottomReserved,
                            interval: (maxX - minX) <= 7 ? 1 : 3,
                            getTitlesWidget: (v, _) =>
                                Text(v.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.isDarkMode
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                    )),
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        handleBuiltInTouches: false,
                        touchCallback:
                            (FlTouchEvent event, LineTouchResponse? response) {
                          // Only respond to tap up event (final tap)
                          if (event is FlTapUpEvent &&
                              response != null &&
                              response.lineBarSpots != null &&
                              response.lineBarSpots!.isNotEmpty) {
                            final spot = response.lineBarSpots!.first;
                            setState(() {
                              final index = spot.spotIndex;
                              if (_showingTooltips.contains(index)) {
                                _showingTooltips.remove(index);
                              } else {
                                _showingTooltips.add(index);
                              }
                            });
                          }
                        },
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (touchedSpot) => theme.isDarkMode
                              ? const Color(0xFF2D2D2D)
                              : Colors.white,
                          tooltipBorder: BorderSide(
                            color: theme.isDarkMode
                                ? Colors.grey[700]!
                                : theme.primary.withOpacity(0.2),
                            width: 1.5,
                          ),
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                formatter.format(spots[spot.spotIndex].y),
                                TextStyle(
                                  color: theme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      showingTooltipIndicators: _showingTooltips
                          .map((index) => ShowingTooltipIndicators([
                                LineBarSpot(
                                    animatedBar, 0, animatedSpots[index]),
                              ]))
                          .toList(),
                      lineBarsData: [animatedBar],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
