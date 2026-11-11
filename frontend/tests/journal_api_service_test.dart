import 'dart:convert';
import 'dart:io';
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

    test('FE-02: Handles server error correctly', () async {
      // Simulate a backend returning HTTP 500 error
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': 'An unexpected error occurred on the server.'
          }),
          500
        );
      });

      final service = JournalApiService(client: mockClient);

      try{
        expect(
          service.analyzeEntry('Today was a challenging day.'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'error message',
              contains('Server error: 500')
            )
          )
        );
      } finally{
        mockClient.close();
      }
    });
    test('FE-03: Handles malformed JSON responses', () async {
      final mockClient = MockClient((request) async {
        // Return a malformed JSON response
        return http.Response(
          'This is not valid JSON',
          200,
        );
      });

      final service = JournalApiService(client: mockClient);

      try{
        expect(
          service.analyzeEntry('I am feeling hopeful today.'),
          throwsA(isA<FormatException>()),
        );
      }finally{
        mockClient.close();
      }
    });

    test('FE-04: Rejects unexpected JSON structure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode([
            'Positive', 
            9, 
            'Great day!'
          ]),
          200,
        );
      });

      final service = JournalApiService(client: mockClient);

      try{
        expect(
          service.analyzeEntry('I am feeling hopeful today.'),
          throwsA(isA<FormatException>().having(
            (e) => e.message,
            'error message',
            contains('Invalid response format from server.')
          )),
        );
      }finally{
        mockClient.close();
      }
    });

    test('FE-05: Handles network connection failures gracefully', () async {
      // Simulate a network connection failure
      final moackClient = MockClient((request) async {
        throw const SocketException(
          'connectin refused',
        );
      });

      final service = JournalApiService(client: moackClient);

      try{
        await expectLater(
          service.analyzeEntry('Today was a good day.'),
          throwsA(isA<SocketException>()),
        );
      } finally{
        moackClient.close();
      }
    });
  });
}