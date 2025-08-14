public class Fibonacci {

    public static long fibonacci(int n) {
        if (n <= 1) return n;
        return fibonacci(n - 1) + fibonacci(n - 2);
    }

    public static void main(String[] args) {
        int n = 30; // Cambia este valor según el término que quieras calcular
        System.out.println("Fibonacci de " + n + " es: " + fibonacci(n));
    }
}