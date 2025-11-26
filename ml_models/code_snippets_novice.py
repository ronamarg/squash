"""
Novice Level Code Snippets (Progression Score: 200-500)
Focus on logic, control flow, loops, and basic data structures
Long enough for the code corruptor to modify effectively
"""

NOVICE_SNIPPETS = [
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

    """def factorial(n):
    if n < 0:
        return None
    if n <= 1:
        return 1
    result = 1
    for i in range(2, n + 1):
        result *= i
    return result

value = factorial(5)
product = factorial(7)
total = value + product
print(value, product, total)""",

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

    """def calculate_average(numbers):
    if len(numbers) == 0:
        return 0
    total = 0
    for num in numbers:
        total += num
    average = total / len(numbers)
    return average

scores = [85, 92, 78, 90, 88]
avg = calculate_average(scores)
print(avg)""",

    """def find_min_max(numbers):
    if len(numbers) == 0:
        return None, None
    min_val = numbers[0]
    max_val = numbers[0]
    for num in numbers:
        if num < min_val:
            min_val = num
        if num > max_val:
            max_val = num
    return min_val, max_val

minimum, maximum = find_min_max([5, 2, 9, 1, 7])
print(minimum, maximum)""",

    """def remove_duplicates(items):
    unique_items = []
    for item in items:
        if item not in unique_items:
            unique_items.append(item)
    return unique_items

data = [1, 2, 2, 3, 3, 3, 4, 5, 5]
result = remove_duplicates(data)
print(result)""",

    """def count_characters(text):
    char_count = {}
    for char in text.lower():
        if char.isalpha():
            if char in char_count:
                char_count[char] += 1
            else:
                char_count[char] = 1
    return char_count

result = count_characters("Hello World")
print(result)""",

    """def calculate_power(base, exponent):
    if exponent == 0:
        return 1
    result = 1
    for i in range(exponent):
        result *= base
    return result

power_result = calculate_power(2, 8)
print(power_result)""",

    """def find_common_elements(list1, list2):
    common = []
    for item in list1:
        if item in list2 and item not in common:
            common.append(item)
    return common

a = [1, 2, 3, 4, 5]
b = [4, 5, 6, 7, 8]
result = find_common_elements(a, b)
print(result)""",
]
