import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/review_card_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/spaced_repetition_service.dart';
import '../widgets/sr_widgets.dart';

/// Spaced Repetition Review Screen
/// 
/// Presents due cards for review using the SM-2 algorithm.
/// Tracks response time and quality for optimal scheduling.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final FirebaseService _firebase = FirebaseService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();
  
  bool _loading = true;
  String? _error;
  
  List<ReviewCard> _dueCards = [];
  int _currentIndex = 0;
  ReviewCard? _currentCard;
  
  // Session stats
  int _cardsReviewed = 0;
  int _correctCount = 0;
  final List<int> _qualities = [];
  
  // Answer state
  bool _showingAnswer = false;
  DateTime? _questionStartTime;
  final TextEditingController _answerController = TextEditingController();
  
  // User info
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadDueCards();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = _firebase.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Please sign in to review cards';
          _loading = false;
        });
        return;
      }

      final userData = await _firebase.getUserData(user.uid);
      final cards = await _srService.getDueCards(user.uid);
      
      setState(() {
        _user = userData;
        _dueCards = cards;
        _loading = false;
        if (cards.isNotEmpty) {
          _currentCard = cards[0];
          _questionStartTime = DateTime.now();
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cards: $e';
        _loading = false;
      });
    }
  }

  void _showAnswer() {
    setState(() {
      _showingAnswer = true;
    });
  }

  Future<void> _rateAnswer(int quality) async {
    if (_currentCard == null) return;
    
    final user = _firebase.currentUser;
    if (user == null) return;

    final responseTime = _questionStartTime != null 
        ? DateTime.now().difference(_questionStartTime!).inMilliseconds 
        : null;

    // Process the review
    await _srService.processReview(
      userId: user.uid,
      card: _currentCard!,
      isCorrect: quality >= 3,
      responseTimeMs: responseTime,
    );

    // Update session stats
    setState(() {
      _cardsReviewed++;
      _qualities.add(quality);
      if (quality >= 3) {
        _correctCount++;
      }
    });

    // Move to next card
    _nextCard();
  }

  void _nextCard() {
    setState(() {
      _currentIndex++;
      _showingAnswer = false;
      _answerController.clear();
      
      if (_currentIndex < _dueCards.length) {
        _currentCard = _dueCards[_currentIndex];
        _questionStartTime = DateTime.now();
      } else {
        _currentCard = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Review Session'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitDialog(),
        ),
        actions: [
          if (_dueCards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_dueCards.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDueCards,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_dueCards.isEmpty) {
      return _buildNoDueCards();
    }

    if (_currentCard == null) {
      return _buildSessionComplete();
    }

    return _buildReviewCard();
  }

  Widget _buildNoDueCards() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No cards due for review right now.\nCome back later!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionComplete() {
    final avgQuality = _qualities.isNotEmpty 
        ? _qualities.reduce((a, b) => a + b) / _qualities.length 
        : 0.0;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 80,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            ReviewSessionSummary(
              cardsReviewed: _cardsReviewed,
              correctCount: _correctCount,
              avgQuality: avgQuality,
              streakDay: _user?.currentStreak ?? 0,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                minimumSize: const Size(200, 50),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final card = _currentCard!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: _dueCards.isNotEmpty 
                ? (_currentIndex + 1) / _dueCards.length 
                : 0,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
          const SizedBox(height: 24),
          
          // Card info badges
          Row(
            children: [
              _buildBadge(card.conceptTag, Icons.label),
              const SizedBox(width: 8),
              _buildBadge('Difficulty: ${card.difficulty}', Icons.speed),
              if (card.daysOverdue > 0) ...[
                const SizedBox(width: 8),
                _buildBadge('${card.daysOverdue}d overdue', Icons.warning, 
                    color: Colors.orange),
              ],
            ],
          ),
          const SizedBox(height: 24),
          
          // Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.questionType == 'code_fix' ? 'Fix this code:' : 'Question:',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (card.questionText != null)
                  Text(
                    card.questionText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                if (card.questionData?['broken_code'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.questionData!['broken_code'].toString(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Answer section
          if (!_showingAnswer)
            _buildAnswerInput()
          else
            _buildAnswerRevealed(),
        ],
      ),
    );
  }

  Widget _buildAnswerInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Think of your answer, then tap to reveal:',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _showAnswer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text(
            'Show Answer',
            style: TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerRevealed() {
    final card = _currentCard!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Correct answer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Correct Answer:',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (card.correctAnswer != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.correctAnswer!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Rating buttons
        const Text(
          'How well did you recall this?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        
        // Quality buttons
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildRatingButton(0, 'Blackout', Colors.red),
            _buildRatingButton(1, 'Wrong', Colors.orange),
            _buildRatingButton(2, 'Almost', Colors.amber),
            _buildRatingButton(3, 'Hard', Colors.yellow),
            _buildRatingButton(4, 'Good', Colors.lightGreen),
            _buildRatingButton(5, 'Easy', Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingButton(int quality, String label, Color color) {
    return ElevatedButton(
      onPressed: () => _rateAnswer(quality),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.3),
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$quality',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? AppColors.accent).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color ?? AppColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.accent),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExitDialog() async {
    if (_cardsReviewed == 0) {
      Navigator.pop(context);
      return;
    }

    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('End Session?'),
        content: Text(
          'You\'ve reviewed $_cardsReviewed cards.\n'
          'Progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (exit == true && mounted) {
      Navigator.pop(context);
    }
  }
}
