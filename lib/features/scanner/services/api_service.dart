import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';

class ApiService {
  Future<FoodModel?> fetchFood(String query) async {
    final url =
    Uri.parse("https://api.edamam.com/api/nutrition-data?app_id=66cdea2f&app_key=62b29f436ef3eff0d20b4b896a62fb72&ingr=$query");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return FoodModel(
        name: query,
        calories: data['calories'] ?? 0,
      );
    }

    return null;
  }
}