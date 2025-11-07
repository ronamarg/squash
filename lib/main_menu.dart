import 'package:flutter/material.dart';
import 'quiz_screen.dart';

class MainMenuScreen extends StatelessWidget {
  final String level;
  final List<Map<String, dynamic>> questionsToLoad;

  const MainMenuScreen({super.key, required this.level, required this.questionsToLoad});

  @override
  Widget build(BuildContext context) {
    final displayLevel = (level.isEmpty) ? 'novice' : level;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Menu'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text('You were classified as', style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 8),
                    Text(displayLevel.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 8),
                    Text('Start practicing at the level best suited to you.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuizScreen(difficulty: displayLevel, questionsToLoad: questionsToLoad),
                ));
              },
              child: const Text('Practice', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // For now just pop back to onboarding (or exit); behavior kept simple per session
                Navigator.of(context).pop();
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
