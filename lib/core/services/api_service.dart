import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/indian_food_database.dart';

/// Service for fetching food nutrition data.
/// Primary source: local Indian food database (instant, offline).
/// Fallback: Open Food Facts filtered to Indian products.
class ApiService {
  static const _offBaseUrl =
      'https://world.openfoodfacts.org/cgi/search.pl';

  /// Search Indian food — local DB first, then Open Food Facts (India).
  /// Returns a combined list with local results first.
  static Future<List<IndianFood>> searchFood(String query) async {
    final local = IndianFoodDatabase.search(query);

    // Also try Open Food Facts with India country filter
    List<IndianFood> remote = [];
    try {
      final uri = Uri.parse(
        '$_offBaseUrl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&countries_tags_en=india'
        '&search_simple=1'
        '&action=process'
        '&json=1'
        '&page_size=10',
      );
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final products = (data['products'] as List<dynamic>? ?? []);

        for (final p in products) {
          final map = p as Map<String, dynamic>;
          final nutriments =
              map['nutriments'] as Map<String, dynamic>? ?? {};
          final rawName =
              (map['product_name'] as String? ?? '').trim();
          if (rawName.isEmpty) continue;

          final cal = (nutriments['energy-kcal_100g'] ??
                  nutriments['energy-kcal'] ??
                  0)
              .toDouble();
          if (cal <= 0) continue;

          // Skip if already in local results
          if (local.any(
              (f) => f.name.toLowerCase() == rawName.toLowerCase())) {
            continue;
          }

          remote.add(IndianFood(
            name: rawName,
            category: 'Other',
            calories: cal,
            protein:
                (nutriments['proteins_100g'] ?? 0).toDouble(),
            carbs: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            fat: (nutriments['fat_100g'] ?? 0).toDouble(),
            serving: map['serving_size'] as String? ?? '100g',
            servingGrams: 100,
          ));
        }
      }
    } catch (_) {
      // Network unavailable — local results are still returned
    }

    return [...local, ...remote];
  }
}
