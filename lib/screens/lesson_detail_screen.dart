import 'package:flutter/material.dart';
import 'lessons_screen.dart';

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: const Color(0xFFFF8A3D),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFFBF5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8A3D),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              lesson.content,
              style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2D2D2D)),
            ),
          ],
        ),
      ),
    );
  }
}
