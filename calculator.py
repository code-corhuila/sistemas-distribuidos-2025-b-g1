class Calculator:
    def __init__(self):
        self.history = []

    def add(self, a, b):
        result = a + b
        self.history.append(f"{a} + {b} = {result}")
        return result

    def subtract(self, a, b):
        result = a - b
        self.history.append(f"{a} - {b} = {result}")
        return result

    def multiply(self, a, b):
        result = a * b
        self.history.append(f"{a} * {b} = {result}")
        return result

    def divide(self, a, b):
        result = a / b
        self.history.append(f"{a} / {b} = {result}")
        return result

    def get_history(self):
        return self.history


if __name__ == "__main__":
    calc = Calculator()
    calc.add(2, 3)
    calc.subtract(10, 4)
    calc.multiply(5, 5)
    calc.divide(8, 2)

    print("Historial:")
    for entry in calc.get_history():
        print(entry)
