"""
Novice Level Code Snippets for Squash Quiz
Beginner to intermediate level - focus on logic and control flow
"""

NOVICE_SNIPPETS = [
    # Variables and Conditional Logic
    """def calculate_discount(price, is_member):
    if is_member:
        discount = price * 0.20
        final_price = price - discount
    else:
        discount = price * 0.10
        final_price = price - discount
    return final_price

result = calculate_discount(100, True)
print(result)""",

    """def check_eligibility(age, has_license):
    if age >= 18 and has_license:
        status = "eligible"
    elif age >= 18 and not has_license:
        status = "needs_license"
    else:
        status = "too_young"
    return status

eligibility = check_eligibility(20, True)
print(eligibility)""",

    """def calculate_grade(score):
    if score >= 90:
        grade = "A"
        points = 4.0
    elif score >= 80:
        grade = "B"
        points = 3.0
    elif score >= 70:
        grade = "C"
        points = 2.0
    else:
        grade = "F"
        points = 0.0
    return grade, points

letter, gpa = calculate_grade(85)
print(letter, gpa)""",

    # Loop Logic and Accumulation
    """def sum_even_numbers(limit):
    total = 0
    for i in range(1, limit + 1):
        if i % 2 == 0:
            total += i
    return total

result = sum_even_numbers(10)
print(result)""",

    """def count_vowels(text):
    vowels = "aeiou"
    count = 0
    for char in text.lower():
        if char in vowels:
            count += 1
    return count

num_vowels = count_vowels("Hello World")
print(num_vowels)""",

    """def find_maximum(numbers):
    if len(numbers) == 0:
        return None
    max_val = numbers[0]
    for num in numbers:
        if num > max_val:
            max_val = num
    return max_val

result = find_maximum([3, 7, 2, 9, 1])
print(result)""",

    # List Processing
    """def filter_positive(numbers):
    positive_nums = []
    for num in numbers:
        if num > 0:
            positive_nums.append(num)
    return positive_nums

result = filter_positive([-2, 5, -1, 8, 0, 3])
print(result)""",

    """def reverse_list(items):
    reversed_items = []
    for i in range(len(items) - 1, -1, -1):
        reversed_items.append(items[i])
    return reversed_items

result = reverse_list([1, 2, 3, 4, 5])
print(result)""",

    """def find_duplicates(numbers):
    duplicates = []
    for i in range(len(numbers)):
        for j in range(i + 1, len(numbers)):
            if numbers[i] == numbers[j] and numbers[i] not in duplicates:
                duplicates.append(numbers[i])
    return duplicates

result = find_duplicates([1, 2, 3, 2, 4, 3])
print(result)""",

    # String Processing Logic
    """def is_palindrome(word):
    cleaned = word.lower()
    reversed_word = cleaned[::-1]
    if cleaned == reversed_word:
        return True
    else:
        return False

result = is_palindrome("Racecar")
print(result)""",

    """def count_words(sentence):
    words = sentence.split()
    word_count = len(words)
    char_count = 0
    for word in words:
        char_count += len(word)
    return word_count, char_count

words, chars = count_words("The quick brown fox")
print(words, chars)""",

    """def extract_numbers(text):
    numbers = []
    for char in text:
        if char.isdigit():
            numbers.append(int(char))
    return numbers

result = extract_numbers("abc123xyz456")
print(result)""",

    # Function Logic
    """def factorial(n):
    if n <= 1:
        return 1
    result = 1
    for i in range(2, n + 1):
        result *= i
    return result

value = factorial(5)
print(value)""",

    """def fibonacci(n):
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    else:
        a, b = 0, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b

result = fibonacci(7)
print(result)""",

    """def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True

result = is_prime(17)
print(result)""",

    # Dictionary and Data Structures
    """def merge_dicts(dict1, dict2):
    merged = {}
    for key, value in dict1.items():
        merged[key] = value
    for key, value in dict2.items():
        merged[key] = value
    return merged

result = merge_dicts({"a": 1, "b": 2}, {"c": 3, "d": 4})
print(result)""",

    """def count_frequency(items):
    frequency = {}
    for item in items:
        if item in frequency:
            frequency[item] += 1
        else:
            frequency[item] = 1
    return frequency

result = count_frequency([1, 2, 2, 3, 3, 3, 4])
print(result)""",

    """def group_by_length(words):
    groups = {}
    for word in words:
        length = len(word)
        if length not in groups:
            groups[length] = []
        groups[length].append(word)
    return groups

result = group_by_length(["cat", "dog", "elephant", "fox"])
print(result)""",

    # Advanced Control Flow
    """def binary_search(arr, target):
    left, right = 0, len(arr) - 1
    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1
    return -1

result = binary_search([1, 3, 5, 7, 9, 11], 7)
print(result)""",

    """def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]
    return arr

result = bubble_sort([64, 34, 25, 12, 22, 11, 90])
print(result)""",

    """def validate_password(password):
    if len(password) < 8:
        return False
    has_digit = False
    has_upper = False
    for char in password:
        if char.isdigit():
            has_digit = True
        if char.isupper():
            has_upper = True
    return has_digit and has_upper

result = validate_password("Pass123")
print(result)""",
]
