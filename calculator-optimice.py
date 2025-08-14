from datetime import datetime

class Calculator:
    def __init__(self):
        self.history = []

    def _save_history(self, operation, a, b, result):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self.history.append(f"[{timestamp}] {operation}: {a} y {b} = {result}")

    def add(self, a, b):
        result = a + b
        self._save_history("Suma", a, b, result)
        return result

    def subtract(self, a, b):
        result = a - b
        self._save_history("Resta", a, b, result)
        return result

    def multiply(self, a, b):
        result = a * b
        self._save_history("Multiplicación", a, b, result)
        return result

    def divide(self, a, b):
        if b == 0:
            raise ValueError("No se puede dividir entre cero")
        result = a / b
        self._save_history("División", a, b, result)
        return result

    def get_history(self):
        return self.history


if __name__ == "__main__":
    calc = Calculator()
    calc.add(2, 3)
    try:
        calc.divide(8, 0)
    except ValueError as e:
        print("Error controlado:", e)
    calc.divide(8, 2)

    print("Historial:")
    for entry in calc.get_history():
        print(entry)
