def is_palindrome_optimized(text):
    # Elimina espacios y convierte todo a minúsculas
    clean_text = ''.join(text.split()).lower()
    return clean_text == clean_text[::-1]

if __name__ == "__main__":
    entrada = input("Introduce una palabra o frase: ")
    print("¿Es palíndromo?", is_palindrome_optimized(entrada))
