import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class NutritionResultCard extends StatelessWidget {
  final String foodName;
  final Map<String, dynamic> nutritionData;
  final VoidCallback? onAddToLog;

  const NutritionResultCard({
    super.key,
    required this.foodName,
    required this.nutritionData,
    this.onAddToLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Icon(Icons.restaurant_menu_rounded, size: 22, color: Color(0xFF6BCB77))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  foodName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Nutrition grid
          const Text('Nutrition Facts (per serving)',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _nutrientTile('Calories',
                  '${nutritionData['calories'] ?? 0} kcal',
                  const Color(0xFFFF9F1C)),
              _nutrientTile('Protein',
                  '${nutritionData['protein'] ?? 0}g',
                  const Color(0xFF4D96FF)),
              _nutrientTile('Carbs',
                  '${nutritionData['carbs'] ?? 0}g',
                  const Color(0xFFFFE66D)),
              _nutrientTile(
                  'Fat', '${nutritionData['fat'] ?? 0}g',
                  const Color(0xFFFF6B6B)),
              _nutrientTile('Fibre',
                  '${nutritionData['fibre'] ?? 0}g',
                  const Color(0xFF6BCB77)),
              _nutrientTile('Sugar',
                  '${nutritionData['sugar'] ?? 0}g',
                  const Color(0xFFB6E388)),
            ],
          ),

          const SizedBox(height: 16),

          // Add to log button
          if (onAddToLog != null)
            GestureDetector(
              onTap: onAddToLog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Center(
                  child: Text(
                    '+ Add to Calorie Log',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _nutrientTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black45)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
