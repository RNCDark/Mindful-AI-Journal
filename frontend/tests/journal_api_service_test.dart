import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_ai/journal_api_service.dart';

void main() {
  group('JournalApiService Tests', (){
    test('FE-01: Successfully analyzes a journal entry', () async {
      // Simulate a successful response from the backend
      final mockClient = MockClient((request) async {
        // Verify the request method endpoint
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://127.0.0.1:8000/api/journal/analyze',
        );

        // Verify the request body
        final requestBody = jsonDecode(request.body);
        expect(
          requestBody['entry_txt'],
          'I have had a wonderful day.'
        );

        // Return a successful response
        return http.Response(
          jsonEncode({
            'status': 'success',
            'Sentiment_summary': {
              'sentiment': 'Positive',
              'emotional_score': 9,
            },
            'ai_feedback': 'It sounds like you had a great day!'
          }),
          200,
        );
      });

      final service = JournalApiService(client: mockClient);

      try{
        final result = await service.analyzeEntry(
          'I have had a wonderful day.'
        );

        // Verify the parsed response
        expect(result['status'], 'success');
        expect(
          result['Sentiment_summary']['sentiment'],
          'Positive'
        );
        expect(
          result['Sentiment_summary']['emotional_score'],
          9
        );
        expect(
          result['ai_feedback'],
          'It sounds like you had a great day!'
        );
      } finally{
        mockClient.close();
      }
    });
  });
}