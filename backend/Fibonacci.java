package prueba;

import javax.swing.JOptionPane;

public class Fibonacci {

    public static void main(String[] args) {
        int n = Integer.parseInt(JOptionPane.showInputDialog("Ingrese la cantidad de términos"));
        fibonnacci(n);
    }

    public static void fibonnacci(int n) {
        if (n < 0) {
            System.out.println("Argumento invalido");
        } else if (n >= 0) {
            System.out.println("0");
            if (n > 0) {
                System.out.println("1");
                int a = 0;
                int b = 1;
                int f_n;
                for (int i = 2; i <= n; i++) {
                    f_n = a + b;
                    a = b;
                    b = f_n;
                    System.out.println(f_n);

                }
            }
        }
    }
}
