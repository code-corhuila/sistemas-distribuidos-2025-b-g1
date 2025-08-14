historial = []

def calcular(op, a, b):
    if op == "+":
        resultado = a + b
    elif op == "-":
        resultado = a - b
    elif op == "*":
        resultado = a * b
    elif op == "/":
        resultado = a / b
    else:
        print("Operación no válida.")
        return None
    
    historial.append(f"{a} {op} {b} = {resultado}")
    return resultado


while True:
        print("\nOpciones: +  -  *  /  |  h (historial)  |  q (salir)")
        op = input("Operación: ")
        
        if op == "q":
            print("¡Hasta luego!")
            break
        elif op == "h":
            print("Historial:")
            for h in historial:
                print(h)
        elif op in ["+", "-", "*", "/"]:
            try:
                a = float(input("Primer número: "))
                b = float(input("Segundo número: "))
                print("Resultado:", calcular(op, a, b))
            except ValueError:
                print("Entrada inválida. Usa números.")
        else:
            print("Opción no válida.")
