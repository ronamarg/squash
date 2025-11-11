"""
Comprehensive Test Cases for RevertV3 Code Corruptor
====================================================

Tests various Python code patterns from simple to complex to verify
that the enhanced T5 model can corrupt different code structures.

Run with: py test_cases.py
"""

from revertV3 import RevertV3


# Test cases organized by complexity
TEST_CASES = {
    "SIMPLE": [
        {
            "name": "Basic Addition",
            "code": """x = 5
y = 10
result = x + y
print(result)"""
        },
        {
            "name": "Simple If Statement",
            "code": """age = 18
if age >= 18:
    print("Adult")
else:
    print("Minor")"""
        },
        {
            "name": "Basic Loop",
            "code": """for i in range(5):
    print(i)"""
        },
        {
            "name": "List Operations",
            "code": """numbers = [1, 2, 3, 4, 5]
total = sum(numbers)
print(total)"""
        },
    ],
    
    "INTERMEDIATE": [
        {
            "name": "Function with Parameters",
            "code": """def calculate_area(length, width):
    area = length * width
    return area

result = calculate_area(5, 10)
print('Area:', result)"""
        },
        {
            "name": "List Comprehension",
            "code": """numbers = [1, 2, 3, 4, 5]
squares = [x ** 2 for x in numbers]
print(squares)"""
        },
        {
            "name": "While Loop",
            "code": """count = 0
while count < 5:
    print(count)
    count += 1"""
        },
        {
            "name": "Dictionary Operations",
            "code": """person = {'name': 'Alice', 'age': 25}
for key, value in person.items():
    print(f'{key}: {value}')"""
        },
        {
            "name": "String Manipulation",
            "code": """text = "Hello World"
words = text.split()
for word in words:
    print(word.lower())"""
        },
    ],
    
    "ADVANCED": [
        {
            "name": "Nested Loops",
            "code": """matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
for row in matrix:
    for num in row:
        if num % 2 == 0:
            print(num)"""
        },
        {
            "name": "Recursive Function",
            "code": """def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)

result = factorial(5)
print('Factorial:', result)"""
        },
        {
            "name": "Class Definition",
            "code": """class Circle:
    def __init__(self, radius):
        self.radius = radius
    
    def area(self):
        return 3.14 * self.radius ** 2

c = Circle(5)
print('Area:', c.area())"""
        },
        {
            "name": "Error Handling",
            "code": """def divide(a, b):
    try:
        result = a / b
        return result
    except ZeroDivisionError:
        return 0

print(divide(10, 2))"""
        },
        {
            "name": "Multiple Conditions",
            "code": """def check_grade(score):
    if score >= 90:
        return 'A'
    elif score >= 80:
        return 'B'
    elif score >= 70:
        return 'C'
    else:
        return 'F'

grade = check_grade(85)
print('Grade:', grade)"""
        },
    ],
    
    "COMPLEX": [
        {
            "name": "Sorting Algorithm (Bubble Sort)",
            "code": """def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr

numbers = [64, 34, 25, 12, 22]
sorted_nums = bubble_sort(numbers)
print(sorted_nums)"""
        },
        {
            "name": "Binary Search",
            "code": """def binary_search(arr, target):
    left = 0
    right = len(arr) - 1
    
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1

nums = [1, 3, 5, 7, 9, 11]
index = binary_search(nums, 7)
print('Index:', index)"""
        },
        {
            "name": "File Processing",
            "code": """def process_data(filename):
    total = 0
    count = 0
    
    with open(filename, 'r') as f:
        for line in f:
            value = int(line.strip())
            total += value
            count += 1
    
    return total / count if count > 0 else 0

average = process_data('data.txt')
print('Average:', average)"""
        },
        {
            "name": "Generator Function",
            "code": """def fibonacci(n):
    a, b = 0, 1
    for _ in range(n):
        yield a
        a, b = b, a + b

for num in fibonacci(10):
    print(num)"""
        },
        {
            "name": "Decorator Pattern",
            "code": """def timer(func):
    def wrapper(*args, **kwargs):
        import time
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f'Time: {end - start}')
        return result
    return wrapper

@timer
def slow_function():
    total = 0
    for i in range(1000000):
        total += i
    return total

result = slow_function()"""
        },
    ]
}


