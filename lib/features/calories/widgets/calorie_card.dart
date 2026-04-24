import 'package:flutter/material.dart';
import '../models/calorie_model.dart';

class CalorieCard extends StatelessWidget {
  final CalorieEntry entry;
  final VoidCallback? onDelete;

  const CalorieCard({super.key, required this.entry, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFB6E388).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.restaurant_rounded, size: 22, color: Color(0xFF6BCB77)),
            ),
          ),

          const SizedBox(width: 14),

          // Name & macros
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'P: ${entry.protein.toStringAsFixed(1)}g  '
                  'C: ${entry.carbs.toStringAsFixed(1)}g  '
                  'F: ${entry.fat.toStringAsFixed(1)}g',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),

          // Calories
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.calories.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF6BCB77),
                ),
              ),
              if (onDelete != null)
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 16, color: Colors.black26),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
