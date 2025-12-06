/// Assessment Questions for Skill Classification
/// 
/// These questions are specifically designed for the initial proficiency assessment.
/// They follow a progressive difficulty curve and are calibrated to differentiate
/// between 5 skill levels: beginner, novice, intermediate, advanced, expert.
/// 
/// Question Design Principles:
/// 1. Clear, unambiguous wording
/// 2. One obviously correct answer
/// 3. Plausible distractors (common mistakes)
/// 4. Progressive difficulty (Q1-3 easy, Q4-6 medium, Q7-9 harder, Q10-12 advanced)
/// 5. Tests core Python concepts, not obscure trivia

/// Assessment questions ordered by difficulty (easiest first)
/// 12 questions total - enough to classify accurately, short enough to complete quickly
const List<Map<String, dynamic>> assessmentQuestions = [
  // ============================================
  // TIER 1: BEGINNER (Q1-3) - Basic syntax recognition
  // Anyone who has seen Python should get these
  // ============================================
  {
    "id": "assess_01",
    "difficulty": 1,
    "concept": "output",
    "question": "Which code correctly prints \"Hello\" to the screen?",
    "options": [
      "print(\"Hello\")",
      "echo \"Hello\"",
      "console.log(\"Hello\")",
      "printf(\"Hello\")"
    ],
    "correct": "print(\"Hello\")",
    "explanation": "In Python, print() is used to display output."
  },
  {
    "id": "assess_02",
    "difficulty": 1,
    "concept": "variables",
    "question": "How do you create a variable named 'age' with the value 25?",
    "options": [
      "age = 25",
      "int age = 25",
      "var age = 25",
      "let age = 25"
    ],
    "correct": "age = 25",
    "explanation": "Python uses simple assignment without type declarations."
  },
  {
    "id": "assess_03",
    "difficulty": 1,
    "concept": "arithmetic",
    "question": "What is the result of: 10 + 5 * 2",
    "options": [
      "20",
      "30",
      "25",
      "17"
    ],
    "correct": "20",
    "explanation": "Multiplication has higher precedence: 10 + (5 * 2) = 10 + 10 = 20"
  },

  // ============================================
  // TIER 2: NOVICE (Q4-6) - Basic control flow
  // Knows if/else, loops, basic syntax
  // ============================================
  {
    "id": "assess_04",
    "difficulty": 2,
    "concept": "conditionals",
    "question": "What is the correct way to check if x is greater than 10?",
    "options": [
      "if x > 10:",
      "if x > 10 then",
      "if (x > 10) {",
      "if x > 10 do"
    ],
    "correct": "if x > 10:",
    "explanation": "Python if statements end with a colon, no parentheses required."
  },
  {
    "id": "assess_05",
    "difficulty": 2,
    "concept": "loops",
    "question": "Which loop prints numbers 0, 1, 2, 3, 4?",
    "options": [
      "for i in range(5):\n    print(i)",
      "for i in range(1, 5):\n    print(i)",
      "for i in [5]:\n    print(i)",
      "for (i = 0; i < 5; i++):\n    print(i)"
    ],
    "correct": "for i in range(5):\n    print(i)",
    "explanation": "range(5) generates 0, 1, 2, 3, 4 (excludes the end value)."
  },
  {
    "id": "assess_06",
    "difficulty": 2,
    "concept": "comparison",
    "question": "What operator checks if two values are equal?",
    "options": [
      "==",
      "=",
      "===",
      "equals"
    ],
    "correct": "==",
    "explanation": "Double equals (==) compares values. Single equals (=) assigns values."
  },

  // ============================================
  // TIER 3: INTERMEDIATE (Q7-9) - Functions & data structures
  // Can write functions, use lists/dicts
  // ============================================
  {
    "id": "assess_07",
    "difficulty": 3,
    "concept": "functions",
    "question": "How do you define a function that takes two numbers and returns their sum?",
    "options": [
      "def add(a, b):\n    return a + b",
      "function add(a, b):\n    return a + b",
      "def add(a, b)\n    return a + b",
      "func add(a, b) => a + b"
    ],
    "correct": "def add(a, b):\n    return a + b",
    "explanation": "Python functions use 'def', followed by name, parameters in parentheses, and a colon."
  },
  {
    "id": "assess_08",
    "difficulty": 3,
    "concept": "lists",
    "question": "Given my_list = [10, 20, 30], what does my_list[1] return?",
    "options": [
      "20",
      "10",
      "30",
      "[20]"
    ],
    "correct": "20",
    "explanation": "Python lists are zero-indexed. Index 0 is 10, index 1 is 20."
  },
  {
    "id": "assess_09",
    "difficulty": 3,
    "concept": "strings",
    "question": "What does \"python\".upper() return?",
    "options": [
      "\"PYTHON\"",
      "\"Python\"",
      "\"python\"",
      "Error"
    ],
    "correct": "\"PYTHON\"",
    "explanation": "The upper() method converts all characters to uppercase."
  },

  // ============================================
  // TIER 4: ADVANCED (Q10-12) - Comprehensions, exceptions, modules
  // Understands Pythonic patterns
  // ============================================
  {
    "id": "assess_10",
    "difficulty": 4,
    "concept": "comprehensions",
    "question": "What does [x * 2 for x in range(3)] produce?",
    "options": [
      "[0, 2, 4]",
      "[2, 4, 6]",
      "[0, 1, 2]",
      "[1, 2, 3]"
    ],
    "correct": "[0, 2, 4]",
    "explanation": "List comprehension: range(3) gives 0,1,2. Each multiplied by 2 gives 0,2,4."
  },
  {
    "id": "assess_11",
    "difficulty": 4,
    "concept": "exceptions",
    "question": "How do you handle an error that might occur when converting user input to an integer?",
    "options": [
      "try:\n    num = int(input())\nexcept ValueError:\n    print(\"Invalid\")",
      "catch ValueError:\n    print(\"Invalid\")",
      "if error:\n    print(\"Invalid\")",
      "handle ValueError:\n    print(\"Invalid\")"
    ],
    "correct": "try:\n    num = int(input())\nexcept ValueError:\n    print(\"Invalid\")",
    "explanation": "Python uses try/except blocks for exception handling."
  },
  {
    "id": "assess_12",
    "difficulty": 4,
    "concept": "dictionaries",
    "question": "Given data = {\"name\": \"Alice\", \"age\": 30}, how do you safely get the \"city\" value with a default of \"Unknown\"?",
    "options": [
      "data.get(\"city\", \"Unknown\")",
      "data[\"city\"] or \"Unknown\"",
      "data.city ?? \"Unknown\"",
      "data.default(\"city\", \"Unknown\")"
    ],
    "correct": "data.get(\"city\", \"Unknown\")",
    "explanation": "The get() method returns the default value if the key doesn't exist."
  },
];

