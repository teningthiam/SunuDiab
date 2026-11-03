import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/glycemia.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';

/// Courbe de glycémie avec zone cible verte. [data] doit être en ordre chronologique.
class GlycemiaChart extends StatelessWidget {
  const GlycemiaChart({
    super.key,
    required this.data,
    required this.cmin,
    required this.cmax,
    this.compact = false,
    this.height = 200,
  });

  final List<Mesure> data;
  final double cmin;
  final double cmax;
  final bool compact;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return SizedBox(
        height: compact ? 90 : height,
        child: Center(
          child: Text(
            context.t('no_data_chart'),
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    final t0 = data.first.mesureLe;
    final spots = data
        .map(
          (m) => FlSpot(m.mesureLe.difference(t0).inMinutes / 1440.0, m.valeur),
        )
        .toList();
    final maxX = max(1.0, spots.last.x);
    final maxVal = data.map((m) => m.valeur).reduce(max);
    final maxY = max(1.8, maxVal + 0.2);
    const noTitles = AxisTitles(sideTitles: SideTitles(showTitles: false));

    return SizedBox(
      height: compact ? 90 : height,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: 0.4,
          maxY: maxY,
          gridData: FlGridData(show: !compact, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: !compact,
            topTitles: noTitles,
            rightTitles: noTitles,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                interval: 0.4,
                getTitlesWidget: (v, meta) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: max(1.0, (maxX / 5).ceilToDouble()),
                getTitlesWidget: (v, meta) {
                  final d = t0
                      .add(Duration(minutes: (v * 1440).round()))
                      .toLocal();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d/M').format(d),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          rangeAnnotations: RangeAnnotations(
            horizontalRangeAnnotations: [
              HorizontalRangeAnnotation(
                y1: cmin,
                y2: cmax,
                color: AppColors.greenSoft,
              ),
            ],
          ),
          lineTouchData: const LineTouchData(enabled: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: compact ? 3 : 4.5,
                      color: statusColor(data[index].statut),
                      strokeWidth: 1.5,
                      strokeColor: Colors.white,
                    ),
              ),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
