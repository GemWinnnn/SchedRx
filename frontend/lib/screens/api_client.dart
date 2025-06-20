import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl =
      'http://127.0.0.1:8000'; // Change to your backend URL

  Future<List<dynamic>> fetchMedicines() async {
    final response = await http.get(Uri.parse('$baseUrl/medicines'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load medicines');
    }
  }
}