/// Scoring thresholds for skill classification based on assessment performance
/// 
/// Score Calculation:
/// - Each correct answer in tier 1-2 (easy): +1 point
/// - Each correct answer in tier 3 (medium): +2 points  
/// - Each correct answer in tier 4 (hard): +3 points
/// 
/// Maximum possible score: 6*1 + 3*2 + 3*3 = 6 + 6 + 9 = 21 points
/// 
/// Level Thresholds:
/// - Beginner: 0-5 points (struggles with basics)
/// - Novice: 6-10 points (knows basics, struggles with functions)
/// - Intermediate: 11-15 points (solid fundamentals)
/// - Advanced: 16-18 points (knows most concepts)
/// - Expert: 19-21 points (masters all concepts)
const Map<String, Map<String, int>> assessmentScoring = {
  "weights": {
    "tier1": 1,  // Questions 1-3
    "tier2": 1,  // Questions 4-6  
    "tier3": 2,  // Questions 7-9
    "tier4": 3,  // Questions 10-12
  },
  "thresholds": {
    "beginner": 0,      // 0-5 points
    "novice": 6,        // 6-10 points
    "intermediate": 11, // 11-15 points
    "advanced": 16,     // 16-18 points
    "expert": 19,       // 19-21 points
  },
  "maxScore": {
    "total": 21,
  }
};

/// Calculate weighted score from assessment answers
/// 
/// [answers] - List of 0 (incorrect) or 1 (correct) for each question
/// Returns total weighted score
int calculateAssessmentScore(List<int> answers) {
  if (answers.length != assessmentQuestions.length) {
    // Handle partial completion - score what we have
    int score = 0;
    for (int i = 0; i < answers.length && i < assessmentQuestions.length; i++) {
      if (answers[i] == 1) {
        final difficulty = assessmentQuestions[i]['difficulty'] as int;
        if (difficulty <= 2) {
          score += 1;  // Tier 1-2
        } else if (difficulty == 3) {
          score += 2;  // Tier 3
        } else {
          score += 3;  // Tier 4
        }
      }
    }
    return score;
  }
  
  int score = 0;
  for (int i = 0; i < answers.length; i++) {
    if (answers[i] == 1) {
      final difficulty = assessmentQuestions[i]['difficulty'] as int;
      if (difficulty <= 2) {
        score += 1;  // Tier 1-2: easy questions
      } else if (difficulty == 3) {
        score += 2;  // Tier 3: medium questions
      } else {
        score += 3;  // Tier 4: hard questions
      }
    }
  }
  return score;
}

/// Determine skill level from weighted score
String scoreToSkillLevel(int score) {
  if (score >= 19) return 'expert';
  if (score >= 16) return 'advanced';
  if (score >= 11) return 'intermediate';
  if (score >= 6) return 'novice';
  return 'beginner';
}

/// Get a human-readable description of the skill level
String getSkillLevelDescription(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return 'You\'re just starting out! We\'ll help you learn Python from the basics.';
    case 'novice':
      return 'You know the basics! Let\'s strengthen your foundation.';
    case 'intermediate':
      return 'Solid fundamentals! Time to tackle more complex concepts.';
    case 'advanced':
      return 'Great skills! Let\'s polish your Python expertise.';
    case 'expert':
      return 'Impressive! You\'re ready for advanced challenges.';
    default:
      return 'Let\'s start your Python journey!';
  }
}

/// Get the icon for each skill level (for UI)
String getSkillLevelEmoji(String level) {
  switch (level.toLowerCase()) {
    case 'beginner':
      return '🌱';
    case 'novice':
      return '📚';
    case 'intermediate':
      return '⚡';
    case 'advanced':
      return '🚀';
    case 'expert':
      return '👑';
    default:
      return '🐍';
  }
}
