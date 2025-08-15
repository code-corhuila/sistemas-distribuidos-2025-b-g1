package com.sistema.actividad;

import java.text.Normalizer;

public class EjercicioTres { public boolean esPalindromoBasico(String texto) {
    if (texto == null) return false;
    return new StringBuilder(texto).reverse().toString().equals(texto);
}

    public boolean esPalindromoMejorado(String texto) {
        if (texto == null || texto.isBlank()) return false;
        String normalizado = normalizar(texto);
        if (normalizado.isEmpty()) return false;

        int i = 0, j = normalizado.length() - 1;
        while (i < j) {
            if (normalizado.charAt(i) != normalizado.charAt(j)) {
                return false;
            }
            i++;
            j--;
        }
        return true;
    }

    private String normalizar(String texto) {
        String lower = texto.toLowerCase();
        String sinAcentos = Normalizer.normalize(lower, Normalizer.Form.NFD)
                .replaceAll("\\p{M}+", "");
        return sinAcentos.replaceAll("[^a-z0-9]", "");
    }

    public static void main(String[] args) {
        EjercicioTres e = new EjercicioTres();

        System.out.println("Basico 'ana': " + e.esPalindromoBasico("ana"));
        System.out.println("Basico 'hola': " + e.esPalindromoBasico("hola"));

        System.out.println("Mejorado 'Ánita lava la tina': " +
                e.esPalindromoMejorado("Ánita lava la tina"));

        System.out.println("Mejorado 'No 'x' in Nixon': " +
                e.esPalindromoMejorado("No 'x' in Nixon"));

        System.out.println("Mejorado 'Hola mundo': " +
                e.esPalindromoMejorado("Hola mundo"));
    }
}