def run_test_case(test_case, difficulty='beginner', show_original=True):
    """Run a single test case and display results"""
    print(f"\n{'='*70}")
    print(f"Test: {test_case['name']}")
    print(f"Difficulty: {difficulty.upper()}")
    print('='*70)
    
    if show_original:
        print("\nORIGINAL CODE:")
        print('-'*70)
        print(test_case['code'])
    
    corruptor = RevertV3(difficulty=difficulty)
    result = corruptor.corrupt_verbose(test_case['code'])
    
    print(f"\nCORRUPTION SETTINGS:")
    print(f"  - Passes: {result['num_passes']}")
    print(f"  - Temperature: {result['temperature']}")
    
    print(f"\nCORRUPTED CODE:")
    print('-'*70)
    print(result['corrupted'])
    
    # Show diff analysis
    original_lines = test_case['code'].strip().split('\n')
    corrupted_lines = result['corrupted'].strip().split('\n')
    
    if original_lines != corrupted_lines:
        print(f"\nCHANGES DETECTED:")
        print('-'*70)
        changes_found = []
        
        # Simple line-by-line comparison
        max_lines = max(len(original_lines), len(corrupted_lines))
        for i in range(max_lines):
            orig = original_lines[i] if i < len(original_lines) else ""
            corr = corrupted_lines[i] if i < len(corrupted_lines) else ""
            
            if orig != corr:
                if orig and corr:
                    changes_found.append(f"Line {i+1} CHANGED:")
                    changes_found.append(f"  - {orig}")
                    changes_found.append(f"  + {corr}")
                elif corr:
                    changes_found.append(f"Line {i+1} ADDED:")
                    changes_found.append(f"  + {corr}")
                elif orig:
                    changes_found.append(f"Line {i+1} DELETED:")
                    changes_found.append(f"  - {orig}")
        
        if changes_found:
            for change in changes_found[:20]:  # Limit to first 20 changes
                print(change)
            if len(changes_found) > 20:
                print(f"  ... and {len(changes_found) - 20} more changes")
        else:
            print("Code structure changed but lines are similar")
    else:
        print(f"\nNO CHANGES: Code remained the same")


def run_category(category_name, difficulty='beginner', limit=None):
    """Run all tests in a category"""
    print("\n" + "="*70)
    print(f"CATEGORY: {category_name}")
    print("="*70)
    
    cases = TEST_CASES[category_name]
    if limit:
        cases = cases[:limit]
    
    for test_case in cases:
        run_test_case(test_case, difficulty, show_original=True)  # Always show original


def run_all_tests(difficulty='beginner'):
    """Run all test cases"""
    print("\n" + "="*70)
    print(f"RUNNING ALL TESTS - Difficulty: {difficulty.upper()}")
    print("="*70)
    
    for category in ['SIMPLE', 'INTERMEDIATE', 'ADVANCED', 'COMPLEX']:
        run_category(category, difficulty, limit=2)  # 2 per category


def interactive_mode():
    """Interactive mode to test specific cases"""
    print("\n" + "="*70)
    print("INTERACTIVE TEST MODE")
    print("="*70)
    
    print("\nCategories:")
    for i, category in enumerate(TEST_CASES.keys(), 1):
        print(f"  {i}. {category} ({len(TEST_CASES[category])} tests)")
    
    print("\nOptions:")
    print("  - Enter category number to see all tests in that category")
    print("  - Enter 'all' to run all tests")
    print("  - Enter 'q' to quit")
    
    choice = input("\nYour choice: ").strip().lower()
    
    if choice == 'q':
        return
    elif choice == 'all':
        difficulty = input("Difficulty (beginner/advanced) [beginner]: ").strip().lower() or 'beginner'
        run_all_tests(difficulty)
    elif choice.isdigit():
        cat_idx = int(choice) - 1
        if 0 <= cat_idx < len(TEST_CASES):
            category = list(TEST_CASES.keys())[cat_idx]
            difficulty = input("Difficulty (beginner/advanced) [beginner]: ").strip().lower() or 'beginner'
            run_category(category, difficulty)


if __name__ == "__main__":
    import sys
    
    print("="*70)
    print("RevertV3 Test Suite")
    print("="*70)
    print(f"\nTotal test cases: {sum(len(cases) for cases in TEST_CASES.values())}")
    for category, cases in TEST_CASES.items():
        print(f"  • {category}: {len(cases)} tests")
    
    if len(sys.argv) > 1:
        # Command line mode
        if sys.argv[1] == 'all':
            difficulty = sys.argv[2] if len(sys.argv) > 2 else 'beginner'
            run_all_tests(difficulty)
        elif sys.argv[1] in TEST_CASES:
            category = sys.argv[1]
            difficulty = sys.argv[2] if len(sys.argv) > 2 else 'beginner'
            run_category(category, difficulty)
        else:
            print(f"\nUsage:")
            print(f"  py test_cases.py all [beginner|advanced]")
            print(f"  py test_cases.py SIMPLE [beginner|advanced]")
            print(f"  py test_cases.py INTERMEDIATE [beginner|advanced]")
            print(f"  py test_cases.py ADVANCED [beginner|advanced]")
            print(f"  py test_cases.py COMPLEX [beginner|advanced]")
    else:
        # Interactive mode
        interactive_mode()
    
    print("\n" + "="*70)
    print("Done! 🎉")
    print("="*70)
