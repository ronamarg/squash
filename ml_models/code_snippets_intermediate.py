"""
Intermediate Level Code Snippets (Progression Score: 500-700)
Advanced algorithms, OOP basics, and data structures
Long enough for the code corruptor to modify effectively
"""

INTERMEDIATE_SNIPPETS = [
    """def flatten_matrix(matrix):
    flattened = [val for row in matrix for val in row]
    evens = [x for x in flattened if x % 2 == 0]
    squared = {x: x**2 for x in flattened}
    return flattened, evens, squared

flat, evens, sq = flatten_matrix([[1,2], [3,4], [5,6]])
print(flat, evens, sq)""",

    """def generate_primes(n):
    primes = []
    for num in range(2, n):
        is_prime = True
        for i in range(2, int(num ** 0.5) + 1):
            if num % i == 0:
                is_prime = False
                break
        if is_prime:
            primes.append(num)
    return primes

result = generate_primes(30)
print(result)""",

    """def partition_array(arr, predicate):
    true_list = [x for x in arr if predicate(x)]
    false_list = [x for x in arr if not predicate(x)]
    return true_list, false_list

evens, odds = partition_array(range(20), lambda x: x % 2 == 0)
print(list(evens), list(odds))""",

    """class LRUCache:
    def __init__(self, capacity):
        self.capacity = capacity
        self.cache = {}
        self.order = []
    
    def get(self, key):
        if key in self.cache:
            self.order.remove(key)
            self.order.append(key)
            return self.cache[key]
        return -1

cache = LRUCache(3)
print(cache.get("a"))""",

    """def invert_dict(d):
    inverted = {}
    for key, value in d.items():
        if value not in inverted:
            inverted[value] = []
        inverted[value].append(key)
    return inverted

def group_by_value(d):
    return {v: [k for k, val in d.items() if val == v] for v in set(d.values())}

result = invert_dict({"a": 1, "b": 2, "c": 1, "d": 3})
grouped = group_by_value({"x": "A", "y": "B", "z": "A"})
print(result, grouped)""",

    """def deep_merge(dict1, dict2):
    merged = dict1.copy()
    for key, value in dict2.items():
        if key in merged and isinstance(merged[key], dict) and isinstance(value, dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged

result = deep_merge({"a": {"b": 1}}, {"a": {"c": 2}})
print(result)""",

    """def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)

result = quicksort([3, 6, 8, 10, 1, 2, 1])
print(result)""",

    """def merge_sort(arr):
    if len(arr) <= 1:
        return arr
    mid = len(arr) // 2
    left = merge_sort(arr[:mid])
    right = merge_sort(arr[mid:])
    return merge(left, right)

def merge(left, right):
    result = []
    i = j = 0
    while i < len(left) and j < len(right):
        if left[i] < right[j]:
            result.append(left[i])
            i += 1
        else:
            result.append(right[j])
            j += 1
    result.extend(left[i:])
    result.extend(right[j:])
    return result

sorted_arr = merge_sort([38, 27, 43, 3, 9, 82, 10])
print(sorted_arr)""",

    """def permutations(arr):
    if len(arr) <= 1:
        return [arr]
    perms = []
    for i in range(len(arr)):
        rest = arr[:i] + arr[i+1:]
        for p in permutations(rest):
            perms.append([arr[i]] + p)
    return perms

result = permutations([1, 2, 3])
print(len(result))""",

    """def longest_common_subsequence(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    return dp[m][n]

result = longest_common_subsequence("ABCBDAB", "BDCAB")
print(result)""",

    """def edit_distance(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    for i in range(m + 1):
        dp[i][0] = i
    for j in range(n + 1):
        dp[0][j] = j
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1]
            else:
                dp[i][j] = 1 + min(dp[i-1][j], dp[i][j-1], dp[i-1][j-1])
    return dp[m][n]

result = edit_distance("kitten", "sitting")
print(result)""",

    """class Graph:
    def __init__(self):
        self.graph = {}
    
    def add_edge(self, u, v):
        if u not in self.graph:
            self.graph[u] = []
        self.graph[u].append(v)
    
    def dfs(self, start, visited=None):
        if visited is None:
            visited = set()
        visited.add(start)
        for neighbor in self.graph.get(start, []):
            if neighbor not in visited:
                self.dfs(neighbor, visited)
        return visited

g = Graph()
g.add_edge(0, 1)
g.add_edge(0, 2)
g.add_edge(1, 2)
result = g.dfs(0)
print(result)""",

    """def dijkstra(graph, start):
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    unvisited = set(graph.keys())
    
    while unvisited:
        current = min(unvisited, key=lambda node: distances[node])
        unvisited.remove(current)
        
        for neighbor, weight in graph[current].items():
            distance = distances[current] + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
    return distances

graph = {0: {1: 4, 2: 1}, 1: {3: 1}, 2: {1: 2, 3: 5}, 3: {}}
result = dijkstra(graph, 0)
print(result)""",

    """class memoize:
    def __init__(self, func):
        self.func = func
        self.cache = {}
    
    def __call__(self, *args):
        if args not in self.cache:
            self.cache[args] = self.func(*args)
        return self.cache[args]

@memoize
def fibonacci(n):
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

result = [fibonacci(i) for i in range(10)]
print(result)""",

    """class Singleton:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.value = 0
        return cls._instance
    
    def increment(self):
        self.value += 1
        return self.value

s1 = Singleton()
s2 = Singleton()
print(s1.increment(), s2.increment(), s1 is s2)""",

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

sorted_list = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19]
result = binary_search(sorted_list, 11)
print(result)""",

    """def selection_sort(arr):
    n = len(arr)
    for i in range(n):
        min_idx = i
        for j in range(i + 1, n):
            if arr[j] < arr[min_idx]:
                min_idx = j
        arr[i], arr[min_idx] = arr[min_idx], arr[i]
    return arr

data = [64, 25, 12, 22, 11]
sorted_data = selection_sort(data.copy())
print(sorted_data)""",

    """def insertion_sort(arr):
    for i in range(1, len(arr)):
        key = arr[i]
        j = i - 1
        while j >= 0 and arr[j] > key:
            arr[j + 1] = arr[j]
            j -= 1
        arr[j + 1] = key
    return arr

data = [12, 11, 13, 5, 6]
sorted_data = insertion_sort(data.copy())
print(sorted_data)""",

    """def matrix_multiply(A, B):
    rows_A = len(A)
    cols_A = len(A[0])
    cols_B = len(B[0])
    result = [[0 for _ in range(cols_B)] for _ in range(rows_A)]
    for i in range(rows_A):
        for j in range(cols_B):
            for k in range(cols_A):
                result[i][j] += A[i][k] * B[k][j]
    return result

A = [[1, 2], [3, 4]]
B = [[5, 6], [7, 8]]
product = matrix_multiply(A, B)
print(product)""",

    """def find_subsets(arr):
    result = [[]]
    for num in arr:
        result += [subset + [num] for subset in result]
    return result

numbers = [1, 2, 3]
subsets = find_subsets(numbers)
print(subsets)""",
]
