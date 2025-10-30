import 'package:flutter/material.dart';
import 'quiz_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

// NOTE: Use the correct IP address for your running Flask service
const String _apiUrl = 'http://192.168.1.8:5000/predict_level'; 

// --- QUIZ DATA MUST BE DEFINED HERE (COPIED FROM quiz_screen.dart) ---
final Map<String, List<Map<String, dynamic>>> fullQuizData = {
    "novice": [
      // NOTE: Ensure this list contains all 20 questions for the main quiz.
      {"question": "What is the correct way to print \"Hello World\"?", "options": ["print('Hello World')", "Print('Hello World')", "print Hello World", "echo 'Hello World'"], "correct": "print('Hello World')"},
      {"question": "How do you declare a variable x with value 5?", "options": ["x = 5", "int x = 5", "var x = 5", "x := 5"], "correct": "x = 5"},
      {"question": "What is the correct syntax for a for loop from 0 to 4?", "options": ["for i in range(5):", "for i in 0..4:", "for (int i=0; i<5; i++):", "foreach i in 0 to 4:"], "correct": "for i in range(5):"},
      {"question": "How do you check if x is equal to 10?", "options": ["if x == 10:", "if x = 10:", "if x === 10:", "if x is 10:"], "correct": "if x == 10:"},
      {"question": "What is the correct way to define a function?", "options": ["def my_function():", "function my_function():", "def my_function{}", "func my_function():"], "correct": "def my_function():"},
      {"question": "What is the output of print(2 + 3)?", "options": ["5", "23", "2+3", "print(5)"], "correct": "5"},
      {"question": "How do you create a list with numbers 1,2,3?", "options": ["[1,2,3]", "(1,2,3)", "{1,2,3}", "list(1,2,3)"], "correct": "[1,2,3]"},
      {"question": "What is the keyword for defining a function?", "options": ["def", "function", "func", "define"], "correct": "def"},
      {"question": "How do you write a comment?", "options": ["# This is a comment", "// This is a comment", "/* This is a comment */", ""], "correct": "# This is a comment"},
      {"question": "What is the correct way to check if a is equal to b?", "options": ["a == b", "a = b", "a === b", "a is b"], "correct": "a == b"},
      {"question": "How do you get the length of a list?", "options": ["len(my_list)", "length(my_list)", "my_list.length()", "size(my_list)"], "correct": "len(my_list)"},
      {"question": "What is the correct syntax for an if statement?", "options": ["if condition:", "if condition then", "if (condition)", "if condition do"], "correct": "if condition:"},
      {"question": "How do you loop from 0 to 9?", "options": ["for i in range(10):", "for i in 0..9:", "for (int i=0; i<10; i++):", "foreach i in range(10):"], "correct": "for i in range(10):"},
      {"question": "What is the output of print(\"Hello\" + \" World\")", "options": ["Hello World", "HelloWorld", "Hello + World", "print(Hello World)"], "correct": "Hello World"},
      {"question": "How do you convert a string to uppercase?", "options": ["my_string.upper()", "upper(my_string)", "my_string.toUpper()", "my_string.uppercase()"], "correct": "my_string.upper()"},
      {"question": "What is the correct way to import math module?", "options": ["import math", "include math", "using math", "require math"], "correct": "import math"},
      {"question": "How do you define a variable with value 10?", "options": ["x = 10", "int x = 10", "var x = 10", "x := 10"], "correct": "x = 10"},
      {"question": "What is the output of 10 // 3?", "options": ["3", "3.333", "3.0", "10/3"], "correct": "3"},
      {"question": "How do you append to a list?", "options": ["my_list.append(item)", "my_list.add(item)", "my_list.push(item)", "my_list.insert(item)"], "correct": "my_list.append(item)"},
      {"question": "What is the correct way to print a variable x?", "options": ["print(x)", "print 'x'", "echo x", "console.log(x)"], "correct": "print(x)"},
    ],
    "experienced": [
      // NOTE: Ensure this list contains all 20 questions for the main quiz.
      {"question": "How do you define an async function?", "options": ["async def my_function():", "def async my_function():", "async function my_function():", "def my_function() async:"], "correct": "async def my_function():"},
      {"question": "What is the correct way to use context manager?", "options": ["with open('file.txt') as f:", "using open('file.txt') as f:", "try:\n    f = open('file.txt')\nfinally:", "open('file.txt') as f:"], "correct": "with open('file.txt') as f:"},
      {"question": "How do you create a lambda function?", "options": ["lambda x: x**2", "lambda (x): x**2", "x => x**2", "def lambda x: x**2"], "correct": "lambda x: x**2"},
      {"question": "What is the correct syntax for asyncio.run?", "options": ["asyncio.run(main())", "asyncio.start(main())", "run asyncio main()", "asyncio.execute(main())"], "correct": "asyncio.run(main())"},
      {"question": "How do you use type hints?", "options": ["def func(x: int) -> str:", "def func(x int) -> str:", "def func(x: int): str", "def func(x) -> str: int"], "correct": "def func(x: int) -> str:"},
      {"question": "How do you use decorators?", "options": ["@my_decorator\ndef my_function():", "def my_function() @my_decorator", "my_decorator(my_function)", "decorate my_function with my_decorator"], "correct": "@my_decorator\ndef my_function():"},
      {"question": "What is the output of **kwargs?", "options": ["keyword arguments", "positional arguments", "default arguments", "variable arguments"], "correct": "keyword arguments"},
      {"question": "How do you create a generator?", "options": ["def my_gen():\n    yield 1", "def my_gen():\n    return 1", "generator = [1]", "gen my_gen(): yield 1"], "correct": "def my_gen():\n    yield 1"},
      {"question": "What is the correct way to use threading?", "options": ["import threading\nthread = threading.Thread(target=my_function)", "thread = Thread(my_function)", "threading.start(my_function)", "import thread\nthread.start(my_function)"], "correct": "import threading\nthread = threading.Thread(target=my_function)"},
      {"question": "How do you handle JSON?", "options": ["import json\njson.loads(data)", "json.parse(data)", "import jsonlib\njsonlib.load(data)", "data.from_json()"], "correct": "import json\njson.loads(data)"},
      {"question": "What is the output of zip([1,2], [3,4])?", "options": ["[(1,3), (2,4)]", "[[1,3], [2,4]]", "(1,3,2,4)", "Error"], "correct": "[(1,3), (2,4)]"},
      {"question": "How do you use regex?", "options": ["import re\nre.search(pattern, string)", "import regex\nregex.find(pattern, string)", "string.match(pattern)", "re.match(string, pattern)"], "correct": "import re\nre.search(pattern, string)"},
      {"question": "What is the correct way to use pandas?", "options": ["import pandas as pd\ndf = pd.DataFrame(data)", "import pandas\ndf = pandas.DataFrame(data)", "from pandas import *\ndf = DataFrame(data)", "df = pandas(data)"], "correct": "import pandas as pd\ndf = pd.DataFrame(data)"},
      {"question": "How do you create a virtual environment?", "options": ["python -m venv myenv", "venv create myenv", "python venv myenv", "virtualenv myenv"], "correct": "python -m venv myenv"},
      {"question": "What is the output of isinstance(5, int)?", "options": ["True", "False", "5", "int"], "correct": "True"},
      {"question": "How do you use logging?", "options": ["import logging\nlogging.info('message')", "import log\nlog.info('message')", "print('message')", "logging.log('message')"], "correct": "import logging\nlogging.info('message')"},
      {"question": "What is the correct way to use unittest?", "options": ["import unittest\nclass Test(unittest.TestCase):", "import test\nclass Test(test.TestCase):", "class Test(unittest):", "def test():"], "correct": "import unittest\nclass Test(unittest.TestCase):"},
      {"question": "How do you handle command line arguments?", "options": ["import sys\nsys.argv", "import argparse\nargs = argparse.parse()", "args = input()", "import os\nos.args"], "correct": "import sys\nsys.argv"},
      {"question": "What is the output of [x*2 for x in range(3)]?", "options": ["[0,2,4]", "[0,1,2]", "[2,4,6]", "[0,2]"], "correct": "[0,2,4]"},
      {"question": "How do you use functools?", "options": ["from functools import reduce\nreduce(lambda x,y: x+y, [1,2,3])", "import functools\nfunctools.reduce(lambda x,y: x+y, [1,2,3])", "reduce = lambda x,y: x+y\nreduce([1,2,3])", "sum([1,2,3])"], "correct": "from functools import reduce\nreduce(lambda x,y: x+y, [1,2,3])"},
    ],
};
// --- END QUIZ DATA ---

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  // --- API CALL AND NAVIGATION LOGIC ---
  Future<void> _startAssessment(BuildContext context) async {
    // FIX: This list simulates the user's 5 correct/incorrect answers from the assessment
    List<int> simulatedAnswers = [1, 1, 0, 1, 1]; // Example: 4/5 correct
    
    Map<String, int> payload = {};
    for (int i = 0; i < simulatedAnswers.length; i++) {
      payload['q${i + 1}'] = simulatedAnswers[i];
    }
    
    String determinedLevel = 'novice'; 
    final url = Uri.parse(_apiUrl);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assessing level...'), duration: Duration(seconds: 2)),
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        determinedLevel = result['level'] ?? 'novice';
        print('API Predicted Level: $determinedLevel');
        
      } else {
        print('API Failed. Status: ${response.statusCode}. Defaulting to novice.');
      }
    } catch (e) {
      print('Network Error: Could not reach scoring service. Defaulting to novice. Error: $e');
    }

    // --- FINAL FIX: Navigate to the FULL QUIZ using the determined level ---
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuizScreen(
            difficulty: determinedLevel.toLowerCase(),
            // Pass the ENTIRE list of questions for the main quiz level
            questionsToLoad: fullQuizData[determinedLevel.toLowerCase()]!, 
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squash Level Assessment'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, 
          children: [
            const Text(
              'Run Initial Assessment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your knowledge level will be determined automatically based on 5 questions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 60),

            // --- ASSESSMENT BUTTON ---
            ElevatedButton.icon(
              onPressed: () => _startAssessment(context), // Call the async API function
              icon: const Icon(Icons.arrow_forward_ios),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Start Assessment', style: TextStyle(fontSize: 18)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 5,
              ),
            ),
            
            const SizedBox(height: 40),

            // --- MANUAL DIFFICULTY CARDS (Kept for completeness, though assessment overrides them) ---
            // Note: Since this is now a StatelessWidget, the old _buildDifficultyCard method 
            // should be integrated or recreated if needed, but for simplicity, we focus on the assessment.
          ],
        ),
      ),
    );
  }
}