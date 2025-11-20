import 'package:flutter/material.dart';
import 'lesson_detail_screen.dart';

class Lesson {
  final String title;
  final String summary;
  final String content;
  const Lesson({required this.title, required this.summary, required this.content});
}

final List<Lesson> beginnerLessons = [
  const Lesson(
    title: 'Variables',
    summary: 'Store and reuse values using names.',
    content: 'Variables let you label data so you can reuse it.\n\nPython creates a variable the moment you assign to a name:\n\n    count = 10\n    user_name = "Alice"\n    pi_approx = 3.14\n\nNaming Tips:\n- Use lowercase_with_underscores\n- Be descriptive (`total_score`, not `ts`)\n\nReassignment just points the name to a new value:\n    count = count + 1\n\nPython is dynamically typed: a name can reference any type over time (avoid overusing this flexibility).',
  ),
  const Lesson(
    title: 'Data Types',
    summary: 'Numbers, text, collections, and booleans.',
    content: 'Core built‑in types you will use:\n\nNumbers: int, float\n    lives = 3\n    speed = 4.5\n\nStrings: text data\n    greeting = "Hello"\n\nBooleans: logic values\n    is_active = True\n\nLists: ordered, changeable sequence\n    fruits = ["apple", "pear", "orange"]\n\nTuples: ordered, immutable\n    point = (10, 20)\n\nDictionaries: key-value pairs\n    scores = {"alice": 8, "bob": 5}\n\nUse type() to inspect:\n    type(fruits)  # list\n\nPick the simplest type that fits the job; prefer lists over custom string parsing.',
  ),
  const Lesson(
    title: 'Loops',
    summary: 'Repeat actions with for and while.',
    content: 'Loops let you execute code repeatedly.\n\nFor loop iterates over a sequence:\n    for fruit in fruits:\n        print(fruit)\n\nRange for counting/indexing:\n    for i in range(5):\n        print(i)  # 0..4\n\nWhile loop runs while a condition is True:\n    attempts = 0\n    while attempts < 3:\n        attempts += 1\n\nBreak / continue:\n    for n in range(10):\n        if n == 6: break  # stop loop\n        if n % 2 == 0: continue  # skip even\n        print(n)\n\nAvoid infinite loops: ensure the condition changes. Prefer for loops when you know the collection.',
  ),
];

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lessons'),
        backgroundColor: const Color(0xFFFF8A3D),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFFBF5),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: beginnerLessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final lesson = beginnerLessons[i];
          return InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LessonDetailScreen(lesson: lesson),
              ),
            ),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFB366).withValues(alpha: 0.4),
                    const Color(0xFFFF8A3D).withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book, color: Color(0xFFFF8A3D)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
