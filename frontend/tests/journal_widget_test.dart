import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_ai/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:journal_ai/journal_api_service.dart';
import 'dart:async';

void main(){
  const testAccessCode = 'test-participant-code';

  final accessCodeFinder = find.byKey(
    const Key('participantAccessCodeField'),
  );

  final journalEntryFinder = find.byKey(
    const Key('journalEntryField'),
  );


  final submitButtonFinder = find.text('Analyze Entry');

  group('Journal Widget Tests', (){
    testWidgets(
      'FW-01: Journal screen renders correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: JournalHomeScreen(),
          ),
        );

        // Verify the application title
        expect(
          find.text('Mindful AI Journal'),
          findsOneWidget,
        );

        // Verify the journal prompt
        expect(
          find.text('How are you feeling today?'),
          findsOneWidget,
        );

        // Verify both input fields are present
        expect(find.byType(TextField), findsNWidgets(2));

        // Verify participant access-code input
        expect(accessCodeFinder, findsOneWidget);

        // Verify journal entry input
        expect(journalEntryFinder, findsOneWidget);

        // Verify access code is masked
        final accessCodeField = tester.widget<TextField>(
          accessCodeFinder,
        );

        expect(accessCodeField.obscureText, isTrue);

        // Verify research privacy notice
        expect(
          find.textContaining('Research prototype:'),
          findsOneWidget,
        );

        // Verify the submission button
        expect(
          submitButtonFinder,
          findsOneWidget,
        );

        // Results should not appear before submission
        expect(
          find.text('Detected Sentiment'),
          findsNothing,
        );

        expect(
          find.text('AI Insights & Reflection'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'FW-02: Empty journal entry displays warning',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: JournalHomeScreen(),
          ),
        );

        // Find and press the submit button without entering text
        await tester.ensureVisible(submitButtonFinder);
        await tester.tap(submitButtonFinder);

        // Allow Flutter to process the UI update
        await tester.pump();

        // Verify the warning appears
        expect(
          find.text(
            'Please enter your journal entry before submitting.',
          ),
          findsOneWidget,
        );

        // Verify no analysis results are displayed
        expect(
          find.text('Detected Sentiment'),
          findsNothing,
        );

        expect(
          find.text('AI Insights & Reflection'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'FW-03: Successful submission displays AI results',
      (WidgetTester tester) async {
        // Create a mock backend response
        final mockClient = MockClient((request) async {
          expect(request.method, 'POST');

          expect(
            jsonDecode(request.body)['entry_txt'],
            'I had a wonderful day today.',
          );

          expect(
            request.headers['x-access-code'],
            testAccessCode,
          );

          return http.Response(
            jsonEncode({
              'status': 'success',
              'Sentiment_summary': {
                'sentiment': 'Positive',
                'emotional_score': 9,
              },
              'ai_feedback':
                  'It sounds like you had a wonderful day!',
            }),
            200,
          );
        });

        final journalService = JournalApiService(
          client: mockClient,
        );

        // Render the journal screen with the mock service
        await tester.pumpWidget(
          MaterialApp(
            home: JournalHomeScreen(
              journalService: journalService,
            ),
          ),
        );

        // Enter participant access code
        await tester.enterText(
          accessCodeFinder,
          testAccessCode,
        );

        // Enter a journal entry
        await tester.enterText(
          journalEntryFinder,
          'I had a wonderful day today.',
        );

        // Submit the entry
        await tester.ensureVisible(submitButtonFinder);
        await tester.tap(
          submitButtonFinder,
        );

        // Wait for the async request and UI updates
        await tester.pumpAndSettle();

        // Verify sentiment results
        expect(
          find.text('Detected Sentiment'),
          findsOneWidget,
        );

        expect(
          find.text('Positive (9/10)'),
          findsOneWidget,
        );

        // Verify personalized feedback
        expect(
          find.text('AI Insights & Reflection'),
          findsOneWidget,
        );

        expect(
          find.text(
            'It sounds like you had a wonderful day!',
          ),
          findsOneWidget,
        );

        // Verify the button returns to its normal state
        expect(
          submitButtonFinder,
          findsOneWidget,
        );

        // Clean up
        mockClient.close();
      },
    );

    testWidgets(
      'FW-04: Submit button is disabled during analysis',
      (WidgetTester tester) async {
        // Control when the simulated API response completes
        final completer = Completer<http.Response>();
        var requestCount = 0;

        final mockClient = MockClient((request) {
          requestCount++;
          return completer.future;
        });

        final journalService = JournalApiService(
          client: mockClient,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: JournalHomeScreen(
              journalService: journalService,
            ),
          ),
        );

        // Enter participant access code
        await tester.enterText(
          accessCodeFinder,
          testAccessCode,
        );

        // Enter a valid journal entry
        await tester.enterText(
          journalEntryFinder,
          'I feel productive today.',
        );

        // Submit the entry
        await tester.ensureVisible(submitButtonFinder);
        await tester.tap(
          submitButtonFinder,
        );

        // Process the loading-state update
        await tester.pump();

        // Verify loading indicator and text
        expect(
          find.text('Analyzing Entry...'),
          findsOneWidget,
        );

        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );

        // Verify the button is disabled
        final buttonFinder = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton,
        );

        final button = tester.widget<ElevatedButton>(
          buttonFinder,
        );

        expect(button.onPressed, isNull);
        expect(requestCount, 1);

        // Verify both input fields are disabled
        expect(
          tester.widget<TextField>(accessCodeFinder).enabled,
          isFalse,
        );

        expect(
          tester.widget<TextField>(journalEntryFinder).enabled,
          isFalse,
        );

        // Complete the simulated API request
        completer.complete(
          http.Response(
            jsonEncode({
              'status': 'success',
              'Sentiment_summary': {
                'sentiment': 'Positive',
                'emotional_score': 8,
              },
              'ai_feedback': 'Keep up the good work!',
            }),
            200,
          ),
        );

        await tester.pumpAndSettle();

        // Verify the button becomes enabled again
        final updatedButton = tester.widget<ElevatedButton>(
          buttonFinder,
        );

        // Verify both input fields are enabled again
        expect(
          tester.widget<TextField>(accessCodeFinder).enabled,
          isTrue,
        );

        expect(
          tester.widget<TextField>(journalEntryFinder).enabled,
          isTrue,
        );

        expect(updatedButton.onPressed, isNotNull);

        expect(
          submitButtonFinder,
          findsOneWidget,
        );

        // Verify only one API request occurred
        expect(requestCount, 1);

        mockClient.close();
      },
    );

    testWidgets(
      'FW-05: API failure displays an error message',
      (WidgetTester tester) async {
        // Simulate an internal server error
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'detail': 'Internal Server Error',
            }),
            500,
          );
        });

        final journalService = JournalApiService(
          client: mockClient,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: JournalHomeScreen(
              journalService: journalService,
            ),
          ),
        );

        await tester.enterText(
          accessCodeFinder,
          testAccessCode,
        );

        // Enter a valid journal entry
        await tester.enterText(
          journalEntryFinder,
          'I am feeling overwhelmed today.',
        );

        // Submit the entry
        await tester.ensureVisible(submitButtonFinder);
        await tester.tap(
          submitButtonFinder,
        );

        // Allow the request and error UI to update
        await tester.pumpAndSettle();

        // Verify that an error SnackBar is displayed
        expect(
          find.byType(SnackBar),
          findsOneWidget,
        );

        expect(
          find.textContaining('Failed to analyze journal entry'),
          findsOneWidget,
        );

        // No results should be displayed
        expect(
          find.text('Detected Sentiment'),
          findsNothing,
        );

        expect(
          find.text('AI Insights & Reflection'),
          findsNothing,
        );

        // The submit button should be enabled again
        final buttonFinder = find.byWidgetPredicate(
          (widget) => widget is ElevatedButton,
        );

        final button = tester.widget<ElevatedButton>(
          buttonFinder,
        );

        expect(button.onPressed, isNotNull);

        mockClient.close();
      },
    );

    testWidgets(
      'FW-06: Missing participant access code displays warning',
      (WidgetTester tester) async {
        var requestCount = 0;

        final mockClient = MockClient((request) async {
          requestCount++;

          return http.Response(
            'Unexpected API request',
            500,
          );
        });

        final journalService = JournalApiService(
          client: mockClient,
        );

        addTearDown(mockClient.close);

        await tester.pumpWidget(
          MaterialApp(
            home: JournalHomeScreen(
              journalService: journalService,
            ),
          ),
        );

        // Enter journal text without an access code
        await tester.enterText(
          journalEntryFinder,
          'I had a productive day today.',
        );

        // Submit the journal entry
        await tester.ensureVisible(submitButtonFinder);
        await tester.tap(submitButtonFinder);

        await tester.pumpAndSettle();

        // Verify access-code warning
        expect(
          find.text(
            'Please enter your participant access code.',
          ),
          findsOneWidget,
        );

        // Verify no backend request was made
        expect(requestCount, 0);

        // Verify no analysis results appear
        expect(
          find.text('Detected Sentiment'),
          findsNothing,
        );

        expect(
          find.text('AI Insights & Reflection'),
          findsNothing,
        );
      },
    );
  });
}