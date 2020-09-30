package com.program.sensorgroup.watchout;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

public abstract class MyLib {
    public static double square(double x){return x*x;}
    public final static String MY_UUID="00001101-0000-1000-8000-00805F9B34FB";
    public static final int FilterOrder=6,FilterOrder_Yaw=6;
    /*public final static double[] butterForMag_b={1.77652970787395e-05,0.000106591782472437,
            0.000266479456181093,0.000355305941574791,0.000266479456181093,
            0.000106591782472437,1.77652970787395e-05},butterForMag_a={1.0,
            -4.61419152834418,8.99893671280900,-9.47448890999945,5.67070791282720,
            -1.82722379445438,0.247396586174848};//butter(6,4/(70/2) from matlab
    public final static double[] butterForRawdata_b={1.32478523001689e-06,7.94871138010134e-06,
            1.98717784502533e-05,2.64957046003378e-05,1.98717784502533e-05,
            7.94871138010134e-06,1.32478523001689e-06},butterForRawdata_a={1.0,
            -5.13333904400221,11.0343018349970,-12.7073128118594,8.26593256355422,
            -2.87873073664690,0.419232980212101};//butter(6,2.5/(70/2) from matlab

    public final static double[] butterForYaw_b={1.96278548969531e-11,1.96278548969531e-10,
            8.83253470362888e-10,2.35534258763437e-09,4.12184952836014e-09,4.94621943403217e-09,
            4.12184952836014e-09,2.35534258763437e-09,8.83253470362888e-10,1.96278548969531e-10,
            1.96278548969531e-11},butterForYaw_a={1.0,-8.85253269233730,
            35.3247776257695,-83.6666814247272,130.249179555912,-139.250704540592,
            103.536219552233,-52.8621700194845,17.7362742463419,-3.53112726343529,
            0.316764980419185};//butter(10,2/(70/2) from matlab
    public final static double[] butterForYaw_b={3.75516964828959e-07,2.25310178897376e-06,
            5.63275447243439e-06,7.51033929657918e-06, 5.63275447243439e-06,
            2.25310178897376e-06,3.75516964828959e-07},butterForYaw_a={1.0,-5.30657072291190,
            11.7691999493702,-13.9610004084936,9.34042492149550,
            -3.34120683988422,0.499177133509829};//butter(6,2/(70/2)) from matlab
     //*/
    public final static SimpleDateFormat sDateFormat=new SimpleDateFormat("yyyyMMdd-HHmmss-SSS");
    public final static SimpleDateFormat nowtimeFormat=new SimpleDateFormat("yyyyMMdd-HHmmss");
    public final static SimpleDateFormat PureDigitDateFormat = new SimpleDateFormat("yyyyMMddHHmmssSSS");
    public final static DecimalFormat counterFormat=new DecimalFormat("0000000");
    public final static DecimalFormat millisecFormat=new DecimalFormat("0000000");
    public final static DecimalFormat dataFormat=new DecimalFormat("000.0000000000000");
    protected static String GetDate(Date date){
        SimpleDateFormat DateFormat = new SimpleDateFormat("yyyyMMdd");
        return DateFormat.format(date);
    }
    // Sample Rate = 100; CutOff Frequency = 5;
    final protected static double EntropyScale[] = {0.05, 0.1, 0.08, 0.01, 0.008, 0.01, 0.01, 0.01, 0.08};
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

    protected static class Butter{
        // Cutoff Frequency: 2Hz Seg; 5Hz for Process
        //

