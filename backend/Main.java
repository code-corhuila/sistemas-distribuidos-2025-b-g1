package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {

    private static final Scanner sc = new Scanner(System.in);
    private static final List<String> historial = new ArrayList<>();

    // Método para leer double con control de errores
    private static double leerDouble(String mensaje) {
        while (true) {
            System.out.print(mensaje);
            if (sc.hasNextDouble()) {
                return sc.nextDouble();
            }
            System.out.println("❌ Entrada inválida. Intente de nuevo.");
            sc.next(); // Limpiar buffer
        }
    }

    // Realiza la operación
    private static void operar() {
        double a = leerDouble("Ingrese primer número: ");
        double b = leerDouble("Ingrese segundo número: ");
        System.out.print("Ingrese operación (+, -, *, /): ");
        char op = sc.next().charAt(0);

        double resultado;
        switch (op) {
            case '+': resultado = a + b; break;
            case '-': resultado = a - b; break;
            case '*': resultado = a * b; break;
            case '/':
                if (b == 0) {
                    System.out.println("❌ Error: división por cero.");
                    return;
                }
                resultado = a / b;
                break;
            default:
                System.out.println("❌ Operación no válida.");
                return;
        }
        String registro = String.format("%.2f %c %.2f = %.2f", a, op, b, resultado);
        historial.add(registro);
        System.out.println("Resultado: " + resultado);
    }

    // Muestra el historial
    private static void mostrarHistorial() {
        if (historial.isEmpty()) {
            System.out.println("📜 Historial vacío.");
        } else {
            System.out.println("📜 Historial de operaciones:");
            historial.forEach(h -> System.out.println(" - " + h));
        }
    }
    public static void main(String[] args) {
        boolean continuar = true;
        while (continuar) {
            System.out.println("\n--- CALCULADORA BÁSICA ---");
            System.out.println("1. Realizar operación");
            System.out.println("2. Ver historial");
            System.out.println("3. Salir");
            System.out.print("Elige una opción: ");

            String opcion = sc.next();
            switch (opcion) {
                case "1": operar(); break;
                case "2": mostrarHistorial(); break;
                case "3": continuar = false; break;
                default: System.out.println("❌ Opción no válida.");
            }
        }
        System.out.println("👋 Calculadora finalizada.");
    }
}