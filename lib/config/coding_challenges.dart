/// Coding Challenges for Onboarding Assessment
/// 
/// These are short coding tasks presented after the MCQ assessment.
/// Users write/fix code, which is then analyzed by the RF model
/// to determine their actual coding proficiency.
/// 
/// Challenge Design:
/// - 2 challenges per user (based on preliminary MCQ level)
/// - Each has a prompt, starter code, and canonical solution
/// - Features extracted: length, tokens, density, verbosity, etc.

/// Challenge difficulty tiers matching skill levels
enum ChallengeTier { beginner, novice, intermediate, advanced, expert }

class CodingChallenge {
  final String id;
  final ChallengeTier tier;
  final String concept;
  final String title;
  final String prompt;
  final String starterCode;
  final String canonicalSolution;
  final String testCase; // Simple test to verify correctness
  final List<String> hints;

  const CodingChallenge({
    required this.id,
    required this.tier,
    required this.concept,
    required this.title,
    required this.prompt,
    required this.starterCode,
    required this.canonicalSolution,
    required this.testCase,
    this.hints = const [],
  });
}

/// Coding challenges organized by tier
/// User gets 2 challenges based on their preliminary MCQ level
const Map<ChallengeTier, List<CodingChallenge>> codingChallenges = {
  
  // ============================================
  // BEGINNER: Very basic syntax
  // ============================================
  ChallengeTier.beginner: [
    CodingChallenge(
      id: 'beg_01',
      tier: ChallengeTier.beginner,
      concept: 'print',
      title: 'Hello World',
      prompt: 'Write code that prints "Hello, World!" to the screen.',
      starterCode: '# Write your code below\n',
      canonicalSolution: 'print("Hello, World!")',
      testCase: 'Hello, World!',
      hints: ['Use the print() function', 'Put text in quotes'],
    ),
    CodingChallenge(
      id: 'beg_02',
      tier: ChallengeTier.beginner,
      concept: 'variables',
      title: 'Store a Number',
      prompt: 'Create a variable called "age" and set it to 25, then print it.',
      starterCode: '# Create the variable and print it\n',
      canonicalSolution: 'age = 25\nprint(age)',
      testCase: '25',
      hints: ['Variables don\'t need type declarations', 'Use = to assign'],
    ),
    CodingChallenge(
      id: 'beg_03',
      tier: ChallengeTier.beginner,
      concept: 'arithmetic',
      title: 'Simple Math',
      prompt: 'Calculate 10 + 5 * 2 and print the result.',
      starterCode: '# Calculate and print\n',
      canonicalSolution: 'result = 10 + 5 * 2\nprint(result)',
      testCase: '20',
      hints: ['Remember order of operations', 'Multiplication before addition'],
    ),
  ],

  // ============================================
  // NOVICE: Basic control flow
  // ============================================
  ChallengeTier.novice: [
    CodingChallenge(
      id: 'nov_01',
      tier: ChallengeTier.novice,
      concept: 'conditionals',
      title: 'Check Positive',
      prompt: 'Write code that prints "Positive" if x is greater than 0, otherwise prints "Not positive". Assume x = 5.',
      starterCode: 'x = 5\n# Add your if/else below\n',
      canonicalSolution: 'x = 5\nif x > 0:\n    print("Positive")\nelse:\n    print("Not positive")',
      testCase: 'Positive',
      hints: ['Use if/else', 'Don\'t forget the colons'],
    ),
    CodingChallenge(
      id: 'nov_02',
      tier: ChallengeTier.novice,
      concept: 'loops',
      title: 'Count to Five',
      prompt: 'Use a for loop to print numbers 1 through 5, each on a new line.',
      starterCode: '# Use a for loop\n',
      canonicalSolution: 'for i in range(1, 6):\n    print(i)',
      testCase: '1\n2\n3\n4\n5',
      hints: ['range(1, 6) gives 1,2,3,4,5', 'range excludes the end value'],
    ),
    CodingChallenge(
      id: 'nov_03',
      tier: ChallengeTier.novice,
      concept: 'strings',
      title: 'Greeting',
      prompt: 'Create a variable name = "Alice" and print "Hello, Alice!" using string concatenation or f-strings.',
      starterCode: 'name = "Alice"\n# Print the greeting\n',
      canonicalSolution: 'name = "Alice"\nprint(f"Hello, {name}!")',
      testCase: 'Hello, Alice!',
      hints: ['Try f"Hello, {name}!"', 'Or use + to concatenate'],
    ),
  ],

  // ============================================
  // INTERMEDIATE: Functions and data structures
  // ============================================
  ChallengeTier.intermediate: [
    CodingChallenge(
      id: 'int_01',
      tier: ChallengeTier.intermediate,
      concept: 'functions',
      title: 'Add Function',
      prompt: 'Write a function called "add" that takes two numbers and returns their sum. Then call it with 3 and 4, and print the result.',
      starterCode: '# Define the add function\n\n# Call it and print\n',
      canonicalSolution: 'def add(a, b):\n    return a + b\n\nresult = add(3, 4)\nprint(result)',
      testCase: '7',
      hints: ['Use def to define functions', 'Don\'t forget return'],
    ),
    CodingChallenge(
      id: 'int_02',
      tier: ChallengeTier.intermediate,
      concept: 'lists',
      title: 'Sum a List',
      prompt: 'Given numbers = [1, 2, 3, 4, 5], calculate and print the sum of all elements.',
      starterCode: 'numbers = [1, 2, 3, 4, 5]\n# Calculate sum and print\n',
      canonicalSolution: 'numbers = [1, 2, 3, 4, 5]\ntotal = sum(numbers)\nprint(total)',
      testCase: '15',
      hints: ['Python has a built-in sum() function', 'Or use a loop'],
    ),
    CodingChallenge(
      id: 'int_03',
      tier: ChallengeTier.intermediate,
      concept: 'dictionaries',
      title: 'Access Dictionary',
      prompt: 'Given person = {"name": "Bob", "age": 30}, print the person\'s name.',
      starterCode: 'person = {"name": "Bob", "age": 30}\n# Print the name\n',
      canonicalSolution: 'person = {"name": "Bob", "age": 30}\nprint(person["name"])',
      testCase: 'Bob',
      hints: ['Use square brackets with the key', 'Keys are strings'],
    ),
  ],

  // ============================================
  // ADVANCED: Pythonic patterns
  // ============================================
  ChallengeTier.advanced: [
    CodingChallenge(
      id: 'adv_01',
      tier: ChallengeTier.advanced,
      concept: 'comprehensions',
      title: 'Square Numbers',
      prompt: 'Use a list comprehension to create a list of squares from 1 to 5 ([1, 4, 9, 16, 25]) and print it.',
      starterCode: '# Use list comprehension\n',
      canonicalSolution: 'squares = [x**2 for x in range(1, 6)]\nprint(squares)',
      testCase: '[1, 4, 9, 16, 25]',
      hints: ['[expression for item in iterable]', 'Use ** for power'],
    ),
    CodingChallenge(
      id: 'adv_02',
      tier: ChallengeTier.advanced,
      concept: 'exceptions',
      title: 'Safe Division',
      prompt: 'Write a function safe_divide(a, b) that returns a/b, but returns 0 if b is zero (handle the ZeroDivisionError).',
      starterCode: '# Define safe_divide with try/except\n',
      canonicalSolution: 'def safe_divide(a, b):\n    try:\n        return a / b\n    except ZeroDivisionError:\n        return 0',
      testCase: 'function_defined',
      hints: ['Use try/except', 'Catch ZeroDivisionError specifically'],
    ),
    CodingChallenge(
      id: 'adv_03',
      tier: ChallengeTier.advanced,
      concept: 'lambda',
      title: 'Sort by Length',
      prompt: 'Given words = ["python", "is", "awesome"], sort them by length (shortest first) and print the result.',
      starterCode: 'words = ["python", "is", "awesome"]\n# Sort by length\n',
      canonicalSolution: 'words = ["python", "is", "awesome"]\nsorted_words = sorted(words, key=len)\nprint(sorted_words)',
      testCase: "['is', 'python', 'awesome']",
      hints: ['Use sorted() with key parameter', 'len gives the length'],
    ),
  ],

  // ============================================
  // EXPERT: Advanced patterns
  // ============================================
  ChallengeTier.expert: [
    CodingChallenge(
      id: 'exp_01',
      tier: ChallengeTier.expert,
      concept: 'generators',
      title: 'Fibonacci Generator',
      prompt: 'Write a generator function fib(n) that yields the first n Fibonacci numbers. Print list(fib(7)).',
      starterCode: '# Define fib generator\n\n# Print first 7\n',
      canonicalSolution: 'def fib(n):\n    a, b = 0, 1\n    for _ in range(n):\n        yield a\n        a, b = b, a + b\n\nprint(list(fib(7)))',
      testCase: '[0, 1, 1, 2, 3, 5, 8]',
      hints: ['Use yield instead of return', 'Fibonacci: each number is sum of previous two'],
    ),
    CodingChallenge(
      id: 'exp_02',
      tier: ChallengeTier.expert,
      concept: 'decorators',
      title: 'Timer Decorator',
      prompt: 'Write a decorator called "timer" that prints "Starting..." before a function runs and "Done!" after. Apply it to a function that prints "Hello".',
      starterCode: '# Define timer decorator\n\n# Apply to a function\n',
      canonicalSolution: 'def timer(func):\n    def wrapper(*args, **kwargs):\n        print("Starting...")\n        result = func(*args, **kwargs)\n        print("Done!")\n        return result\n    return wrapper\n\n@timer\ndef say_hello():\n    print("Hello")\n\nsay_hello()',
      testCase: 'Starting...\nHello\nDone!',
      hints: ['Decorator takes a function, returns a wrapper', 'Use @decorator syntax'],
    ),
    CodingChallenge(
      id: 'exp_03',
      tier: ChallengeTier.expert,
      concept: 'classes',
      title: 'Counter Class',
      prompt: 'Create a Counter class with methods increment(), decrement(), and get_value(). Start at 0. Create instance, increment twice, print value.',
      starterCode: '# Define Counter class\n\n# Create and use\n',
      canonicalSolution: 'class Counter:\n    def __init__(self):\n        self.value = 0\n    \n    def increment(self):\n        self.value += 1\n    \n    def decrement(self):\n        self.value -= 1\n    \n    def get_value(self):\n        return self.value\n\nc = Counter()\nc.increment()\nc.increment()\nprint(c.get_value())',
      testCase: '2',
      hints: ['Use __init__ for constructor', 'self.value for instance variable'],
    ),
  ],
};

/// Get 2 challenges appropriate for the given preliminary level
List<CodingChallenge> getChallengesForLevel(String level) {
  ChallengeTier tier;
  
  switch (level.toLowerCase()) {
    case 'beginner':
      tier = ChallengeTier.beginner;
      break;
    case 'novice':
      tier = ChallengeTier.novice;
      break;
    case 'intermediate':
      tier = ChallengeTier.intermediate;
      break;
    case 'advanced':
      tier = ChallengeTier.advanced;
      break;
    case 'expert':
      tier = ChallengeTier.expert;
      break;
    default:
      tier = ChallengeTier.novice;
  }
  
  final challenges = codingChallenges[tier] ?? codingChallenges[ChallengeTier.novice]!;
  
  // Return first 2 challenges (or all if less than 2)
  return challenges.take(2).toList();
}

/// Get a single challenge by ID
CodingChallenge? getChallengeById(String id) {
  for (final tierChallenges in codingChallenges.values) {
    for (final challenge in tierChallenges) {
      if (challenge.id == id) {
        return challenge;
      }
    }
  }
  return null;
}
