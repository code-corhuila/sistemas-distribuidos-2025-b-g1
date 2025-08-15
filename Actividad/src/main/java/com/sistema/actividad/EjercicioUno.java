package com.sistema.actividad;

import java.util.ArrayDeque;
import java.util.Deque;

public class EjercicioUno {
    private final Deque<String> historial = new ArrayDeque<>();
    private final int maxHistorial;

    public EjercicioUno() {
        this(20);
    }

    public EjercicioUno(int maxHistorial) {
        this.maxHistorial = Math.max(1, maxHistorial);
    }

    public double sumar(double a, double b) {
        return registrarOperacion(a + b, a + " + " + b);
    }

    public double restar(double a, double b) {
        return registrarOperacion(a - b, a + " - " + b);
    }

    public double multiplicar(double a, double b) {
        return registrarOperacion(a * b, a + " * " + b);
    }

    public double dividir(double a, double b) {
        if (b == 0) {
            throw new ArithmeticException("No se puede dividir entre cero");
        }
        return registrarOperacion(a / b, a + " / " + b);
    }

    private double registrarOperacion(double resultado, String expresion) {
        String linea = expresion + " = " + resultado;
        historial.addFirst(linea);
        while (historial.size() > maxHistorial) {
            historial.removeLast();
        }
        return resultado;
    }

    public Deque<String> obtenerHistorial() {
        return new ArrayDeque<>(historial);
    }

    public void limpiarHistorial() {
        historial.clear();
    }

    public static void main(String[] args) {
        EjercicioUno calc = new EjercicioUno();
        calc.sumar(5, 3);
        calc.restar(10, 4);
        calc.multiplicar(6, 7);
        calc.dividir(20, 5);

        System.out.println("Historial:");
        calc.obtenerHistorial().forEach(System.out::println);
    }
}


