"""
Advanced Level Code Snippets (Progression Score: 700-1000)
Expert-level algorithms, complex data structures, and advanced patterns
Long enough for the code corruptor to modify effectively
"""

ADVANCED_SNIPPETS = [
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
print(result)""",

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

    """def lcs_dp(s1, s2):
    m, n = len(s1), len(s2)
    dp = [[0] * (n + 1) for _ in range(m + 1)]
    
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i-1] == s2[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])
    
    lcs = []
    i, j = m, n
    while i > 0 and j > 0:
        if s1[i-1] == s2[j-1]:
            lcs.append(s1[i-1])
            i -= 1
            j -= 1
        elif dp[i-1][j] > dp[i][j-1]:
            i -= 1
        else:
            j -= 1
    return ''.join(reversed(lcs))

result = lcs_dp("ABCDGH", "AEDFHR")
print(result)""",

    """def coin_change(coins, amount):
    dp = [float('inf')] * (amount + 1)
    dp[0] = 0
    
    for coin in coins:
        for x in range(coin, amount + 1):
            dp[x] = min(dp[x], dp[x - coin] + 1)
    
    return dp[amount] if dp[amount] != float('inf') else -1

coins = [1, 5, 10, 25]
amount = 63
min_coins = coin_change(coins, amount)
print(min_coins)""",

    """def longest_increasing_subsequence(nums):
    if not nums:
        return 0
    
    n = len(nums)
    dp = [1] * n
    parent = [-1] * n
    
    for i in range(1, n):
        for j in range(i):
            if nums[j] < nums[i] and dp[j] + 1 > dp[i]:
                dp[i] = dp[j] + 1
                parent[i] = j
    
    max_len = max(dp)
    idx = dp.index(max_len)
    
    lis = []
    while idx != -1:
        lis.append(nums[idx])
        idx = parent[idx]
    return list(reversed(lis))

nums = [10, 9, 2, 5, 3, 7, 101, 18]
result = longest_increasing_subsequence(nums)
print(result)""",

    """class AVLNode:
    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None
        self.height = 1

class AVLTree:
    def get_height(self, node):
        if not node:
            return 0
        return node.height
    
    def get_balance(self, node):
        if not node:
            return 0
        return self.get_height(node.left) - self.get_height(node.right)
    
    def right_rotate(self, y):
        x = y.left
        T2 = x.right
        x.right = y
        y.left = T2
        y.height = 1 + max(self.get_height(y.left), self.get_height(y.right))
        x.height = 1 + max(self.get_height(x.left), self.get_height(x.right))
        return x
    
    def left_rotate(self, x):
        y = x.right
        T2 = y.left
        y.left = x
        x.right = T2
        x.height = 1 + max(self.get_height(x.left), self.get_height(x.right))
        y.height = 1 + max(self.get_height(y.left), self.get_height(y.right))
        return y

avl = AVLTree()
print(avl.get_height(None))""",

    """def kmp_search(pattern, text):
    def compute_lps(pattern):
        lps = [0] * len(pattern)
        length = 0
        i = 1
        while i < len(pattern):
            if pattern[i] == pattern[length]:
                length += 1
                lps[i] = length
                i += 1
            else:
                if length != 0:
                    length = lps[length - 1]
                else:
                    lps[i] = 0
                    i += 1
        return lps
    
    lps = compute_lps(pattern)
    matches = []
    i = j = 0
    
    while i < len(text):
        if pattern[j] == text[i]:
            i += 1
            j += 1
        
        if j == len(pattern):
            matches.append(i - j)
            j = lps[j - 1]
        elif i < len(text) and pattern[j] != text[i]:
            if j != 0:
                j = lps[j - 1]
            else:
                i += 1
    return matches

text = "ABABDABACDABABCABAB"
pattern = "ABABCABAB"
result = kmp_search(pattern, text)
print(result)""",

    """def bellman_ford(graph, source):
    dist = {v: float('inf') for v in graph}
    dist[source] = 0
    
    for _ in range(len(graph) - 1):
        for u in graph:
            for v, w in graph[u]:
                if dist[u] != float('inf') and dist[u] + w < dist[v]:
                    dist[v] = dist[u] + w
    
    for u in graph:
        for v, w in graph[u]:
            if dist[u] != float('inf') and dist[u] + w < dist[v]:
                return None
    
    return dist

graph = {
    'A': [('B', 4), ('C', 2)],
    'B': [('C', 3), ('D', 2), ('E', 3)],
    'C': [('B', 1), ('D', 4), ('E', 5)],
    'D': [],
    'E': [('D', -5)]
}
result = bellman_ford(graph, 'A')
print(result)""",

    """def flood_fill(image, sr, sc, new_color):
    rows, cols = len(image), len(image[0])
    original_color = image[sr][sc]
    
    if original_color == new_color:
        return image
    
    def dfs(r, c):
        if r < 0 or r >= rows or c < 0 or c >= cols:
            return
        if image[r][c] != original_color:
            return
        
        image[r][c] = new_color
        dfs(r + 1, c)
        dfs(r - 1, c)
        dfs(r, c + 1)
        dfs(r, c - 1)
    
    dfs(sr, sc)
    return image

image = [[1, 1, 1], [1, 1, 0], [1, 0, 1]]
result = flood_fill(image, 1, 1, 2)
print(result)""",

    """def word_ladder(begin_word, end_word, word_list):
    from collections import deque
    
    word_set = set(word_list)
    if end_word not in word_set:
        return 0
    
    queue = deque([(begin_word, 1)])
    visited = {begin_word}
    
    while queue:
        current_word, steps = queue.popleft()
        
        if current_word == end_word:
            return steps
        
        for i in range(len(current_word)):
            for c in 'abcdefghijklmnopqrstuvwxyz':
                next_word = current_word[:i] + c + current_word[i+1:]
                if next_word in word_set and next_word not in visited:
                    visited.add(next_word)
                    queue.append((next_word, steps + 1))
    
    return 0

begin_word = "hit"
end_word = "cog"
word_list = ["hot", "dot", "dog", "lot", "log", "cog"]
result = word_ladder(begin_word, end_word, word_list)
print(result)""",
]
