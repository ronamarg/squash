"""
Intermediate Level Code Snippets for Squash Quiz
High intermediate to expert level - advanced algorithms and patterns
"""

INTERMEDIATE_SNIPPETS = [
    # Advanced List Comprehensions and Generators
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
print(evens, odds)""",

    # Advanced Dictionary Operations and Data Structures
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

def flatten_dict(d, parent_key='', sep='_'):
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep).items())
        else:
            items.append((new_key, v))
    return dict(items)

result = deep_merge({"a": {"b": 1}}, {"a": {"c": 2}})
flat = flatten_dict({"x": {"y": {"z": 1}}})
print(result, flat)""",

    # Recursive Algorithms
    """def quicksort(arr):
    if len(arr) <= 1:
        return arr
    pivot = arr[len(arr) // 2]
    left = [x for x in arr if x < pivot]
    middle = [x for x in arr if x == pivot]
    right = [x for x in arr if x > pivot]
    return quicksort(left) + middle + quicksort(right)

def partition_pivot(arr):
    pivot = arr[0]
    return [x for x in arr if x < pivot], pivot, [x for x in arr if x > pivot]

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

def is_sorted(arr):
    return all(arr[i] <= arr[i+1] for i in range(len(arr)-1))

sorted_arr = merge_sort([38, 27, 43, 3, 9, 82, 10])
print(sorted_arr, is_sorted(sorted_arr))""",

    """def permutations(arr):
    if len(arr) <= 1:
        return [arr]
    perms = []
    for i in range(len(arr)):
        rest = arr[:i] + arr[i+1:]
        for p in permutations(rest):
            perms.append([arr[i]] + p)
    return perms

def combinations(arr, k):
    if k == 0:
        return [[]]
    if not arr:
        return []
    return combinations(arr[1:], k-1) + [[arr[0]] + c for c in combinations(arr[1:], k-1)]

result = permutations([1, 2, 3])
combs = combinations([1, 2, 3, 4], 2)
print(len(result), len(combs))""",

    # Advanced String Processing
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

    # Graph Algorithms and Data Structures
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

    # Advanced Class Patterns (Decorators, Descriptors)
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

    # Functional Programming Patterns
    """def compose(*functions):
    def inner(arg):
        result = arg
        for func in reversed(functions):
            result = func(result)
        return result
    return inner

add_five = lambda x: x + 5
multiply_two = lambda x: x * 2
square = lambda x: x ** 2

pipeline = compose(square, multiply_two, add_five)
result = pipeline(3)
print(result)""",

    """def curry(func, arity=None):
    if arity is None:
        arity = func.__code__.co_argcount
    
    def curried(*args):
        if len(args) >= arity:
            return func(*args[:arity])
        return lambda *more_args: curried(*(args + more_args))
    return curried

def add_three(a, b, c):
    return a + b + c

curried_add = curry(add_three)
result = curried_add(1)(2)(3)
print(result)""",

    # Advanced Algorithms (Backtracking, Dynamic Programming)
    """def subset_sum(nums, target):
    n = len(nums)
    dp = [[False] * (target + 1) for _ in range(n + 1)]
    for i in range(n + 1):
        dp[i][0] = True
    
    for i in range(1, n + 1):
        for j in range(1, target + 1):
            dp[i][j] = dp[i-1][j]
            if j >= nums[i-1]:
                dp[i][j] = dp[i][j] or dp[i-1][j-nums[i-1]]
    return dp[n][target]

result = subset_sum([3, 34, 4, 12, 5, 2], 9)
print(result)""",

    """def knapsack(weights, values, capacity):
    n = len(weights)
    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
    
    for i in range(1, n + 1):
        for w in range(1, capacity + 1):
            if weights[i-1] <= w:
                dp[i][w] = max(values[i-1] + dp[i-1][w-weights[i-1]], dp[i-1][w])
            else:
                dp[i][w] = dp[i-1][w]
    return dp[n][capacity]

result = knapsack([1, 3, 4, 5], [1, 4, 5, 7], 7)
print(result)""",

    """def n_queens(n):
    def solve(row, cols, diag1, diag2, board):
        if row == n:
            solutions.append([''.join(row) for row in board])
            return
        for col in range(n):
            if col in cols or (row-col) in diag1 or (row+col) in diag2:
                continue
            board[row][col] = 'Q'
            solve(row+1, cols|{col}, diag1|{row-col}, diag2|{row+col}, board)
            board[row][col] = '.'
    
    solutions = []
    solve(0, set(), set(), set(), [['.']*n for _ in range(n)])
    return len(solutions)

result = n_queens(4)
print(result)""",

    # Trie Data Structure
    """class TrieNode:
    def __init__(self):
        self.children = {}
        self.is_end = False

class Trie:
    def __init__(self):
        self.root = TrieNode()
    
    def insert(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_end = True
    
    def search(self, word):
        node = self.root
        for char in word:
            if char not in node.children:
                return False
            node = node.children[char]
        return node.is_end

trie = Trie()
words = ['apple', 'app', 'apricot']
for w in words:
    trie.insert(w)
result = trie.search('app')
print(result)""",

    """class UnionFind:
    def __init__(self, n):
        self.parent = list(range(n))
        self.rank = [0] * n
    
    def find(self, x):
        if self.parent[x] != x:
            self.parent[x] = self.find(self.parent[x])
        return self.parent[x]
    
    def union(self, x, y):
        px, py = self.find(x), self.find(y)
        if px == py:
            return False
        if self.rank[px] < self.rank[py]:
            px, py = py, px
        self.parent[py] = px
        if self.rank[px] == self.rank[py]:
            self.rank[px] += 1
        return True

uf = UnionFind(5)
uf.union(0, 1)
uf.union(1, 2)
result = uf.find(0) == uf.find(2)
print(result)""",

    # Matrix Algorithms
    """def rotate_matrix(matrix):
    n = len(matrix)
    for i in range(n // 2):
        for j in range(i, n - i - 1):
            temp = matrix[i][j]
            matrix[i][j] = matrix[n-1-j][i]
            matrix[n-1-j][i] = matrix[n-1-i][n-1-j]
            matrix[n-1-i][n-1-j] = matrix[j][n-1-i]
            matrix[j][n-1-i] = temp
    return matrix

matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
result = rotate_matrix([row[:] for row in matrix])
print(result)""",

    """def spiral_order(matrix):
    if not matrix:
        return []
    result = []
    top, bottom = 0, len(matrix) - 1
    left, right = 0, len(matrix[0]) - 1
    
    while top <= bottom and left <= right:
        for i in range(left, right + 1):
            result.append(matrix[top][i])
        top += 1
        for i in range(top, bottom + 1):
            result.append(matrix[i][right])
        right -= 1
        if top <= bottom:
            for i in range(right, left - 1, -1):
                result.append(matrix[bottom][i])
            bottom -= 1
        if left <= right:
            for i in range(bottom, top - 1, -1):
                result.append(matrix[i][left])
            left += 1
    return result

matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
result = spiral_order(matrix)
print(result)""",

    # Binary Search Tree
    """class TreeNode:
    def __init__(self, val):
        self.val = val
        self.left = None
        self.right = None

class BST:
    def __init__(self):
        self.root = None
    
    def insert(self, val):
        if not self.root:
            self.root = TreeNode(val)
        else:
            self._insert(self.root, val)
    
    def _insert(self, node, val):
        if val < node.val:
            if node.left:
                self._insert(node.left, val)
            else:
                node.left = TreeNode(val)
        else:
            if node.right:
                self._insert(node.right, val)
            else:
                node.right = TreeNode(val)
    
    def search(self, val):
        return self._search(self.root, val)
    
    def _search(self, node, val):
        if not node:
            return False
        if node.val == val:
            return True
        elif val < node.val:
            return self._search(node.left, val)
        else:
            return self._search(node.right, val)

bst = BST()
for x in [5, 3, 7, 1, 9]:
    bst.insert(x)
result = bst.search(7)
print(result)""",

    """def sliding_window_max(nums, k):
    from collections import deque
    dq = deque()
    result = []
    
    for i, num in enumerate(nums):
        while dq and dq[0] < i - k + 1:
            dq.popleft()
        while dq and nums[dq[-1]] < num:
            dq.pop()
        dq.append(i)
        if i >= k - 1:
            result.append(nums[dq[0]])
    return result

nums = [1, 3, -1, -3, 5, 3, 6, 7]
result = sliding_window_max(nums, 3)
print(result)""",

    # Heap and Priority Queue
    """import heapq

def k_closest_points(points, k):
    heap = []
    for x, y in points:
        dist = -(x*x + y*y)
        if len(heap) < k:
            heapq.heappush(heap, (dist, x, y))
        elif dist > heap[0][0]:
            heapq.heapreplace(heap, (dist, x, y))
    return [(x, y) for _, x, y in heap]

points = [(1, 3), (-2, 2), (5, 8), (0, 1)]
result = k_closest_points(points, 2)
print(result)""",

    """def merge_k_sorted_lists(lists):
    import heapq
    heap = []
    for i, lst in enumerate(lists):
        if lst:
            heapq.heappush(heap, (lst[0], i, 0))
    
    result = []
    while heap:
        val, list_idx, elem_idx = heapq.heappop(heap)
        result.append(val)
        if elem_idx + 1 < len(lists[list_idx]):
            next_val = lists[list_idx][elem_idx + 1]
            heapq.heappush(heap, (next_val, list_idx, elem_idx + 1))
    return result

lists = [[1, 4, 5], [1, 3, 4], [2, 6]]
result = merge_k_sorted_lists(lists)
print(result)""",

    # Bit Manipulation
    """def count_set_bits(n):
    count = 0
    while n:
        count += n & 1
        n >>= 1
    return count

def is_power_of_two(n):
    return n > 0 and (n & (n - 1)) == 0

def reverse_bits(n):
    result = 0
    for _ in range(32):
        result = (result << 1) | (n & 1)
        n >>= 1
    return result

bits = count_set_bits(15)
power = is_power_of_two(16)
reversed_val = reverse_bits(43261596)
print(bits, power, reversed_val)""",

    # Topological Sort
    """def topological_sort(graph):
    from collections import deque, defaultdict
    in_degree = defaultdict(int)
    for node in graph:
        for neighbor in graph[node]:
            in_degree[neighbor] += 1
    
    queue = deque([node for node in graph if in_degree[node] == 0])
    result = []
    
    while queue:
        node = queue.popleft()
        result.append(node)
        for neighbor in graph[node]:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.append(neighbor)
    
    return result if len(result) == len(graph) else []

graph = {0: [1, 2], 1: [3], 2: [3], 3: []}
result = topological_sort(graph)
print(result)""",

    # Segment Tree
    """class SegmentTree:
    def __init__(self, arr):
        self.n = len(arr)
        self.tree = [0] * (4 * self.n)
        self.build(arr, 0, 0, self.n - 1)
    
    def build(self, arr, node, start, end):
        if start == end:
            self.tree[node] = arr[start]
        else:
            mid = (start + end) // 2
            self.build(arr, 2*node+1, start, mid)
            self.build(arr, 2*node+2, mid+1, end)
            self.tree[node] = self.tree[2*node+1] + self.tree[2*node+2]
    
    def query(self, node, start, end, l, r):
        if r < start or end < l:
            return 0
        if l <= start and end <= r:
            return self.tree[node]
        mid = (start + end) // 2
        return self.query(2*node+1, start, mid, l, r) + self.query(2*node+2, mid+1, end, l, r)
    
    def range_sum(self, l, r):
        return self.query(0, 0, self.n - 1, l, r)

st = SegmentTree([1, 3, 5, 7, 9, 11])
result = st.range_sum(1, 3)
print(result)"""
]
