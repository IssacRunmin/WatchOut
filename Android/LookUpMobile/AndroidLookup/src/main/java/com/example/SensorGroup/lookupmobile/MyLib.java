package com.example.SensorGroup.lookupmobile;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Arrays;
import java.util.Date;

/**
 * Created by IssacRunmin on 18/5/6.
 */

public abstract class MyLib {
    final protected static double[] butterForMag_b={4.86398750165762e-08,2.91839250099457e-07,7.29598125248643e-07,9.72797500331524e-07,7.29598125248643e-07,2.91839250099457e-07,4.86398750165762e-08}
            ,butterForMag_a={1.0,-5.51453512116617,12.6891130565151,-15.5936352107041,10.7932966704854,-3.98935940423088,0.615123122052628}; //for 100 & 2
    final protected static double[] butterForRawdata_b={8.57655707323102e-6,
            5.14593424393861e-5,0.000128648356098465,0.000171531141464620,
            0.000128648356098465,5.14593424393861e-5,8.57655707323102e-6}
            ,butterForRawdata_a={1.0,-4.78713549885213,9.64951772872191,-10.4690788925439,
            6.44111188100806,-2.12903875003045,0.295172431349155};
    // Sample Rate = 100; CutOff Frequency = 5;
    final protected static double EntropyScale[] = {0.05, 0.1, 0.08, 0.01, 0.008, 0.01, 0.01, 0.01, 0.08};
    final protected static SimpleDateFormat sDateFormat=new SimpleDateFormat("yyyyMMdd-HHmmss-SSS");
    final protected static SimpleDateFormat nowtimeFormat=new SimpleDateFormat("yyyyMMdd-HHmmss");
    final protected static DecimalFormat counterFormat=new DecimalFormat("0000000");
    final protected static DecimalFormat millisecFormat=new DecimalFormat("0000000");
    final protected static DecimalFormat dataFormat=new DecimalFormat("000.0000000000");
    final protected static String TAG="LookUpMobileTag";
    final protected static int EVENT_FLAT = 1, EVENT_UPRAMP = 2, EVENT_DOWNRAMP = 3, EVENT_TURN = 4,
            EVENT_UPCURB = 5, EVENT_DOWNCURB = 6, EVENT_STAND = 7;
    final protected static short STATE_SLIDE = 0,STATE_UPRAMP = 1,STATE_DOWNRAMP = 2,
            STATE_UPCURB = 3, STATE_DOWNCURB = 4, STATE_ROAD = 5;
    final protected static int HMM_Events[] ={EVENT_FLAT, EVENT_UPRAMP, EVENT_DOWNRAMP, EVENT_TURN,
            EVENT_UPCURB, EVENT_DOWNCURB, EVENT_STAND};
    final protected static int HMM_States[] = {STATE_SLIDE, STATE_UPRAMP, STATE_DOWNRAMP,
            STATE_UPCURB, STATE_DOWNCURB, STATE_ROAD};
//    protected static enum EVENT{
//        MISSED, FLAT, UPRAMP, DOWNRAMP, TURN, UPCURB, DOWNCURB, STAND
//    }
//    protected static enum STATE{
//        SLIDE, UPRAMP, DOWNRAMP, UPCURB, DOWNCURB, ROAD
//    }
    protected static String EVENT[] = {"MISSED", "FLAT  ", "UPRAMP", "DOWNRAMP", "TURN  ", "UPCURB  ", "DOWNCURB", "STAND "};
    protected static String STATE[] = {"SIDE", "UPRAMP", "DOWNRAMP", "UPCURB", "DOWNCURB", "ROAD"};
//    final protected static enum Events
    /*protected static long TimeToMillisec(Date date) {
        SimpleDateFormat PureDigitDateFormat=new SimpleDateFormat("yyyyMMddHHmmssSSS");
        long rst=0,init;
        init=Long.parseLong(PureDigitDateFormat.format(date).toString())%1000000000;
        rst+=(init/(long)10000000);
        init%=(long)10000000;
        rst=rst*24+(init/(long)100000);
        init%=(long)100000;
        rst=rst*60+(init/(long)1000);
        init%=(long)1000;
        rst=rst*1000+init;
        return rst;
    }*/
    protected static String GetDate(Date date){
        SimpleDateFormat DateFormat = new SimpleDateFormat("yyyyMMdd");
        return DateFormat.format(date);
    }
    protected static double getButterworth(double[] Rawdata,double[] Butterdata, double[] butter_a,
                                  double[] butter_b, int StartIndex,int MOD) {
        double rst=0;
        Butterdata[StartIndex]=0;
        for(int i=0;i<=6;i++){
            int tmp=(StartIndex-i+MOD)%MOD;
            rst+=butter_b[i]*Rawdata[tmp];
            rst-=butter_a[i]*Butterdata[tmp];
        }
        Butterdata[StartIndex]=rst;
        return rst;
    }
    protected static double prctile(double[] SortedData,int n, double p){
        double r = n * p / 100;
        int k = (int)Math.floor(r + 0.5);
        int kd1 = k - 1;
        r = r - k;
        return (0.5+r) * SortedData[k] + (0.5 - r) * SortedData[kd1];
    }
    protected static double square(double x){return x*x;}
}
