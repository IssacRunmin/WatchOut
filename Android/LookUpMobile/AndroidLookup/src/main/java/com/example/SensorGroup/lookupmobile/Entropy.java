package com.example.SensorGroup.lookupmobile;

/**
 * Created by ztgni on 2018/3/19.
 */

public class Entropy {

    public static double getEntropy(double[] Data,int length,double scale){
        int i,j;
        int[] Pdata=new int[length+1];
        int[] forpro = new int[length+1];

        for(i=0;i<length;i++)Pdata[i] = (int)Math.round(Data[i]/scale);
        forpro[0] = 1;
        j=0;
        for(i=1;i<length;i++){
            if(Pdata[i]==Pdata[i-1])forpro[j]++;
            else{
                j++;
                forpro[j] = 1;
            }
        }
        double entropy=0.0;
        for(i=0;i<j+1;i++)entropy += (forpro[i]/(double)length)*Math.log(forpro[i]/(double)length);
        return -entropy;
    }
}
