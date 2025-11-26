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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF8A3D).withValues(alpha: 0.1),
                    const Color(0xFFFFB366).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF8A3D).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF8A3D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.summary,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Content with styling
            _buildStyledContent(lesson.content),
          ],
        ),
      ),
    );
  }

  Widget _buildStyledContent(String content) {
    final lines = content.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Empty lines
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Section headers (lines that start with a number and period)
      if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        widgets.add(const SizedBox(height: 16));
        widgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A3D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border(
                left: BorderSide(
                  color: const Color(0xFFFF8A3D),
                  width: 4,
                ),
              ),
            ),
            child: Text(
              line.trim(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF8A3D),
              ),
            ),
          ),
        );
        widgets.add(const SizedBox(height: 12));
        continue;
      }

      // Code blocks (lines with significant indentation)
      if (line.startsWith('   ')) {
        widgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              line.trimLeft(),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Courier',
                color: Color(0xFF4AF626),
                height: 1.5,
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet points (lines starting with -)
      if (line.trim().startsWith('-')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8A3D),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.trim().substring(1).trim(),
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Regular paragraph text
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
