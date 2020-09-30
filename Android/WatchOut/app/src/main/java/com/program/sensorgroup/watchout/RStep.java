package com.program.sensorgroup.watchout;

import android.os.Handler;
import android.util.Log;

import java.io.OutputStream;

public class RStep extends Thread {
    static final String tag = "MyTag2";

    static final int SavedStepNum=6;
    static double[]StanceYaw=new double[SavedStepNum+1];
    static double[]maxAccMag=new double[SavedStepNum+1];
    static double[]StancePitch=new double[SavedStepNum+1];
    static int StepLength,StanceLength,index=0;
    static long long_deltaTime;
    static private double RampThr=5* Math.PI/180,TurnThr=60,MagThr=17;
    static int[] WalkingState=new int[SavedStepNum+1];
    static boolean Circle = false;
    static boolean Warning = false;
    private OutputStream output;
    double pitchStatic;
    {
        //1: Flat
        //2: UpRamp
        //3: DownRamp
        //4: Turn
        //5: Curb
    }
    public RStep(double StancePitch, double StanceYaw, double maxAccMag,
                 int StanceStartIndex, int StanceEndIndex,
                 int StepStartIndex, int StepEndIndex, int MOD,
                 Handler mHandler, OutputStream output, long long_deltaTime,double StancePitchIn){
        index=(index+1)%SavedStepNum;
        if (index == 0) Circle = true;
        RStep.StancePitch[index]=StancePitch;
        RStep.StanceYaw[index]=StanceYaw;
        RStep.maxAccMag[index]=maxAccMag;
        RStep.StanceLength=(StanceEndIndex-StanceStartIndex+MOD)%MOD;
        RStep.StepLength=(StepEndIndex-StepStartIndex+MOD)%MOD;
        pitchStatic = StancePitchIn;
        this.output=output;
        RStep.long_deltaTime=long_deltaTime;
        this.start();
    }
    public void run(){
        try {
            WalkingState[index]=1;
            int index_1=(index-1+SavedStepNum)%SavedStepNum;
            int index_3=(index-3+SavedStepNum)%SavedStepNum;
            if((Circle || index > 4) &&
                    Math.abs(StanceYaw[index]-StanceYaw[index_3])>TurnThr)WalkingState[index]=4;
            else if(StancePitch[index]-pitchStatic>RampThr)WalkingState[index]=2;
            else if(StancePitch[index]-pitchStatic<-RampThr)WalkingState[index]=3;
            else if(maxAccMag[index]>MagThr)WalkingState[index]=5;
            String s=MyLib.millisecFormat.format(long_deltaTime)+
                    "\t"+StancePitch[index]+
                    "\t"+StanceYaw[index]+
                    "\t"+maxAccMag[index]+
                    "\t"+StanceLength+
                    "\t"+StepLength+"\t"+WalkingState[index]+"\r\n";
            output.write(s.getBytes());
//            WatchOutService.AddStepBy1();
            if (WalkingState[index] == 3 || WalkingState[index] == 5)
                Warning = true;

        } catch (Exception e)
        { Log.d(tag, "File2 write error."); }

    }
    public static void ResetWarn(){
        Warning = false;
    }
    public static boolean IsWarning(){
        return Warning;
    }
}
