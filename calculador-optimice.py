# calculadora_historial.py
# Calculadora básica con historial y pruebas

# ======= LÓGICA DE LA CALCULADORA =======
class Calculadora:
    def __init__(self):
        self.historial = []

    def registrar_operacion(self, operacion, resultado):
        self.historial.append(f"{operacion} = {resultado}")

    def sumar(self, a, b):
        resultado = a + b
        self.registrar_operacion(f"{a} + {b}", resultado)
        return resultado

    def restar(self, a, b):
        resultado = a - b
        self.registrar_operacion(f"{a} - {b}", resultado)
        return resultado

    def multiplicar(self, a, b):
        resultado = a * b
        self.registrar_operacion(f"{a} * {b}", resultado)
        return resultado

    def dividir(self, a, b):
        if b == 0:
            raise ValueError("No se puede dividir entre cero.")
        resultado = a / b
        self.registrar_operacion(f"{a} / {b}", resultado)
        return resultado

    def mostrar_historial(self):
        return "\n".join(self.historial) if self.historial else "Historial vacío."


# ======= MENÚ INTERACTIVO =======
def menu():
    calc = Calculadora()

    while True:
        print("\n--- Calculadora con Historial ---")
        print("1. Sumar")
        print("2. Restar")
        print("3. Multiplicar")
        print("4. Dividir")
        print("5. Ver historial")
        print("6. Salir")

        opcion = input("Selecciona una opción: ")

        if opcion in ["1", "2", "3", "4"]:
            try:
                num1 = float(input("Ingrese el primer número: "))
                num2 = float(input("Ingrese el segundo número: "))

                if opcion == "1":
                    print("Resultado:", calc.sumar(num1, num2))
                elif opcion == "2":
                    print("Resultado:", calc.restar(num1, num2))
                elif opcion == "3":
                    print("Resultado:", calc.multiplicar(num1, num2))
                elif opcion == "4":
                    print("Resultado:", calc.dividir(num1, num2))

            except ValueError as e:
                print("Error:", e)

        elif opcion == "5":
            print("\n--- Historial de operaciones ---")
            print(calc.mostrar_historial())

        elif opcion == "6":
            print("Saliendo de la calculadora...")
            break
        else:
            print("Opción no válida. Intente nuevamente.")


# ======= PRUEBAS AUTOMÁTICAS =======
def pruebas():
    calc = Calculadora()

    assert calc.sumar(2, 3) == 5
    assert calc.restar(5, 3) == 2
    assert calc.multiplicar(4, 3) == 12
    assert calc.dividir(10, 2) == 5

    try:
        calc.dividir(5, 0)
    except ValueError as e:
        assert str(e) == "No se puede dividir entre cero."

    print("✅ Todas las pruebas pasaron correctamente.")


if __name__ == "__main__":
    # Ejecutar pruebas
    pruebas()

    # Iniciar menú
    menu()
