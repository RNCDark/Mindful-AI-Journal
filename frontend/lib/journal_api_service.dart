import 'dart:convert';
import 'package:http/http.dart' as http;

class JournalApiService {
  final http.Client client;
  final String baseUrl;

  JournalApiService({
    required this.client,
    this.baseUrl = 'http://127.0.0.1:8000',
  });

  Future<Map<String, dynamic>> analyzeEntry(String entryText) async {
    final url = Uri.parse('$baseUrl/api/journal/analyze');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'entry_txt': entryText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid response format from server.',
        );
      }

      return data;
    }

    throw Exception(
      'Server error: ${response.statusCode}. '
      'Failed to analyze journal entry.',
    );
  }
}