import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MacroChart extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;

  const MacroChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;

    if (total == 0) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(color: Colors.black38),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          // Pie Chart
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: protein,
                    color: const Color(0xFF4D96FF),
                    title: '',
                    radius: 28,
                  ),
                  PieChartSectionData(
                    value: carbs,
                    color: const Color(0xFFFFE66D),
                    title: '',
                    radius: 28,
                  ),
                  PieChartSectionData(
                    value: fat,
                    color: const Color(0xFFFF9F1C),
                    title: '',
                    radius: 28,
                  ),
                ],
              ),
            ),
          ),

          // Legend
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(const Color(0xFF4D96FF), 'Protein',
                  '${protein.toStringAsFixed(1)}g'),
              const SizedBox(height: 8),
              _legend(const Color(0xFFFFE66D), 'Carbs',
                  '${carbs.toStringAsFixed(1)}g'),
              const SizedBox(height: 8),
              _legend(const Color(0xFFFF9F1C), 'Fat',
                  '${fat.toStringAsFixed(1)}g'),
            ],
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $value',
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
