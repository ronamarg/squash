import 'package:flutter/foundation.dart';

/// Simple MCQ structure for lesson-locked quizzes.
@immutable
class LessonQuizQuestion {
  final String question;
  final List<String> options;
  final String correct;

  const LessonQuizQuestion({
    required this.question,
    required this.options,
    required this.correct,
  });
}

// Stable lesson ids: lesson_01 ... lesson_14
final Map<String, List<LessonQuizQuestion>> lessonQuizzes = {
  'lesson_01': const [
    LessonQuizQuestion(
      question: 'Which function prints text to the screen?',
      options: ['echo()', 'print()', 'log()', 'show()'],
      correct: 'print()',
    ),
    LessonQuizQuestion(
      question: 'What does a line starting with # do?',
      options: ['Runs faster', 'Adds two numbers', 'Is ignored by Python', 'Declares a variable'],
      correct: 'Is ignored by Python',
    ),
    LessonQuizQuestion(
      question: 'Python executes code in what order?',
      options: ['Random', 'Bottom to top', 'Top to bottom', 'Alphabetical'],
      correct: 'Top to bottom',
    ),
  ],
  'lesson_02': const [
    LessonQuizQuestion(
      question: 'What operator assigns a value to a variable?',
      options: ['==', '=', '+=', ':='],
      correct: '=',
    ),
    LessonQuizQuestion(
      question: 'Valid variable name?',
      options: ['my score', '2score', 'my_score', 'my-score'],
      correct: 'my_score',
    ),
    LessonQuizQuestion(
      question: 'After running: score = 5; score = 8; what prints?',
      options: ['5', '13', '8', 'Error'],
      correct: '8',
    ),
  ],
  'lesson_03': const [
    LessonQuizQuestion(
      question: 'Which is a boolean literal?',
      options: ['true', 'False', '"True"', '1'],
      correct: 'False',
    ),
    LessonQuizQuestion(
      question: 'What is the type of 3.14?',
      options: ['int', 'float', 'str', 'bool'],
      correct: 'float',
    ),
    LessonQuizQuestion(
      question: 'type("hi") returns what class name?',
      options: ['int', 'str', 'bool', 'list'],
      correct: 'str',
    ),
  ],
  'lesson_04': const [
    LessonQuizQuestion(
      question: 'What does 10 % 3 evaluate to?',
      options: ['0', '1', '3', '10'],
      correct: '1',
    ),
    LessonQuizQuestion(
      question: 'Which operator is exponentiation?',
      options: ['^', '**', '^^', 'exp'],
      correct: '**',
    ),
    LessonQuizQuestion(
      question: 'price=2, qty=4; total = price * qty; total is?',
      options: ['2', '4', '6', '8'],
      correct: '8',
    ),
  ],
  'lesson_05': const [
    LessonQuizQuestion(
      question: 'What type does input() return?',
      options: ['int', 'float', 'str', 'bool'],
      correct: 'str',
    ),
    LessonQuizQuestion(
      question: 'How do you turn "42" into a number?',
      options: ['float("42")', 'int("42")', 'num("42")', 'cast("42")'],
      correct: 'int("42")',
    ),
    LessonQuizQuestion(
      question: 'What happens if you add 1 to input("Age?") without casting?',
      options: ['Works fine', 'String concatenation', 'TypeError', 'Subtracts 1'],
      correct: 'TypeError',
    ),
  ],
  'lesson_06': const [
    LessonQuizQuestion(
      question: 'Best way to embed variables in strings?',
      options: ['"Hello" + name', 'f"Hello {name}"', 'concat("Hello", name)', 'format(name)'],
      correct: 'f"Hello {name}"',
    ),
    LessonQuizQuestion(
      question: 'What does " python ".strip() return?',
      options: ['" python "', '"python"', '" python"', '"python  "'],
      correct: '"python"',
    ),
    LessonQuizQuestion(
      question: 'len("abc") is?',
      options: ['2', '3', '4', '5'],
      correct: '3',
    ),
  ],
  'lesson_07': const [
    LessonQuizQuestion(
      question: 'Which operator checks equality?',
      options: ['=', '==', '!=', '==='],
      correct: '==',
    ),
    LessonQuizQuestion(
      question: 'Fill the blank: if temp > 30: ___("hot")',
      options: ['echo', 'printf', 'print', 'log'],
      correct: 'print',
    ),
    LessonQuizQuestion(
      question: 'elif means?',
      options: ['Else-if branch', 'End loop', 'Assign value', 'Compare types'],
      correct: 'Else-if branch',
    ),
  ],
  'lesson_08': const [
    LessonQuizQuestion(
      question: 'range(5) produces?',
      options: ['0..5 inclusive', '1..5', '0..4', '5..10'],
      correct: '0..4',
    ),
    LessonQuizQuestion(
      question: 'Which loop keeps running while a condition stays true?',
      options: ['for', 'while', 'loop', 'repeat'],
      correct: 'while',
    ),
    LessonQuizQuestion(
      question: 'for friend in friends: friend is?',
      options: ['Index', 'Tuple', 'Element value', 'Dictionary key'],
      correct: 'Element value',
    ),
  ],
  'lesson_09': const [
    LessonQuizQuestion(
      question: 'Lists are indexed starting at?',
      options: ['-1', '0', '1', 'any'],
      correct: '0',
    ),
    LessonQuizQuestion(
      question: 'Which adds an item to the end of a list?',
      options: ['push()', 'append()', 'add()', 'insert()'],
      correct: 'append()',
    ),
    LessonQuizQuestion(
      question: 'backpack[0] refers to?',
      options: ['First item', 'Second item', 'Last item', 'Length'],
      correct: 'First item',
    ),
  ],
  'lesson_10': const [
    LessonQuizQuestion(
      question: 'Dictionaries use what to access values?',
      options: ['Indexes', 'Keys', 'Offsets', 'Rows'],
      correct: 'Keys',
    ),
    LessonQuizQuestion(
      question: 'phonebook["Alice"] returns?',
      options: ['Key', 'Value', 'Index', 'Tuple'],
      correct: 'Value',
    ),
    LessonQuizQuestion(
      question: 'How to add a new key?',
      options: ['phonebook.add("Eve")', 'phonebook("Eve") = ...', 'phonebook["Eve"] = "123"', 'phonebook.push("Eve")'],
      correct: 'phonebook["Eve"] = "123"',
    ),
  ],
  'lesson_11': const [
    LessonQuizQuestion(
      question: 'How to define a function named greet?',
      options: ['func greet():', 'def greet():', 'function greet():', 'greet() =>'],
      correct: 'def greet():',
    ),
    LessonQuizQuestion(
      question: 'A function returns a value using?',
      options: ['output', 'return', 'yield', 'give'],
      correct: 'return',
    ),
    LessonQuizQuestion(
      question: 'square(4) returns 16 when square is?',
      options: ['def square(): print(4)', 'def square(x): return x * x', 'def square(x,y): x+y', 'def square: x*x'],
      correct: 'def square(x): return x * x',
    ),
  ],
  'lesson_12': const [
    LessonQuizQuestion(
      question: 'What is __init__ used for?',
      options: ['Import modules', 'Object construction', 'Delete object', 'Loop control'],
      correct: 'Object construction',
    ),
    LessonQuizQuestion(
      question: 'self.name inside a class refers to?',
      options: ['Global variable', 'Class name', 'Instance attribute', 'Function'],
      correct: 'Instance attribute',
    ),
    LessonQuizQuestion(
      question: 'How to create a Dog named Rex?',
      options: ['Dog.create("Rex")', 'new Dog("Rex")', 'Dog("Rex")', 'Dog = Rex()'],
      correct: 'Dog("Rex")',
    ),
  ],
  'lesson_13': const [
    LessonQuizQuestion(
      question: 'Which imports the random module?',
      options: ['include random', 'import random', 'use random', 'require random'],
      correct: 'import random',
    ),
    LessonQuizQuestion(
      question: 'time.sleep(2) does what?',
      options: ['Prints time', 'Sleeps 2 ms', 'Pauses ~2 seconds', 'Stops program forever'],
      correct: 'Pauses ~2 seconds',
    ),
    LessonQuizQuestion(
      question: 'random.randint(1,6) returns?',
      options: ['Float 1-6', 'Int 1-6 inclusive', 'Int 0-5', 'Error'],
      correct: 'Int 1-6 inclusive',
    ),
  ],
  'lesson_14': const [
    LessonQuizQuestion(
      question: 'Regex is used for?',
      options: ['Math', 'File IO', 'Pattern matching in text', 'Graphics'],
      correct: 'Pattern matching in text',
    ),
    LessonQuizQuestion(
      question: '\\d in a regex means?',
      options: ['Digit', 'Letter', 'Space', 'Dot'],
      correct: 'Digit',
    ),
    LessonQuizQuestion(
      question: 'Which simple pattern matches email-like strings?',
      options: ['[a-z]+', '[\\w\\.-]+@[\\w\\.-]+', '\\d{3}-\\d{4}', '.*'],
      correct: '[\\w\\.-]+@[\\w\\.-]+',
    ),
  ],
};
