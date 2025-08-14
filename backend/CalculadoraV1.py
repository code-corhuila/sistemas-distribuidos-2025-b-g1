# Versión: develop
# Calculadora básica sin validaciones ni historial

def calcular(op, a, b):
    if op == "1":
        return a + b
    elif op == "2":
        return a - b
    elif op == "3":
        return a * b
    elif op == "4":
        return a / b

print("Resultado:", calcular("1", 4, 2))  # Ejemplo simple
