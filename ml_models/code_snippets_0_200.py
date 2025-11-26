SNIPPETS = [
"""def show_welcome(name):
    print("--- SYSTEM ---")
    print(f"Welcome, {name}!")
    print("--------------")
show_welcome("User")""",

"""def check_battery(level):
    if level < 20:
        print("Low Battery!")
    else:
        print("Battery Good.")
check_battery(15)""",

"""def double_number(num):
    result = num * 2
    print(f"{num} doubled is {result}")
    return result
double_number(10)""",

"""def get_first_item(items):
    if items:
        print(f"First: {items[0]}")
    else:
        print("Empty list")
get_first_item(['a', 'b', 'c'])""",

"""def loop_three_times():
    for i in range(3):
        print("Knock knock...")
    print("Who's there?")
loop_three_times()""",

"""def is_equal(a, b):
    if a == b:
        print("They are same")
    else:
        print("They are different")
is_equal(5, 5)""",

"""def km_to_miles(km):
    miles = km * 0.621371
    print(f"{km}km is {miles}mi")
km_to_miles(10)""",

"""def check_list_length(data):
    size = len(data)
    print(f"List has {size} items")
check_list_length([1, 2, 3, 4])""",

"""def simple_while(count):
    while count > 0:
        print(count)
        count = count - 1
simple_while(3)""",

"""def string_combine(a, b):
    full = a + " " + b
    print(full)
string_combine("Hello", "World")""",

"""def check_negative(num):
    if num < 0:
        print("Negative number detected")
    print("Check complete")
check_negative(-5)""",

"""def last_item_safe(data):
    if len(data) > 0:
        print(data[-1])
last_item_safe([10, 20, 30])""",

"""def print_square(num):
    sq = num * num
    print(f"{num} squared is {sq}")
print_square(4)""",

"""def boolean_check(is_on):
    if is_on:
        print("System is ON")
    else:
        print("System is OFF")
boolean_check(False)""",

"""def say_hello_many(times):
    for i in range(times):
        print(f"Hello #{i+1}")
say_hello_many(3)""",
]