        // butter(6,2/(fs/2)) fs = 5/20/50/100/200 Hz
        final static double[][] WatchOut_SegA =
                {{1, 3.57943479833119, 5.65866716593362, 4.96541522877857, 2.52949490584145, 0.705274114509900, 0.0837564796186789},    // 5Hz
                 {1, -3.57943479833119, 5.65866716593363, -4.96541522877858, 2.52949490584145, -0.705274114509902, 0.0837564796186792}, // 20Hz
                 {1, -5.02943835142161, 10.6070421837797, -11.9993158162167, 7.67547454820020, -2.63105512847395, 0.377452386374088},   // 50Hz
                 {1, -5.51453512116617, 12.6891130565151, -15.5936352107041, 10.7932966704854, -3.98935940423088, 0.615123122052628},   // 100Hz
                 {1, -5.75724418624657, 13.8155108060580, -17.6873761798940, 12.7416173292292, -4.89692489143373, 0.784417176889301}};  // 200Hz
        final static double[][] WatchOut_SegB =
                {{0.289406917078335, 1.73644150247001, 4.34110375617502, 5.78813834156669, 4.34110375617502, 1.73644150247001, 0.289406917078335},
                 {0.000340537652720116, 0.00204322591632070, 0.00510806479080174, 0.00681075305440232, 0.00510806479080174, 0.00204322591632070, 0.000340537652720116},
                 {2.49722252688989e-06, 1.49833351613393e-05, 3.74583379033483e-05, 4.99444505377977e-05, 3.74583379033483e-05, 1.49833351613393e-05, 2.49722252688989e-06},
                 {4.86398750165762e-08, 2.91839250099457e-07, 7.29598125248643e-07, 9.72797500331524e-07, 7.29598125248643e-07, 2.91839250099457e-07, 4.86398750165762e-08},
                 {8.53159515257218e-10, 5.11895709154331e-09, 1.27973927288583e-08, 1.70631903051444e-08, 1.27973927288583e-08, 5.11895709154331e-09, 8.53159515257218e-10}};
        // butter(6,5/(fs/2)) fs = 5/20/50/100/200 Hz
        final static double[][] WatchOut_ProcessA =
                {{0,0,0,0,0,0,0}, // 5Hz, no butterworth
                 {1, 4.77048955893622e-16, 0.777695961855672, 5.30642408176822e-16, 0.114199425062433, 5.11020413059698e-17, 0.00175092595618278},  // 20Hz
                 {1, -3.57943479833119, 5.65866716593363, -4.96541522877858, 2.52949490584145, -0.705274114509902, 0.0837564796186792},             // 50Hz
                 {1, -4.78713549885213, 9.64951772872191, -10.4690788925439, 6.44111188100806, -2.12903875003045, 0.295172431349155},               // 100Hz
                 {1, -5.39321248486136, 12.1474251704169, -14.6237875666076, 9.92304857077041, -3.59806353388664, 0.544601067560120}};              // 200Hz
        final static double[][] WatchOut_ProcessB =
                {{0,0,0,0,0,0,0},
                 {0.0295882236386608, 0.177529341831965, 0.443823354579911, 0.591764472773215, 0.443823354579911, 0.177529341831965, 0.0295882236386608},               // 20Hz
                 {0.000340537652720116, 0.00204322591632070, 0.00510806479080174, 0.00681075305440232, 0.00510806479080174, 0.00204322591632070, 0.000340537652720116}, // 50Hz
                 {8.57655707323102e-06, 5.14593424393861e-05, 0.000128648356098465, 0.000171531141464620, 0.000128648356098465, 5.14593424393861e-05, 8.57655707323102e-06},// 100Hz
                 {1.75365497206981e-07, 1.05219298324188e-06, 2.63048245810471e-06, 3.50730994413961e-06, 2.63048245810471e-06, 1.05219298324188e-06, 1.75365497206981e-07}};//200Hz
        //  butter(6,4/(fs/2)) fs = 50Hz , 70 Hz
        final static double[][] LookUp_MagA =
                {{1, -4.06164399921344, 7.09950381875071, -6.78501602539751, 3.72301942889161, -1.10867085534354, 0.139660041747140},   // 50Hz
                 {1, -4.61419152834418, 8.99893671280900, -9.47448890999945, 5.67070791282720, -1.82722379445438, 0.247396586174848}};  // 70Hz
        final static double[][] LookUp_MagB =
                {{0.000107068897421389, 0.000642413384528334, 0.00160603346132084, 0.00214137794842778, 0.00160603346132084, 0.000642413384528334, 0.000107068897421389},
                 {1.77652970787395e-05, 0.000106591782472437, 0.000266479456181093, 0.000355305941574791, 0.000266479456181093, 0.000106591782472437, 1.77652970787395e-05}};
        // butter(6,2/(fs/2)) fs = 50/70 Hz
        final static double[][] LookUp_YawA =
                {{1, -5.02943835142161, 10.6070421837797, -11.9993158162167, 7.67547454820020, -2.63105512847395, 0.377452386374088}, // 50Hz
                 {1.0,-5.30657072291190,11.7691999493702,-13.9610004084936,9.34042492149550, -3.34120683988422,0.499177133509829}};// 70Hz
        final static double[][] LookUp_YawB =
                {{2.49722252688989e-06, 1.49833351613393e-05, 3.74583379033483e-05, 4.99444505377977e-05, 3.74583379033483e-05, 1.49833351613393e-05, 2.49722252688989e-06}, // 50Hz
                 {3.75516964828959e-07, 2.25310178897376e-06, 5.63275447243439e-06, 7.51033929657918e-06, 5.63275447243439e-06, 2.25310178897376e-06, 3.75516964828959e-07}};// 70Hz
        // Watch_Lookup : WatchOut app or LookUp App
        // Process Type : WatchOut - Segmentation & Process; LookUp - Magnitude & Yaw
        // Char
        public static double[] GetButter(char Watch_LookUp, int ProcessType, char A_B, int Hz){
            double[] result;
            if (Watch_LookUp == 'W'){
                if (ProcessType == 1){
                    if (A_B == 'A'){
                        switch (Hz){
                            case 5:     result = WatchOut_SegA[0];break;
                            case 20:    result = WatchOut_SegA[1];break;
                            case 50:    result = WatchOut_SegA[2];break;
                            case 100:   result = WatchOut_SegA[3];break;
                            case 200:   result = WatchOut_SegA[4];break;
                            default:    result = WatchOut_SegA[3];break;
                        }
                    }
                    else{
                        switch (Hz){
                            case 5:     result = WatchOut_SegB[0];break;
                            case 20:    result = WatchOut_SegB[1];break;
                            case 50:    result = WatchOut_SegB[2];break;
                            case 100:   result = WatchOut_SegB[3];break;
                            case 200:   result = WatchOut_SegB[4];break;
                            default:    result = WatchOut_SegB[3];break;
                        }
                    }
                }
                else{// Process
                    if (A_B == 'A'){
                        switch (Hz){
                            case 5:     result = WatchOut_ProcessA[0];break;
                            case 20:    result = WatchOut_ProcessA[1];break;
                            case 50:    result = WatchOut_ProcessA[2];break;
                            case 100:   result = WatchOut_ProcessA[3];break;
                            case 200:   result = WatchOut_ProcessA[4];break;
                            default:    result = WatchOut_ProcessA[3];break;
                        }
                    }
                    else{
                        switch (Hz){
                            case 5:     result = WatchOut_ProcessB[0];break;
                            case 20:    result = WatchOut_ProcessB[1];break;
                            case 50:    result = WatchOut_ProcessB[2];break;
                            case 100:   result = WatchOut_ProcessB[3];break;
                            case 200:   result = WatchOut_ProcessB[4];break;
                            default:    result = WatchOut_ProcessB[3];break;
                        }
                    }
                }
            }
            else{// LookUp
                if (ProcessType == 1){
                    if (A_B == 'A'){
                        switch (Hz){
                            case 50:    result = LookUp_MagA[0];break;
                            case 70:    result = LookUp_MagA[1];break;
                            default:    result = LookUp_MagA[0];break;
                        }
                    }
                    else{
                        switch (Hz){
                            case 50:    result = LookUp_MagB[0];break;
                            case 70:    result = LookUp_MagB[1];break;
                            default:    result = LookUp_MagB[0];break;
                        }
                    }
                }
                else{
                    if (A_B == 'A'){
                        switch (Hz){
                            case 50:    result = LookUp_YawA[0];break;
                            case 70:    result = LookUp_YawA[1];break;
                            default:    result = LookUp_YawA[0];break;
                        }
                    }
                    else{
                        switch (Hz){
                            case 50:    result = LookUp_YawB[0];break;
                            case 70:    result = LookUp_YawB[1];break;
                            default:    result = LookUp_YawB[0];break;
                        }
                    }
                }

            }
            return result;
        }
    }
}
