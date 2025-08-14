def is_palindrome_basic(text):
    return text == text[::-1]

if __name__ == "__main__":
    entrada = input("Introduce una palabra o frase: ")
    print("¿Es palíndromo?", is_palindrome_basic(entrada))

