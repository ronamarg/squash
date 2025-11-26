import 'package:flutter/material.dart';
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

// I've organized the curriculum into a logical progression
final List<Lesson> allLessons = [
  // --- MODULE 1: ABSOLUTE BEGINNER ---
  
  const Lesson(
    title: '1. First Steps & Printing',
    summary: 'Your very first Python code.',
    content: r'''
Welcome to programming! Python is a language that allows you to give instructions to a computer.

1. The Print Command
The most basic instruction is `print()`. It displays text on the screen.
   print("Hello, World!")
   print("I am coding!")

2. Order Matters
Python runs your code from top to bottom, line by line.
   print("Line 1")
   print("Line 2")
   print("Line 3")

3. Comments
Any line starting with `#` is ignored by the computer. These are notes for humans.
   # This is a comment to explain the code
   print("This will print") 
   # print("This will NOT print")
''',
  ),

  const Lesson(
    title: '2. Variables',
    summary: 'How to store data for later use.',
    content: r'''
1. What is a Variable?
Imagine a box with a label on it. You can put data inside the box to use later.
   
   # Create a variable named 'score' and put 10 inside
   score = 10
   print(score)

2. Changing Values
You can change what is inside the box at any time.
   score = 10
   print(score)  # Prints 10
   
   score = 20
   print(score)  # Now prints 20

3. Naming Rules
Variable names cannot have spaces! Use underscores instead.
   my_name = "Alice"  # Good (snake_case)
   my name = "Alice"  # ERROR!
   MyName = "Alice"   # Allowed, but not typical in Python
''',
  ),

  const Lesson(
    title: '3. Data Types',
    summary: 'Text, Numbers, and True/False.',
    content: r'''
In Python, every piece of data has a "Type". Python needs to know if something is a number or text to know what to do with it.

1. Strings (str)
Text is called a "String". It MUST be inside quotes.
   name = "Mario"
   job = 'Plumber'

2. Integers (int)
Whole numbers without decimals.
   lives = 3
   level = 1

3. Floats (float)
Numbers with decimals.
   speed = 4.5
   pi = 3.14

4. Booleans (bool)
Logic values. Only `True` or `False` (Capitalized!).
   is_game_over = False
   has_key = True

5. Checking Types
You can ask Python what type something is:
   print(type(lives)) # <class 'int'>
''',
  ),

  const Lesson(
    title: '4. Math & Operators',
    summary: 'Using Python as a calculator.',
    content: r'''
Computers are great at math. You can perform calculations directly on numbers or variables.

1. Basic Math
   print(2 + 2)    # Addition (4)
   print(10 - 3)   # Subtraction (7)
   print(5 * 5)    # Multiplication (25)
   print(10 / 2)   # Division (5.0)

2. Advanced Math
   # Power (Exponents)
   print(2 ** 3)   # 2 * 2 * 2 = 8
   
   # Modulo (Remainder)
   # Useful for checking if numbers are even/odd
   print(10 % 3)   # 10 divided by 3 is 3 remainder 1. Output: 1

3. Math with Variables
   apple_price = 2
   quantity = 5
   total = apple_price * quantity
   print(total)    # 10
''',
  ),

  const Lesson(
    title: '5. User Input',
    summary: 'Getting data from the user.',
    content: r'''
So far, we have only set values in the code. Let's ask the user to type something!

1. The input() Function
This pauses the program and waits for the user.
   name = input("Enter your name: ")
   print(f"Nice to meet you, {name}!")

2. The "String" Problem
`input()` ALWAYS returns text (String), even if the user types a number!
   age = input("Enter age: ")
   # print(age + 1)  <-- ERROR! You cannot add a number to text.

3. Casting (Fixing the Problem)
You must convert the input to a number using `int()`.
   age_text = input("Enter age: ")
   age_number = int(age_text)
   
   print(f"Next year you will be {age_number + 1}")
''',
  ),

  // --- MODULE 2: WORKING WITH DATA ---

  const Lesson(
    title: '6. Strings & Formatting',
    summary: 'Combining variables with text.',
    content: r'''
1. F-Strings (The Best Way)
Put an `f` before the quotes to put variables directly inside text using `{}`.
   
   score = 500
   player = "Luigi"
   
   print(f"Player: {player}, Score: {score}")

2. Combining Strings
You can add strings together using `+`.
   first = "Super"
   last = "Mario"
   full = first + " " + last 
   print(full) # Super Mario

3. Useful Tools
   text = "  python  "
   print(text.upper())   # "  PYTHON  "
   print(text.strip())   # "python" (removes spaces)
   print(len(text))      # 10 (counts characters)
''',
  ),

  // --- MODULE 3: CONTROL FLOW ---

  const Lesson(
    title: '7. Conditionals (If/Else)',
    summary: 'Making decisions.',
    content: r'''
Code usually runs in a straight line. "If" statements let the code branch.

1. Comparison Operators
   ==  (Equal to)
   !=  (Not equal to)
   >   (Greater than)
   <   (Less than)

2. Simple Decision
   age = 18

   if age >= 18:
       print("You can vote!")
   else:
       print("Too young.")

3. Multiple Choices (elif)
"elif" stands for "else if".
   
   score = 85

   if score >= 90:
       print("Grade: A")
   elif score >= 80:
       print("Grade: B")
   else:
       print("Grade: C")
''',
  ),

  const Lesson(
    title: '8. Loops (For & While)',
    summary: 'Doing things over and over.',
    content: r'''
1. For Loops (Counting)
   # Count from 0 to 4
   for i in range(5):
       print(i)

2. Loop over a List
   friends = ["Ross", "Joey", "Chandler"]
   for friend in friends:
       print(f"Hi {friend}")

3. While Loops
Keep running AS LONG AS a condition is true.
   
   battery = 5
   while battery > 0:
       print("Phone is on...")
       battery = battery - 1
   print("Battery died.")
''',
  ),

  // --- MODULE 4: DATA STRUCTURES ---

  const Lesson(
    title: '9. Lists',
    summary: 'Storing multiple items in one variable.',
    content: r'''
A list is a collection of items in a specific order.

1. Creating a List
   backpack = ["Sword", "Shield", "Potion"]

2. Accessing Items (Index)
Computers start counting at 0!
   print(backpack[0])  # Sword
   print(backpack[1])  # Shield

3. Modifying Lists
   backpack.append("Map")  # Add to end
   backpack[0] = "Axe"     # Change first item
   backpack.remove("Potion") # Remove item
   
   print(backpack) 
   # ['Axe', 'Shield', 'Map']
''',
  ),

  const Lesson(
    title: '10. Dictionaries',
    summary: 'Key-Value pairs (like a real dictionary).',
    content: r'''
Lists use numbers (0, 1, 2) to find things. Dictionaries use "Keys".

1. Creating a Dictionary
   phonebook = {
     "Alice": "555-1234",
     "Bob": "555-9876"
   }

2. Accessing Data
   print(phonebook["Alice"]) # Output: 555-1234

3. Adding/Updating
   phonebook["Charlie"] = "555-5555" # Add new
   phonebook["Alice"] = "555-0000"   # Update existing
''',
  ),

  // --- MODULE 5: INTERMEDIATE ---

  const Lesson(
    title: '11. Functions',
    summary: 'Reusable blocks of code.',
    content: r'''
1. Defining a Function
   def greet_user():
       print("Welcome back!")

   # It won't run until you call it:
   greet_user()

2. Parameters (Passing Data)
   def square(number):
       print(number * number)

   square(5)  # 25
   square(10) # 100

3. Return Values
Sometimes you want the function to give you an answer back.
   def add(a, b):
       return a + b
   
   result = add(10, 5)
   print(result) # 15
''',
  ),

  const Lesson(
    title: '12. Classes & OOP',
    summary: 'Creating your own custom objects.',
    content: r'''
1. The Class (The Blueprint)
   class Dog:
       def __init__(self, name):
           self.name = name
       
       def bark(self):
           print(f"{self.name} says Woof!")

2. The Object (The House built from blueprint)
   my_dog = Dog("Buddy")
   neighbor_dog = Dog("Rex")

   my_dog.bark()      # Buddy says Woof!
   neighbor_dog.bark() # Rex says Woof!
''',
  ),

  const Lesson(
    title: '13. Modules & Libraries',
    summary: 'Using code others have written.',
    content: r'''
Python has "batteries included". You can import powerful tools.

1. Random Module
   import random
   
   roll = random.randint(1, 6)
   print(f"You rolled a {roll}")

2. Time Module
   import time
   
   print("Sleeping...")
   time.sleep(2) # Pause for 2 seconds
   print("Awake!")
''',
  ),

  const Lesson(
    title: '14. Regular Expressions (Regex)',
    summary: 'Finding patterns in text.',
    content: r'''
Regex is a tool for advanced search (like finding emails or phone numbers).

1. Basic Match
   import re
   
   text = "My number is 123-456-7890"
   
   # \d means "Any Digit"
   # + means "One or more"
   match = re.search(r"\d+-\d+-\d+", text)
   
   if match:
       print("Found phone number:", match.group())
''',
  ),
];
class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Python Lessons'),
        backgroundColor: const Color(0xFFFF8A3D),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFFFFBF5),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: allLessons.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final lesson = allLessons[i];
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
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8A3D),
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lesson.summary,
                          style: const TextStyle(
                            fontSize: 13,
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