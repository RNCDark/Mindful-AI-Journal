import 'package:flutter/material.dart';

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

  void _submitEntry(){
    if(_entryController.text.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
    });

    // Mock API call for week 1
    //TODO::Connect to Python/OpenAI in Week 2
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isAnalyzing = false;
        _sentimentResults = "Positive / Reflective (Score: +0.78)";
        _aiFeedback = 
          "It sounds like you had a productive day working through challenges. "
          "Acknowledging your small wins is a great practice for emotional resilience!";
      });
    });
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