class Calculator:
    def __init__(self):
        self.history = []

    def add(self, a, b):
        result = a + b
        self.history.append(f"ADD: {a} + {b} = {result}")
        return result

    def subtract(self, a, b):
        result = a - b
        self.history.append(f"SUBTRACT: {a} - {b} = {result}")
        return result

    def multiply(self, a, b):
        result = a * b
        self.history.append(f"MULTIPLY: {a} * {b} = {result}")
        return result

    def divide(self, a, b):
        if b == 0:
            self.history.append(f"DIVIDE ERROR: Division by zero attempted ({a} / {b})")
            return "Error: Division by zero"
        result = a / b
        self.history.append(f"DIVIDE: {a} / {b} = {result}")
        return result

    def get_history(self):
        return self.history


if __name__ == "__main__":
    print("=== QA Test: Calculator Implementation ===")
    
    calc = Calculator()
    calc.add(2, 3)
    calc.subtract(10, 4)
    calc.multiply(5, 5)
    calc.divide(8, 2)
    calc.divide(5, 0)  # Caso de prueba de error
    
    print("\nTest History:")
    for entry in calc.get_history():
        print(entry)

    print("=== End of QA Test ===")
