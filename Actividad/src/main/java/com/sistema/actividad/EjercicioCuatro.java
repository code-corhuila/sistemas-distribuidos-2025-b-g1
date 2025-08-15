package com.sistema.actividad;

public class EjercicioCuatro {
    public long fibonacciIterativo(int n) {
        if (n < 0) throw new IllegalArgumentException("n debe ser >= 0");
        if (n < 2) return n;
        long a = 0, b = 1;
        for (int i = 2; i <= n; i++) {
            long c = a + b;
            a = b;
            b = c;
        }
        return b;
    }

    public long fibonacciRapido(int n) {
        if (n < 0) throw new IllegalArgumentException("n debe ser >= 0");
        return fibPar(n)[0];
    }

    private long[] fibPar(int n) {
        if (n == 0) return new long[]{0, 1};
        long[] par = fibPar(n >> 1);
        long a = par[0];
        long b = par[1];
        long c = a * (2 * b - a);
        long d = a * a + b * b;
        if ((n & 1) == 0) {
            return new long[]{c, d};
        } else {
            return new long[]{d, c + d};
        }
    }

    public static void main(String[] args) {
        EjercicioCuatro e = new EjercicioCuatro();

        System.out.println("Iterativo F(10) = " + e.fibonacciIterativo(10));
        System.out.println("Rápido F(10) = " + e.fibonacciRapido(10));

        System.out.println("Iterativo F(50) = " + e.fibonacciIterativo(50));
        System.out.println("Rápido F(50) = " + e.fibonacciRapido(50));
    }
}

