# Calculadora básica - HU-1
# Versión inicial: solo suma y resta

historial = []

def sumar(a, b):
    resultado = a + b
    historial.append(f"{a} + {b} = {resultado}")
    return resultado

def restar(a, b):
    resultado = a - b
    historial.append(f"{a} - {b} = {resultado}")
    return resultado

# Ejemplo de uso
print("Suma:", sumar(5, 3))
print("Resta:", restar(10, 4))

print("\nHistorial de operaciones:")
for operacion in historial:
    print(operacion)
