import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_ai/main.dart';

void main(){
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

        // Verify the journal input field
        expect(
          find.byType(TextField),
          findsOneWidget,
        );

        // Verify the submission button
        expect(
          find.text('Analyze & Save Entry'),
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
        await tester.tap(find.text('Analyze & Save Entry'));

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
  });
}