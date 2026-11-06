import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const AIJournal());
}

class AIJournal extends StatelessWidget {
  const AIJournal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Journaling Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        ),
        home: JournalHomeScreen(),
    );
  }
}

class JournalHomeScreen extends StatefulWidget {
  const JournalHomeScreen({super.key});

  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen>{
  final TextEditingController _entryController = TextEditingController();
  bool _isAnalyzing = false;
  String? _sentimentResults;
  String? _aiFeedback;

  Future<void> _submitEntry() async {
    final  text = _entryController.text.trim();
    if(text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your journal entry before submitting.")),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _sentimentResults = null;
      _aiFeedback = null;
    });

    try {
      // Replace with backend API endpoint
      // Note: if running on Windows desktop/web, 'http://127.0.0.1:8000/api/journal/analyze'
      final url = Uri.parse('http://127.0.0.1:8000/api/journal/analyze');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'entry_txt': text}), // Matches my Pydantic model
      );

      if(response.statusCode == 200){
        final data = jsonDecode(response.body);

        final sentimentData = data['Sentiment_summary'];

        setState(() {
          // Correctly map model/summary to UI
          _sentimentResults = "${sentimentData['sentiment']}" " (${sentimentData['emotional_score']}/10)";
          _aiFeedback = data['ai_feedback'] ?? "No feedback provided.";
        });
      } else {
        setState(() {
          _showErrorSnackBar("Server error: ${response.statusCode}. Failed to analyze journal entry. Please try again later.");
        });
      }
    } catch (e){
      setState(() {
        // Network timeout, connection refused, or other network-related issues
        _showErrorSnackBar("Could not connect to backend server. Make sure uvicorn is running and accessible. \nDetails: $e");
      });
    } finally{
      setState(() {
        _isAnalyzing = false;
      });
    }

  }

  // Helper method to display a bottom SnackBar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mindful AI Journal'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //User Prompt header
            Text(
              "How are you feeling today?",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            //Spacer
            const SizedBox(height: 8,),
            Text(
              "Write down your thoughts below. AI feedback will generate automatically upon submission.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 16,),
            //Journal Entry Input
            TextField(
              controller: _entryController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: "Start typing your journal entry here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)
                ),
                filled: true,
                fillColor: Colors.grey[50]
              ),
            ),
            const SizedBox(height: 16),

            // Action button
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _submitEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)
                ),
              ),
              icon: _isAnalyzing
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2,),
              )
              : const Icon(Icons.psychology),
              label: Text(
                _isAnalyzing ? "Analyzing Entry..." : "Analyze & Save Entry",
                style: const TextStyle(fontSize: 16),
              ),
            ),

            // Week 1 Stub Output UI Cards
            if(_sentimentResults != null) ...[
              Card(
                color: Colors.teal[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.teal),
                          SizedBox(width: 8,),
                          Text(
                            "Detected Sentiment",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          )
                        ],
                      ),
                      const SizedBox(height: 8,),
                      Text(_sentimentResults!)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12,),
              Card(
                color: Colors.indigo[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.indigo,),
                          SizedBox(width: 8,),
                          Text(
                            'AI Insights & Reflection',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8,),
                      Text(_aiFeedback!),
                    ],
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}