"""
Intermediate Level Code Snippets for Squash Quiz
30 moderately complex Python code examples
"""

INTERMEDIATE_SNIPPETS = [
    # List Comprehensions
    """numbers = [1, 2, 3, 4, 5]
squares = [x**2 for x in numbers]
print(squares)""",

    """words = ["hello", "world", "python"]
upper_words = [w.upper() for w in words]
print(upper_words)""",

    """nums = range(10)
evens = [n for n in nums if n % 2 == 0]
print(evens)""",

    # Dictionary Operations
    """student = {"name": "Alice", "age": 20, "grade": "A"}
print(student.get("name"))""",

    """scores = {"math": 90, "english": 85, "science": 92}
for subject, score in scores.items():
    print(f"{subject}: {score}")""",

    """person = {"name": "Bob"}
person["age"] = 25
person["city"] = "New York"
print(person)""",

    # Functions with Multiple Parameters
    """def calculate_average(numbers):
    total = sum(numbers)
    return total / len(numbers)
    
nums = [10, 20, 30, 40]
print(calculate_average(nums))""",

    """def find_max(a, b, c):
    return max(a, b, c)
    
result = find_max(5, 12, 8)
print(result)""",

    """def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)
    
print(factorial(5))""",

    # String Methods
    """text = "  Python Programming  "
cleaned = text.strip()
print(cleaned)""",

    """email = "user@example.com"
parts = email.split("@")
print(parts[0])""",

    """sentence = "the quick brown fox"
title_case = sentence.title()
print(title_case)""",

    # File Operations
    """with open("data.txt", "w") as file:
    file.write("Hello, World!")""",

    """try:
    with open("input.txt", "r") as f:
        content = f.read()
except FileNotFoundError:
    print("File not found")""",

    # Exception Handling
    """try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero")""",

    """def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return None
        
print(safe_divide(10, 2))""",

    # Classes - Basic
    """class Dog:
    def __init__(self, name):
        self.name = name
    
    def bark(self):
        print(f"{self.name} says woof!")
        
dog = Dog("Buddy")
dog.bark()""",

    """class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height
        
rect = Rectangle(5, 3)
print(rect.area())""",

    # Lambda Functions
    """square = lambda x: x**2
print(square(5))""",

    """numbers = [1, 2, 3, 4, 5]
doubled = list(map(lambda x: x*2, numbers))
print(doubled)""",

    # Filter and Map
    """numbers = [1, 2, 3, 4, 5, 6]
evens = list(filter(lambda x: x % 2 == 0, numbers))
print(evens)""",

    """words = ["apple", "banana", "cherry"]
lengths = list(map(len, words))
print(lengths)""",

    # Set Operations
    """set1 = {1, 2, 3, 4}
set2 = {3, 4, 5, 6}
intersection = set1 & set2
print(intersection)""",

    """numbers = [1, 2, 2, 3, 3, 3, 4]
unique = list(set(numbers))
print(unique)""",

    # Tuple Operations
    """coords = (10, 20)
x, y = coords
print(f"x={x}, y={y}")""",

    """def get_stats():
    return (10, 20, 15)
    
min_val, max_val, avg = get_stats()
print(avg)""",

    # Advanced String Formatting
    """name = "Alice"
age = 25
print(f"{name} is {age} years old")""",

    """pi = 3.14159
print(f"Pi is approximately {pi:.2f}")""",

    # Nested Loops
    """for i in range(3):
    for j in range(3):
        print(f"({i},{j})", end=" ")
    print()""",

    # List Slicing
    """numbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
subset = numbers[2:7]
print(subset)""",

    """items = [10, 20, 30, 40, 50]
reversed_items = items[::-1]
print(reversed_items)"""
]
