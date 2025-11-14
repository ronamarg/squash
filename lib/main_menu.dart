import 'package:flutter/material.dart';

import 'code_fix_quiz_screen.dart';

class MainMenuScreen extends StatelessWidget {
  final String level;
  final List<Map<String, dynamic>> questionsToLoad;

  const MainMenuScreen({super.key, required this.level, required this.questionsToLoad});

  @override
  Widget build(BuildContext context) {
    final displayLevel = (level.isEmpty) ? 'novice' : level;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          '_img/iconSqTEXT.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: Colors.orange,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Logo at the top - larger size
            Center(
              child: Image.asset(
                '_img/iconSqTEXT.png',
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            
            // User level card
            Card(
              elevation: 4,
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 48, color: Colors.orange),
                    const SizedBox(height: 12),
                    Text(
                      'Your Level',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayLevel.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Main gameplay button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size.fromHeight(64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CodeFixQuizScreen(difficulty: displayLevel),
                ));
              },
              icon: const Icon(Icons.code, size: 28),
              label: const Text(
                'Start Practice',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info text
            Text(
              'Fix buggy Python code and improve your debugging skills!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats/Info section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.bug_report,
                  label: 'AI-Generated',
                  value: 'Bugs',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.score,
                  label: 'Real-time',
                  value: 'Scoring',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.trending_up,
                  label: 'Adaptive',
                  value: 'Learning',
                ),
              ],
            ),
            
            const Spacer(),
            
            // Secondary actions
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Exit'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.orange, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
