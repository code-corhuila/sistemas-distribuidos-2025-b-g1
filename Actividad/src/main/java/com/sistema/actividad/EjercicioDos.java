package com.sistema.actividad;

import java.util.Arrays;

public class EjercicioDos {public int[] ordenarMerge(int[] arr) {
    if (arr == null) return null;
    int[] a = Arrays.copyOf(arr, arr.length);
    if (a.length <= 1) return a;
    int[] tmp = new int[a.length];
    mergeSort(a, 0, a.length - 1, tmp);
    return a;
}

    private void mergeSort(int[] a, int l, int r, int[] tmp) {
        if (l >= r) return;
        int m = (l + r) >>> 1;
        mergeSort(a, l, m, tmp);
        mergeSort(a, m + 1, r, tmp);
        int i = l, j = m + 1, k = l;
        while (i <= m && j <= r) tmp[k++] = (a[i] <= a[j]) ? a[i++] : a[j++];
        while (i <= m) tmp[k++] = a[i++];
        while (j <= r) tmp[k++] = a[j++];
        System.arraycopy(tmp, l, a, l, r - l + 1);
    }

    public void ordenarQuickInPlace(int[] a) {
        if (a == null || a.length <= 1) return;
        quickSort(a, 0, a.length - 1);
    }

    private void quickSort(int[] a, int l, int r) {
        int i = l, j = r;
        int pivote = a[(l + r) >>> 1];
        while (i <= j) {
            while (a[i] < pivote) i++;
            while (a[j] > pivote) j--;
            if (i <= j) {
                int t = a[i]; a[i] = a[j]; a[j] = t;
                i++; j--;
            }
        }
        if (l < j) quickSort(a, l, j);
        if (i < r) quickSort(a, i, r);
    }

    public int busquedaLineal(int[] arr, int objetivo) {
        if (arr == null) return -1;
        for (int i = 0; i < arr.length; i++) {
            if (arr[i] == objetivo) return i;
        }
        return -1;
    }

    public int busquedaBinaria(int[] ordenadoAsc, int objetivo) {
        if (ordenadoAsc == null || ordenadoAsc.length == 0) return -1;
        int l = 0, r = ordenadoAsc.length - 1;
        while (l <= r) {
            int m = (l + r) >>> 1;
            if (ordenadoAsc[m] == objetivo) return m;
            if (ordenadoAsc[m] < objetivo) l = m + 1; else r = m - 1;
        }
        return -1;
    }

    public static void main(String[] args) {
        EjercicioDos e = new EjercicioDos();

        int[] datos = { 7, 3, 9, 1, 5, 8, 2 };

        int[] ordenadoMerge = e.ordenarMerge(datos);
        System.out.println("Original: " + Arrays.toString(datos));
        System.out.println("Ordenado (Merge): " + Arrays.toString(ordenadoMerge));

        e.ordenarQuickInPlace(datos);
        System.out.println("Ordenado (Quick in-place): " + Arrays.toString(datos));

        int posLineal = e.busquedaLineal(new int[]{10, 50, 20}, 20);
        System.out.println("Búsqueda lineal de 20: index=" + posLineal);

        int posBinaria = e.busquedaBinaria(ordenadoMerge, 8);
        System.out.println("Búsqueda binaria de 8 en Merge: index=" + posBinaria);
    }
}

