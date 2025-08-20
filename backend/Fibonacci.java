package prueba;

import javax.swing.JOptionPane;

public class Fibonacci {

    public static void main(String[] args) {
        int n = Integer.parseInt(JOptionPane.showInputDialog("Ingrese la cantidad de términos"));
        fibonnacci(n);
    }

    public static void fibonnacci(int n) {
        String mensaje = "";
        if (n < 0) {
            mensaje = "Argumento invalido";
        } else if (n >= 0) {
            mensaje = "0";
            if (n > 0) {
                mensaje = mensaje + ", 1";
                int a = 0;
                int b = 1;
                int f_n;
                for (int i = 2; i <= n; i++) {
                    f_n = a + b;
                    a = b;
                    b = f_n;
                    mensaje = mensaje + ", " + f_n;
                }
            }
        }
        JOptionPane.showMessageDialog(null, mensaje);
    }
}
