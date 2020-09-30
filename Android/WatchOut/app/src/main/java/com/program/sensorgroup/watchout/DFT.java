package com.program.sensorgroup.watchout;

import android.util.Log;

/**
 * Created by IssacRunmin on 18/5/4.
 */

public class DFT {
    public static boolean debug = false;
    private static String tag = "DFT";
    public static void outComplex(Complex x) {
        Log.d(tag, x.re() + "\t" + x.im() + "\t");
    }

    public static Complex[] dft(Complex[] x, int end) {
        int n = end + 1;//x.length;
        // exp(-2i*n*PI)=cos(-2*n*PI)+i*sin(-2*n*PI)=1
        if (n == 1) return x;

        Complex[] result = new Complex[n];
        for (int i = 0; i < n; i++) {
            result[i] = new Complex(0, 0);
            if (debug)
//                System.out.println("i=" + i + ":");
                Log.d(tag, "i=" + i + ":");
            for (int k = 0; k < n; k++) {
                //使用欧拉公式e^(-i*2pi*k/N) = cos(-2pi*k/N) + i*sin(-2pi*k/N)
                double p = -2.0 * i * k * Math.PI / n;
                Complex m = new Complex(Math.cos(p), Math.sin(p));
                Complex tmp = x[k].times(m);
                result[i] = result[i].plus(tmp);
                if (debug) {
                    Log.d(tag, "\tp=" + p);
                    Log.d(tag, "\tm:\t");
                    outComplex(m);
                    Log.d(tag, "\ttmp:\t");
                    outComplex(tmp);
                    Log.d(tag, "\trst[i]:\t");
                    outComplex(result[i]);
                }
            }
            if (debug) outComplex(result[i]);
        }
        return result;
    }
}