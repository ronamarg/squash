import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'lesson_detail_screen.dart';

class Lesson {
  final String title;
  final String summary;
  final String content;
  const Lesson({
    required this.title,
    required this.summary,
    required this.content,
  });
}

// I've organized the curriculum into a logical progression with mini-checks to prep for quizzes
final List<Lesson> allLessons = [
  // --- MODULE 1: ABSOLUTE BEGINNER ---

  const Lesson(
   title: '1. First Steps & Printing',
   summary: 'Hello world, order of execution, and comments.',
   content: r'''
Why it matters: Printing is the quickest way to see what your code is doing and to debug.

You will practice:
- Writing your first `print()` calls.
- Seeing that Python runs top-to-bottom.
- Using comments to explain or disable code.

Core ideas
1) Printing text
  print("Hello, World!")
  print("I am coding!")

2) Execution order (top to bottom)
  print("Line 1")
  print("Line 2")
  print("Line 3")

3) Comments are ignored by Python
  # This is a helpful note
  print("Visible")
  # print("Hidden")

Mini-check (write it):
- Print your name on one line, then your favorite food on the next line.
''',
  ),

  const Lesson(
   title: '2. Variables',
   summary: 'Store values with good names and change them.',
   content: r'''
Why it matters: Variables let you reuse data instead of retyping it.

You will practice:
- Creating variables with `=`.
- Updating values.
- Picking clear names.

Core ideas
1) Create a variable
  score = 10
  print(score)

2) Change it later
  score = 10
  score = 20
  print(score)  # 20

3) Naming rules
  my_name = "Alice"   # snake_case is standard
  my name = "Alice"   # ERROR (spaces not allowed)

Mini-check:
- Make `lives = 3`, subtract 1, print the result with `print(lives)`.
''',
  ),

  const Lesson(
   title: '3. Data Types',
   summary: 'Strings, numbers, booleans, and how to inspect them.',
   content: r'''
Why it matters: Operations depend on the data type (text vs number vs True/False).

You will practice:
- Declaring strings, ints, floats, and bools.
- Checking a value’s type with `type()`.

Core ideas
1) Strings (text)
  name = "Mario"
  job = 'Plumber'

2) Integers and floats
  lives = 3       # int
  speed = 4.5     # float

3) Booleans
  is_game_over = False
  has_key = True

4) Inspect a type
  print(type(speed))  # <class 'float'>

Mini-check:
- Create `temperature = 21.5` and `is_raining = False`, then print their types.
''',
  ),

  const Lesson(
   title: '4. Math & Operators',
   summary: 'Basic arithmetic, exponent, and modulo.',
   content: r'''
Why it matters: Games, finance, and data tasks all rely on math operations.

You will practice:
- +, -, *, /, **, and %.
- Using variables inside expressions.

Core ideas
1) Basic math
  print(2 + 2)
  print(10 - 3)
  print(5 * 5)
  print(10 / 2)   # 5.0 (float)

2) Power and remainder
  print(2 ** 3)   # 8
  print(10 % 3)   # 1 (remainder)

3) Math with variables
  price = 2
  qty = 5
  total = price * qty
  print(total)

Mini-check:
- Compute the area of a rectangle with width 4 and height 7, store in `area`, and print it.
''',
  ),

  const Lesson(
   title: '5. User Input',
   summary: 'Read user input and convert it to numbers safely.',
   content: r'''
Why it matters: Interactive programs need data from people.

You will practice:
- Using `input()`.
- Converting strings to integers with `int()`.

Core ideas
1) Read input as text
  name = input("Enter your name: ")
  print(f"Hi {name}!")

2) Input is always a string
  age_text = input("Enter age: ")
  # print(age_text + 1)  # TypeError

3) Cast to number
  age = int(age_text)
  print(age + 1)

Mini-check:
- Ask for a number, convert it to int, then print double its value.
''',
  ),

  // --- MODULE 2: WORKING WITH DATA ---

  const Lesson(
   title: '6. Strings & Formatting',
   summary: 'Build readable messages with f-strings and helpers.',
   content: r'''
Why it matters: Clean string handling makes output and logs understandable.

You will practice:
- f-strings for interpolation.
- Combining strings and cleaning whitespace.

Core ideas
1) f-strings
  player = "Luigi"
  score = 500
  print(f"Player: {player}, Score: {score}")

2) Concatenate
  full = "Super" + " " + "Mario"
  print(full)

3) Helpful string methods
  text = "  python  "
  print(text.upper())
  print(text.strip())
  print(len(text))

Mini-check:
- Make `city = "London"`, `temp = 18`, then print `London is 18C` using an f-string.
''',
  ),

  // --- MODULE 3: CONTROL FLOW ---

  const Lesson(
   title: '7. Conditionals (If/Else)',
   summary: 'Branch logic with comparisons and elif chains.',
   content: r'''
Why it matters: Programs react differently depending on conditions.

You will practice:
- Comparison operators.
- if/elif/else structure.

Core ideas
1) Comparisons
  ==, !=, >, <, >=, <=

2) Simple decision
  age = 18
  if age >= 18:
     print("You can vote")
  else:
     print("Too young")

3) Multiple branches
  score = 85
  if score >= 90:
     print("Grade A")
  elif score >= 80:
     print("Grade B")
  else:
     print("Grade C")

Mini-check:
- Write a check that prints "even" when `n % 2 == 0` else "odd".
''',
  ),

  const Lesson(
   title: '8. Loops (For & While)',
   summary: 'Repeat work over ranges and while conditions hold.',
   content: r'''
Why it matters: Loops prevent copy-paste code and handle collections.

You will practice:
- Counting with for.
- Iterating lists.
- Using while for open-ended loops.

Core ideas
1) Counting loop
  for i in range(5):
     print(i)

2) Loop over list values
  friends = ["Ross", "Joey", "Chandler"]
  for friend in friends:
     print(f"Hi {friend}")

3) While loop
  battery = 3
  while battery > 0:
     print("On")
     battery -= 1
  print("Off")

Mini-check:
- Print numbers 1 through 5 using a for loop, then do the same with a while loop.
''',
  ),

  // --- MODULE 4: DATA STRUCTURES ---

  const Lesson(
   title: '9. Lists',
   summary: 'Ordered collections you can grow and edit.',
   content: r'''
Why it matters: Lists hold sequences like todos, scores, or records.

You will practice:
- Creating, indexing, appending, and removing.

Core ideas
1) Make a list
  backpack = ["Sword", "Shield", "Potion"]

2) Indexing (starts at 0)
  print(backpack[0])
  print(backpack[1])

3) Modify
  backpack.append("Map")
  backpack[0] = "Axe"
  backpack.remove("Potion")
  print(backpack)

Mini-check:
- Start with `nums = [1, 2, 3]`, append 4, replace the first item with 10, then print the list.
''',
  ),

  const Lesson(
   title: '10. Dictionaries',
   summary: 'Key-value lookups for fast access.',
   content: r'''
Why it matters: Dictionaries model real data (contacts, settings, JSON).

You will practice:
- Creating dictionaries, reading values, adding/updating keys.

Core ideas
1) Create a dict
  phonebook = {
    "Alice": "555-1234",
    "Bob": "555-9876"
  }

2) Access
  print(phonebook["Alice"])

3) Add or update
  phonebook["Charlie"] = "555-5555"
  phonebook["Alice"] = "555-0000"

Mini-check:
- Build a dict with keys name, role, level. Print the role. Update level to 2.
''',
  ),

  // --- MODULE 5: INTERMEDIATE ---

  const Lesson(
   title: '11. Functions',
   summary: 'Bundle work into reusable blocks.',
   content: r'''
Why it matters: Functions reduce repetition and make tests easier.

You will practice:
- Defining functions with and without parameters.
- Returning values.

Core ideas
1) Define and call
  def greet_user():
     print("Welcome back!")

  greet_user()

2) Parameters
  def square(number):
     return number * number

  print(square(5))

3) Multiple parameters + return
  def add(a, b):
     return a + b

  total = add(10, 5)
  print(total)

Mini-check:
- Write `def triple(x):` that returns 3*x and print `triple(4)`.
''',
  ),

  const Lesson(
   title: '12. Classes & OOP',
   summary: 'Create blueprints (classes) to build objects.',
   content: r'''
Why it matters: Objects group data with behavior (methods) and scale larger apps.

You will practice:
- Defining a class with `__init__`.
- Creating instances and calling methods.

Core ideas
1) Define a class
  class Dog:
     def __init__(self, name):
        self.name = name

     def bark(self):
        print(f"{self.name} says Woof!")

2) Create objects
  my_dog = Dog("Buddy")
  neighbor_dog = Dog("Rex")

3) Call methods
  my_dog.bark()
  neighbor_dog.bark()

Mini-check:
- Add a method `rename(self, new_name)` that updates `self.name`, then call it.
''',
  ),

  const Lesson(
   title: '13. Modules & Libraries',
   summary: 'Import and reuse existing code.',
   content: r'''
Why it matters: You rarely start from scratch—modules save time.

You will practice:
- Importing standard library modules.
- Calling their functions.

Core ideas
1) Random
  import random
  roll = random.randint(1, 6)
  print(f"You rolled {roll}")

2) Time
  import time
  print("Sleeping...")
  time.sleep(2)
  print("Awake!")

Mini-check:
- Use `random.choice` on a list of three snacks and print the result.
''',
  ),

  const Lesson(
   title: '14. Regular Expressions (Regex)',
   summary: 'Search text with patterns.',
   content: r'''
Why it matters: Regex helps validate and extract structured text (emails, phones).

You will practice:
- Writing a simple pattern and matching it.

Core ideas
1) Basic match
  import re
  text = "My number is 123-456-7890"
  match = re.search(r"\d+-\d+-\d+", text)
  if match:
     print("Found:", match.group())

2) Character classes and quantifiers
  email = "dev@example.com"
  pattern = r"[\w\.-]+@[\w\.-]+"  # simple email-ish pattern
  print(re.match(pattern, email))

Mini-check:
- Write a regex that matches three letters followed by two digits (e.g., ABC12) and test it.
''',
  ),

  // --- MODULE 6: ADVANCED TOPICS ---

  const Lesson(
   title: '15. Error Handling',
   summary: 'Catch exceptions so your program does not crash.',
   content: r'''
Why it matters: Real programs face bad input, missing files, and network issues.

You will practice:
- try/except blocks.
- Catching specific exceptions.
- The finally clause.

Core ideas
1) Basic try/except
  try:
     num = int(input("Number: "))
     print(num * 2)
  except ValueError:
     print("That's not a valid number!")

2) Multiple exceptions
  try:
     result = 10 / int(input("Divide by: "))
  except ValueError:
     print("Not a number")
  except ZeroDivisionError:
     print("Can't divide by zero")

3) Finally (always runs)
  try:
     f = open("data.txt")
     data = f.read()
  except FileNotFoundError:
     print("File missing")
  finally:
     print("Cleanup done")

Mini-check:
- Write a try/except that asks for age, converts to int, and prints "Invalid" on error.
''',
  ),

  const Lesson(
   title: '16. File I/O',
   summary: 'Read from and write to files.',
   content: r'''
Why it matters: Persist data between program runs (logs, saves, configs).

You will practice:
- Opening files with `with`.
- Reading and writing text.

Core ideas
1) Write to a file
  with open("notes.txt", "w") as f:
     f.write("Hello from Python!\n")
     f.write("Line 2\n")

2) Read entire file
  with open("notes.txt", "r") as f:
     content = f.read()
     print(content)

3) Read line by line
  with open("notes.txt", "r") as f:
     for line in f:
        print(line.strip())

Mini-check:
- Write your name to a file, then read it back and print it.
''',
  ),

  const Lesson(
   title: '17. List Comprehensions',
   summary: 'Build lists in one elegant line.',
   content: r'''
Why it matters: Comprehensions are Pythonic—shorter and often faster.

You will practice:
- Basic comprehensions.
- Adding conditions.

Core ideas
1) Transform each item
  nums = [1, 2, 3, 4, 5]
  squares = [n * n for n in nums]
  print(squares)  # [1, 4, 9, 16, 25]

2) Filter with condition
  evens = [n for n in nums if n % 2 == 0]
  print(evens)  # [2, 4]

3) Transform + filter
  big_squares = [n * n for n in nums if n > 2]
  print(big_squares)  # [9, 16, 25]

Mini-check:
- From `words = ["hi", "hello", "hey", "world"]`, create a list of words longer than 2 chars, uppercased.
''',
  ),

  const Lesson(
   title: '18. Lambda Functions',
   summary: 'Small anonymous functions for quick tasks.',
   content: r'''
Why it matters: Lambdas are handy for sorting, filtering, and callbacks.

You will practice:
- Writing lambda expressions.
- Using them with `sorted()` and `map()`.

Core ideas
1) Basic lambda
  double = lambda x: x * 2
  print(double(5))  # 10

2) Sorting with key
  players = [("Mario", 100), ("Luigi", 80), ("Peach", 120)]
  by_score = sorted(players, key=lambda p: p[1])
  print(by_score)

3) Map with lambda
  nums = [1, 2, 3]
  tripled = list(map(lambda n: n * 3, nums))
  print(tripled)  # [3, 6, 9]

Mini-check:
- Sort a list of names by their length using a lambda.
''',
  ),

  const Lesson(
   title: '19. Working with APIs',
   summary: 'Fetch data from the web using requests.',
   content: r'''
Why it matters: APIs let your app talk to servers (weather, news, games).

You will practice:
- Making GET requests.
- Parsing JSON responses.

Core ideas
1) Install requests (if needed)
  # pip install requests

2) Simple GET request
  import requests
  response = requests.get("https://api.github.com")
  print(response.status_code)  # 200 = success

3) Parse JSON
  data = response.json()
  print(data["current_user_url"])

4) API with parameters
  url = "https://api.example.com/search"
  params = {"q": "python", "limit": 5}
  r = requests.get(url, params=params)
  results = r.json()

Mini-check:
- Fetch a public API and print one field from the JSON response.
''',
  ),

  const Lesson(
   title: '20. Debugging Techniques',
   summary: 'Find and fix bugs like a pro.',
   content: r'''
Why it matters: Every programmer spends time debugging—do it efficiently.

You will practice:
- Using print debugging.
- Reading error messages.
- Common bug patterns.

Core ideas
1) Strategic print statements
  def calculate(x, y):
     print(f"DEBUG: x={x}, y={y}")  # <-- add this
     result = x / y
     print(f"DEBUG: result={result}")
     return result

2) Read the traceback (bottom up)
  Traceback (most recent call last):
    File "app.py", line 10, in <module>
      calculate(5, 0)
    File "app.py", line 4, in calculate
      result = x / y
  ZeroDivisionError: division by zero
  # Line 4 is the problem!

3) Common bugs to watch for
  - Off-by-one errors (range(5) is 0-4, not 1-5)
  - Forgetting to return a value
  - Modifying a list while iterating
  - Using = instead of ==

Mini-check:
- Given buggy code, add print statements to find where it fails.
''',
  ),
];
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  String _lessonId(int index) => 'lesson_${(index + 1).toString().padLeft(2, '0')}';

  bool _isUnlocked({
    required String lessonId,
    required String currentLessonId,
    required Map<String, dynamic> progress,
  }) {
    if (lessonId == 'lesson_01') return true;
    // Unlocked if currentLessonId is this or beyond, or if previous is completed
    if (lessonId.compareTo(currentLessonId) <= 0) return true;
    final numPart = int.tryParse(lessonId.split('_').last) ?? 1;
    final prevId = 'lesson_${(numPart - 1).toString().padLeft(2, '0')}';
    final prevDone = (progress[prevId]?['completed'] ?? false) == true;
    return prevDone;
  }

  @override
  Widget build(BuildContext context) {
    final firebase = FirebaseService();
    final user = firebase.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Lessons'),
        backgroundColor: AppColors.background,
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: user == null
              ? _buildList(context, const {}, 'lesson_01')
              : FutureBuilder<UserModel?>(
                  future: FirebaseService().getUserData(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    }
                    final data = snapshot.data;
                    final progress = data?.lessonProgress ?? const {};
                    final current = data?.currentLessonId ?? 'lesson_01';
                    return _buildList(context, progress, current);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, Map<String, dynamic> progress, String currentLessonId) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: allLessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final lesson = allLessons[i];
        final lessonId = _lessonId(i);
        final unlocked = _isUnlocked(lessonId: lessonId, currentLessonId: currentLessonId, progress: progress);
        final completed = (progress[lessonId]?['completed'] ?? false) == true;
        final gradient = unlocked
          ? [AppColors.accent.withValues(alpha: 0.9), AppColors.accentSecondary.withValues(alpha: 0.9)]
          : [AppColors.surface, AppColors.surface];
        final textColor = unlocked ? AppColors.textPrimary : AppColors.textMuted;
        return InkWell(
          onTap: unlocked
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LessonDetailScreen(lesson: lesson, lessonId: lessonId),
                    ),
                  )
              : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Locked. Pass the previous quiz to unlock.')),
                  ),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: unlocked ? AppColors.accent.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: unlocked ? AppColors.accent : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.summary,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (completed)
                  const Icon(Icons.check_circle, color: Colors.white, size: 22)
                else if (!unlocked)
                  Icon(Icons.lock, color: textColor, size: 20)
                else
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}