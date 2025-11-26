SNIPPETS = [
"""def process_scores(scores, min_pass):
    passed = []
    total = 0
    for s in scores:
        if s >= min_pass:
            passed.append(s)
            total = total + s
        else:
            total = total - 1
    
    if len(passed) > 0:
        avg = total / len(passed)
    else:
        avg = 0
        
    print(f"Passed: {len(passed)} students")
    print(f"Adjusted Average: {avg}")
process_scores([40, 60, 80, 55, 90], 50)""",

"""def calc_ratios(values, divisor):
    results = []
    skipped = 0
    
    if divisor == 0:
        print("Critical Error: Divisor is 0")
        return

    for v in values:
        if v % divisor == 0:
            results.append(v // divisor)
        else:
            skipped = skipped + 1
            
    print(f"Clean Ratios: {results}")
    print(f"Values skipped: {skipped}")
calc_ratios([10, 23, 40, 55, 62], 5)""",

"""def attempt_login(guesses, secret):
    penalty = 0
    locked = False
    
    for guess in guesses:
        if locked:
            print("System Locked. Contact Admin.")
            break
            
        if guess == secret:
            print("Access Granted.")
            return
        else:
            penalty = penalty + 1
            if penalty >= 3:
                locked = True
                
    if locked:
        print(f"Login Failed. Penalty: {penalty}")
attempt_login(["admin", "1234", "password", "secret"], "secret")""",

"""def analyze_numbers(nums):
    evens_sum = 0
    odds_sum = 0
    e_list = []
    o_list = []
    
    for n in nums:
        if n % 2 == 0:
            evens_sum = evens_sum + n
            e_list.append(n)
        else:
            odds_sum = odds_sum + n
            o_list.append(n)
            
    print(f"Evens: {e_list} (Sum {evens_sum})")
    print(f"Odds: {o_list} (Sum {odds_sum})")
analyze_numbers([1, 2, 3, 4, 5, 6])""",

"""def find_long_words(text, min_len):
    words = text.split(" ")
    found = []
    count = 0
    
    for w in words:
        if len(w) > min_len:
            found.append(w.upper())
            count = count + 1
            
    print(f"Found {count} words > {min_len} chars:")
    print(found)
find_long_words("The quick brown fox jumps over the lazy dog", 3)""",

"""def calculate_group_cost(ages):
    total = 0
    tickets = 0
    
    for age in ages:
        tickets = tickets + 1
        if age < 5:
            cost = 0
        elif age < 18:
            cost = 10
        elif age < 65:
            cost = 20
        else:
            cost = 15
        total = total + cost
        
    print(f"Total Tickets: {tickets}")
    print(f"Total Cost: ${total}")
calculate_group_cost([3, 15, 25, 70, 40])""",

"""def locate_all(items, target):
    indices = []
    count = 0
    idx = 0
    
    for item in items:
        if item == target:
            indices.append(idx)
            count = count + 1
        idx = idx + 1
        
    if count > 0:
        print(f"Found '{target}' {count} times.")
        print(f"Locations: {indices}")
    else:
        print("Target not found in list.")
locate_all(["a", "b", "a", "c", "a"], "a")""",

"""def split_stream(stream):
    pos = []
    neg = []
    zeros = 0
    
    for val in stream:
        if val > 0:
            pos.append(val)
        elif val < 0:
            neg.append(val)
        else:
            zeros = zeros + 1
            
    print(f"Positives: {len(pos)} items -> {pos}")
    print(f"Negatives: {len(neg)} items -> {neg}")
    print(f"Zeros ignored: {zeros}")
split_stream([10, -2, 0, 5, -8, 0, 3])""",

"""def class_stats(grades):
    passing = 0
    failing = 0
    total = 0
    
    for g in grades:
        total = total + g
        if g >= 60:
            passing = passing + 1
        else:
            failing = failing + 1
            
    avg = total / len(grades)
    print(f"Pass: {passing} | Fail: {failing}")
    print(f"Class Average: {avg}")
class_stats([55, 80, 90, 40, 75])""",

"""def count_vowels_consonants(text):
    vowels = "aeiou"
    v_count = 0
    c_count = 0
    clean = text.lower()
    
    for char in clean:
        if char in vowels:
            v_count = v_count + 1
        elif char.isalpha():
            c_count = c_count + 1
            
    print(f"Analysis of: '{text}'")
    print(f"Vowels: {v_count}")
    print(f"Consonants: {c_count}")
count_vowels_consonants("Hello World")""",

"""def shopping_trip(prices, budget):
    cart = []
    spent = 0
    
    for p in prices:
        if spent + p <= budget:
            cart.append(p)
            spent = spent + p
        else:
            print(f"Skipping item cost ${p} (Too expensive)")
            
    print(f"Bought {len(cart)} items: {cart}")
    print(f"Total spent: ${spent}")
    print(f"Change: ${budget - spent}")
shopping_trip([20, 50, 10, 40, 15], 100)""",

"""def process_numbers(raw_data):
    processed = []
    discarded = 0
    
    for n in raw_data:
        if n > 0:
            squared = n * n
            if squared < 100:
                processed.append(squared)
            else:
                discarded = discarded + 1
                
    print(f"Processed List: {processed}")
    print(f"Large items discarded: {discarded}")
process_numbers([2, 5, 12, 8, -3, 15])""",

"""def launch_sequence(t_minus):
    aborted = False
    
    while t_minus > 0:
        if t_minus == 3:
            print("Ignition engines...")
        
        if t_minus == 100: 
            aborted = True
            break
            
        print(f"T-minus {t_minus}")
        t_minus = t_minus - 1
        
    if not aborted:
        print("Liftoff successful!")
    else:
        print("Launch Aborted.")
launch_sequence(5)""",

"""def validate_user(user_role, is_active, has_badge):
    access = False
    
    if not is_active:
        print("Error: User account inactive")
    elif user_role == "admin":
        access = True
    elif user_role == "staff" and has_badge:
        access = True
    
    if access:
        print(f"Door Unlocked for {user_role}")
    else:
        print("Access Denied")
validate_user("staff", True, False)""",

"""def monitor_system(readings):
    alerts = 0
    safe = []
    
    for temp in readings:
        if temp > 90:
            print(f"ALERT: High Temp {temp}")
            alerts = alerts + 1
        elif temp < 10:
            print(f"ALERT: Low Temp {temp}")
            alerts = alerts + 1
        else:
            safe.append(temp)
            
    print(f"System Check Complete.")
    print(f"Total Alerts: {alerts}")
    print(f"Safe Readings: {len(safe)}")
monitor_system([50, 95, 20, 5, 60])""",
]