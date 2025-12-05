import 'package:flutter/material.dart';
import '../lesson_quiz_data.dart';
import 'quiz_screen.dart';
import 'lessons_screen.dart';
import '../config/theme.dart';

class LessonDetailScreen extends StatelessWidget {
  final Lesson lesson;
  final String lessonId;
  const LessonDetailScreen({super.key, required this.lesson, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        backgroundColor: AppColors.background,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                    gradient: AppGradients.subtle,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: AppTextStyles.headingL.copyWith(color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lesson.summary,
                        style: AppTextStyles.body.copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildStyledContent(lesson.content),
                const SizedBox(height: 28),
                _buildQuizCta(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuizCta(BuildContext context) {
    final questions = lessonQuizzes[lessonId] ?? const <LessonQuizQuestion>[];
    final hasQuiz = questions.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: hasQuiz ? AppGradients.cardAccent : AppGradients.subtle,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: hasQuiz ? 0.35 : 0.1),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: hasQuiz
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          difficulty: lesson.title,
                          questionsToLoad: questions.map((q) => {
                                'question': q.question,
                                'options': q.options,
                                'correct': q.correct,
                              }).toList(),
                          lessonId: lessonId,
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.quiz_outlined, color: Colors.white),
            label: Text(hasQuiz ? 'Take Quiz to Unlock Next' : 'Quiz Coming Soon'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: AppTextStyles.button.copyWith(fontSize: 16),
            ),
          ),
        ),
        if (!hasQuiz)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Quiz content is being prepared for this lesson.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
      ],
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
              style: AppTextStyles.headingM.copyWith(color: AppColors.accent),
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
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
                color: Color(0xFF8CF79E),
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
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.trim().substring(1).trim(),
                    style: AppTextStyles.body,
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
            style: AppTextStyles.body,
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
