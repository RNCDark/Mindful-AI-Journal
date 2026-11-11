import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'journal_api_service.dart';

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
  const JournalHomeScreen({super.key, this.journalService});

  final JournalApiService? journalService;

  @override
  State<JournalHomeScreen> createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen>{
  final TextEditingController _entryController = TextEditingController();
  late final JournalApiService _journalService;
  http.Client? _ownedClient;
  bool _isAnalyzing = false;
  String? _sentimentResults;
  String? _aiFeedback;

  @override
  void initState() {
    super.initState();

    if (widget.journalService != null) {
      _journalService = widget.journalService!;
    } else {
      _ownedClient = http.Client();
      _journalService = JournalApiService(
        client: _ownedClient!,
      );
    }
  }


  @override
  void dispose() {
    _entryController.dispose();
    _ownedClient?.close();
    super.dispose();
  }


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
      // Update: Use the JournalApiService to handle the API call
      final data = await _journalService.analyzeEntry(text);

      if (!mounted) return;

      final sentimentData = data['Sentiment_summary'];

      setState(() {
        _sentimentResults =
            "${sentimentData['sentiment']} "
            "(${sentimentData['emotional_score']}/10)";

        _aiFeedback = data['ai_feedback'] ?? "No feedback provided.";
      });
    } catch (e){
      if (!mounted) return;

      _showErrorSnackBar(
        "Failed to analyze journal entry. "
        "Please check your connection or try again.\n"
        "Details: $e",
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
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