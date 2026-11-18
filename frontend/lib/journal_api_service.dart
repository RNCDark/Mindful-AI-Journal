import 'dart:convert';
import 'package:http/http.dart' as http;

class JournalApiService {
  final http.Client client;
  final String baseUrl;

  JournalApiService({
    required this.client,
    this.baseUrl = 'https://mindful-ai-journal.onrender.com',
  });

  Future<Map<String, dynamic>> analyzeEntry(
    String entryText, {
    required String accessCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/journal/analyze');

    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Access-Code': accessCode,
      },
      body: jsonEncode({'entry_txt': entryText}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid response format from server.');
      }

      return data;
    }

    if (response.statusCode == 401) {
      throw Exception('Invalid participant access code.');
    }

    if (response.statusCode == 429) {
      throw Exception('Too many requests. Please wait before trying again.');
    }

    throw Exception(
      'Server error: ${response.statusCode}. '
      'Failed to analyze journal entry.',
    );
  }
}
