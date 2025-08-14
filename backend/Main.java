package org.example;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class Main {

    private static List<String> historial = new ArrayList<>();

    // Realiza la operación y guarda en el historial
    public static double operar(double a, double b, char operacion) {
        double resultado;
        switch (operacion) {
            case '+':
                resultado = a + b;
                break;
            case '-':
                resultado = a - b;
                break;
            case '*':
                resultado = a * b;
                break;
            case '/':
                if (b == 0) {
                    System.out.println("❌ Error: división por cero.");
                    return Double.NaN;
                }
                resultado = a / b;
                break;
            default:
                System.out.println("❌ Operación no válida.");
                return Double.NaN;
        }
        historial.add(a + " " + operacion + " " + b + " = " + resultado);
        return resultado;
    }

    // Muestra el historial
    public static void mostrarHistorial() {
        if (historial.isEmpty()) {
            System.out.println("📜 Historial vacío.");
        } else {
            System.out.println("📜 Historial de operaciones:");
            for (String h : historial) {
                System.out.println(" - " + h);
            }
        }
    }
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        boolean continuar = true;

        while (continuar) {
            System.out.println("\n--- CALCULADORA BÁSICA ---");
            System.out.println("1. Realizar operación");
            System.out.println("2. Ver historial");
            System.out.println("3. Salir");
            System.out.print("Elige una opción: ");

            int opcion = sc.nextInt();

            switch (opcion) {
                case 1:
                    System.out.print("Ingrese primer número: ");
                    double num1 = sc.nextDouble();
                    System.out.print("Ingrese segundo número: ");
                    double num2 = sc.nextDouble();
                    System.out.print("Ingrese operación (+, -, *, /): ");
                    char op = sc.next().charAt(0);

                    double resultado = operar(num1, num2, op);
                    if (!Double.isNaN(resultado)) {
                        System.out.println("Resultado: " + resultado);
                    }
                    break;
                case 2:
                    mostrarHistorial();
                    break;
                case 3:
                    continuar = false;
                    break;
                default:
                    System.out.println("❌ Opción no válida.");
            }
        }
        sc.close();
        System.out.println("👋 Calculadora finalizada.");
    }
}