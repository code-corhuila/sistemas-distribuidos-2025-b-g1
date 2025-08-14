from datetime import datetime
import unittest


class Calculator:
    """Calculadora básica con historial de operaciones."""

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


# ------------------ PRUEBAS UNITARIAS ------------------ #
class TestCalculator(unittest.TestCase):

    def setUp(self):
        self.calc = Calculator()

    def test_add(self):
        self.assertEqual(self.calc.add(2, 3), 5)

    def test_subtract(self):
        self.assertEqual(self.calc.subtract(5, 3), 2)

    def test_multiply(self):
        self.assertEqual(self.calc.multiply(4, 3), 12)

    def test_divide(self):
        self.assertEqual(self.calc.divide(10, 2), 5)

    def test_divide_by_zero(self):
        with self.assertRaises(ValueError):
            self.calc.divide(5, 0)

    def test_history(self):
        self.calc.add(1, 1)
        self.assertTrue(len(self.calc.get_history()) > 0)


# ------------------ EJECUCIÓN DIRECTA ------------------ #
if __name__ == "__main__":
    # Modo demostración
    calc = Calculator()
    calc.add(2, 3)
    try:
        calc.divide(8, 0)
    except ValueError as e:
        print("Error controlado:", e)
    calc.divide(8, 2)

    print("\nHistorial:")
    for entry in calc.get_history():
        print(entry)

    # Ejecutar pruebas
    print("\nEjecutando pruebas...")
    unittest.main(argv=[''], verbosity=2, exit=False)
