# fibonacci.py
def fibonacci_optimizado(n, memo={}):
    if n in memo:
        return memo[n]
    if n <= 1:
        return n
    memo[n] = fibonacci_optimizado(n-1, memo) + fibonacci_optimizado(n-2, memo)
    return memo[n]

# Ejemplo de uso
print(fibonacci_optimizado(50))