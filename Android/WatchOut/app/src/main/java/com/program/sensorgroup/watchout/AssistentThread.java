package com.program.sensorgroup.watchout;


import android.bluetooth.BluetoothSocket;
import android.os.Environment;
import android.os.Handler;
import android.util.Log;
import android.view.View;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Date;


/**
 * Created by IssacRunmin on 18/7/9.
 */

public class AssistentThread extends Thread {
    private int IndexID;
    private InputStream BTinput;
    private OutputStream BToutput;

    final int SavedPointNum=500,freq=70;
    final static double PI=Math.PI;
    final static double neg_thr=-30* Math.PI/180,
            std_thr=0.09, var_thr=std_thr*std_thr,
            mean_thr= Math.PI/6;
    private double PitchStatic=-20* Math.PI/180,NowPitch=-20* Math.PI/180;
    // There is a pitch effect(negative pitch) on shoes when equipped, adjust PitchStatic to cancel this effect.
    final static double YawButterErrCorrection=1;
    private static Long desiredSeconds = 2L;
    private Date fileCreateTime, now;
    private String filename,filenameForStep,filenameForTruth;
    private String fileSaveNotice, fileCreateNotice, DeviceName;

    private OutputStream output,outputForStep;
    private long counter,counterForMag,counterInStep;
    Long long_lastTime, long_fileCreateTime,
            long_nowTime, long_nowTime2, long_deltaTime;
    private double[][]RawData=new double[6][SavedPointNum+1];
    //double[][]ButterData=new double[6][SavedPointNum+1];
    private double[]RawAccMagnitude=new double[SavedPointNum+1];//sqrt(acc_y^2+acc_z^2)
    private double[]ButterAccMagnitude=new double[SavedPointNum+1];
    private double[]alpha=new double[SavedPointNum+1];//for calc pitch
    private double[]beta=new double[SavedPointNum+1];//for calc pitch
    private double[]v=new double[SavedPointNum+1];//for calc pitch
    private double[]w=new double[SavedPointNum+1];//for calc pitch
    private double[]pitch=new double[SavedPointNum+1];
    private double[]yaw=new double[SavedPointNum+1];
    private double[]ButterYaw=new double[SavedPointNum+1];
    private final String tag="ServiceThread";
    private int len=MyLib.FilterOrder+1,mode,StepStartIndex;
    private int StanceStartIndex,StanceEndIndex;
    private int state;
    {   //state://0:dustbin
        //1:neg peak
        //2:after neg peak
        //3:stance phase
        //4:waiting for neg peak
    }
    private double StancePitch,StanceYaw,maxButterAccMag;
    private double exp_pitch,exp_pitch2,var_pitch,exp_yaw;
    private int m,m_1,state_len;//mean&variance pitch of last m points
    private final double[]minlen_seconds=new double[]{0,0,0.1,0.2,0.1};
    private final double[]maxlen_seconds=new double[]{10000,1.0,1.0,1.0,1.0};
    private final long[]minlen_points=new long[5];
    private final long[]maxlen_points=new long[5];
    private static boolean writeornot = true;
    private double[] ButterMagA = MyLib.Butter.GetButter('L',1,'A',70),
            ButterMagB = MyLib.Butter.GetButter('L',1,'B',70),
            ButterYawA = MyLib.Butter.GetButter('L',2,'A',70),
            ButterYawB = MyLib.Butter.GetButter('L',2,'B',70);
    BluetoothSocket Socket;

    static double getButterworth(double[] Rawdata,double[] Butterdata, double[] butter_a,
                                 double[] butter_b, int StartIndex,int order,int MOD) {
        double rst=0;
        Butterdata[StartIndex]=0;
        for(int i=0;i<=order;i++){
            int tmp=(StartIndex-i+MOD)%MOD;
            rst-=butter_a[i]*Butterdata[tmp];
            rst+=butter_b[i]*Rawdata[tmp];
        }
        Butterdata[StartIndex]=rst;
        return rst;
    }
    static double UpdateExp(double OldExp1,double OldExp2,long num1,long num2){
        return (num1*OldExp1+num2*OldExp2)/(num1+num2);
    }
    void updateFSM(double pitchvalue,double pitchmean,double pitchvar,double yawmean){
        state_len++;
        if(ButterAccMagnitude[len]>maxButterAccMag)
            maxButterAccMag=ButterAccMagnitude[len];
        if(state_len>maxlen_points[state]){
            state=0;
            return;
        }
        if(0==state){
            if(pitchvalue<PitchStatic+neg_thr){
                state=1;
                StepStartIndex=len;
                state_len=0;
            }
        }
        else if(1==state){
            if(pitchvalue>PitchStatic+neg_thr) {
                if (state_len < minlen_points[state]) state = 0;
                else state = 2;
                state_len=0;
            }
        }
        else if(2==state){
            if(pitchvar<var_thr&& Math.abs(pitchmean-PitchStatic)<mean_thr) {
                if (state_len < minlen_points[state]) state = 0;
                else {
                    state = 3;
                    StanceStartIndex=len;
                    StancePitch=pitchmean;
                    StanceYaw=yawmean;
                }
                state_len=0;
            }
        }
        else if(3==state){
            if(pitchvar>var_thr&&state_len >= minlen_points[state]){
                state = 4;
                StanceEndIndex=len;
                state_len=0;
            }else{
                StancePitch=UpdateExp(StancePitch,pitch[len],m+state_len-1,1);
                StanceYaw=UpdateExp(StanceYaw,ButterYaw[len],m+state_len-1,1);
            }
        }
        else if(4==state){
            if(pitchvalue<PitchStatic+neg_thr) {
                if (state_len < minlen_points[state]) state = 0;
                else {
                    if (IndexID == 0) {
                        LStep ALStep = new LStep(StancePitch, StanceYaw * YawButterErrCorrection,
                                maxButterAccMag, StanceStartIndex, StanceEndIndex,
                                StepStartIndex, len, SavedPointNum,
                                null, outputForStep, long_deltaTime, StancePitch);
                    }
                    else{
                        RStep ALStep = new RStep(StancePitch, StanceYaw * YawButterErrCorrection,
                                maxButterAccMag, StanceStartIndex, StanceEndIndex,
                                StepStartIndex, len, SavedPointNum,
                                null, outputForStep, long_deltaTime, StancePitch);
                    }
                    initStep();
                    state = 1;
                }
                state_len=0;
                StepStartIndex=len;
            }
        }
    }
    void initStep(){
        StepStartIndex=-1;
        StancePitch=0;
        StanceYaw=0;
        counterInStep=0;
        maxButterAccMag=-1.0;
    }
    void initThrs(){
        for(int i=0;i<=4;i++){
            minlen_points[i]=(int)(freq*minlen_seconds[i]);
            maxlen_points[i]=(int)(freq*maxlen_seconds[i]);
        }
        m=(int)(0.15*freq);
        m_1=m-1;
        state=0;
        exp_pitch=0;
        exp_pitch2=0;
        exp_yaw=0;
        counter=0;
    }
    public static void StopWritingAndExit(){
        writeornot = false;
    }
    public AssistentThread(String UserName, Handler HandleIn,String DeviceName,int index,Date fileCreateTimeIn,long FileCreateTime_L) throws IOException {
        // 先将文件、蓝牙的outputStream、inputStream建立好，出错则由调用方处理
        File path, file,fileForStep,fileForTruth;
        IndexID = index;
        Socket = MainActivity.Socket[index];
        BToutput = Socket.getOutputStream();
        BTinput = Socket.getInputStream();
        fileCreateTime = fileCreateTimeIn;
        String NowerDate = MyLib.GetDate(fileCreateTime);
        long_fileCreateTime = FileCreateTime_L;
        filename = DeviceName + "-" + MyLib.sDateFormat.format(fileCreateTime) + "-" + UserName + ".txt";
        filenameForStep = DeviceName + "-ForStep"+MyLib.sDateFormat.format(fileCreateTime) + "-" + UserName
                + ".txt";
//        filenameForTruth="ForTruth"+MyLib.sDateFormat.format(fileCreateTime)
//                + "-" + DeviceName + ".txt";
        path = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                + File.separator + "WatchOut" + File.separator + NowerDate);
        if (!path.exists()){
            path.mkdirs();
        }
        fileCreateNotice = "File name: \r\n" + filename + "\r\n"
                + "Directory: \r\n" + path.toString();
        file = new File(path, filename);
        fileForStep=new File(path,filenameForStep);

        output = new FileOutputStream(file);
        outputForStep=new FileOutputStream(fileForStep);
        writeornot = true;
        this.start();
    }
    public void run(){
        final double[] trans={9.80665/4096,1.0/131};//,0.3};
        String DataToFile = "", DataDisplay = "";

        boolean flag = true;
        boolean Ignore = false;
        long CTime,LTime;
        LTime = System.currentTimeMillis();

        long_lastTime = long_fileCreateTime;
        initThrs();
        initStep();
        try {
            BToutput.write('1');
        }
        catch (IOException e){
            writeornot = false;
            e.printStackTrace();
            Log.d(tag,"Failed to write 1");
        }
        while (writeornot) {
            /*CTime = System.currentTimeMillis();
            if (CTime - LTime > 1000 + (int)(Math.random() * 200) ) {
                WatchOutService.AddStepBy1();
                LTime = CTime;
            }
            */
            now = new java.util.Date();
            long_nowTime2 = long_nowTime = System.currentTimeMillis();
//            if (10 >= long_nowTime % 1000) PostToMainThread(textView_time,
//                    "Now time: "+MyLib.nowtimeFormat.format(now)
//                            +"\r\nDesired length: "+desiredSeconds+" seconds.");
            while (long_nowTime2 < long_lastTime) long_nowTime2 += 86400000;
            long_lastTime = long_nowTime2;
            long_deltaTime = long_nowTime2 - long_fileCreateTime;
            String string_number;
            mode=0;
            Ignore = false;
            while (mode<6) {
                char data = 0;
                double double_number;
                string_number="";
                while('\t'==data||'\r'==data||'\n'==data||0==data){
                    try { data = (char) BTinput.read(); }
                    catch (Exception e) {
                        Log.d(tag, "Bluetooth data reading error1.");
//                        PostToMainThread(textview_bluetoothnotice,"Bluetooth data reading error1.");
                        writeornot=false;
                        mode=8;
                        break;
                    }
                }
                while('\t'!=data&&'\r'!=data&&'\n'!=data){
                    string_number+=data;
                    try { data = (char) BTinput.read(); }
                    catch (Exception e) {
                        Log.d(tag, "Bluetooth data reading error2.");
//                        PostToMainThread(textview_bluetoothnotice,"Bluetooth data reading error2.");
                        writeornot=false;
                        mode=6;
                        break;
                    }
                }
                try {
                    double_number = trans[(mode / 3)] * Long.valueOf(string_number);
                }
                catch (Exception e){
                    Ignore = true;
                    double_number = Double.NaN;
                }
                if (mode > 6) break;
                RawData[mode][len]=(double_number);
                string_number=MyLib.dataFormat.format(double_number);
                DataToFile+=string_number+" \t ";
                //DataDisplay+=string_number+"\r\n";
                mode++;
            }
            if (Ignore){
                DataToFile = "";
                Log.d(tag,"Ignored one Data");
                continue;
            }
            counterInStep++;
            RawAccMagnitude[len]=
                    Math.sqrt(MyLib.square(RawData[1][len])+MyLib.square(RawData[2][len]));
            ButterAccMagnitude[len]=getButterworth(RawAccMagnitude,ButterAccMagnitude,
                    ButterMagA,ButterMagB,len,
                    MyLib.FilterOrder,SavedPointNum);
                /*for(int i=0;i<6;i++)
                    ButterData[i][len]=getButterworth(RawData[i],ButterData[i],
                            SomeLib.butterForRawdata_a,SomeLib.butterForRawdata_b,
                            len,FilterOrder,SavedPointNum);
                */
            //pitch!pitch!pitch!pitch!pitch!pitch!
            double T=0.02,k=10.0;
            int len_1=(len-1+SavedPointNum)%SavedPointNum;
            alpha[len]= Math.atan(RawData[0][len]/RawData[2][len]);
            beta[len]=alpha[len]-pitch[len_1];
            v[len]=T*k*k*beta[len]+v[len_1];
            w[len]=v[len]+2*k*beta[len]+RawData[4][len]/180* Math.PI;
            pitch[len]=T*w[len]+pitch[len_1];
            //pitch!pitch!pitch!pitch!pitch!pitch!
            double tmpYaw=GetYaw(RawData[0][len],RawData[1][len],RawData[2][len],
                    RawData[3][len],RawData[4][len],RawData[5][len],8.3,3.1);
            {   //where x=tmpYaw is the new detected yaw,
                // which is in the range of [-180,180) or (-180,180],
                // and y=yaw[len_1] is the last yaw.
                //We want to minimize abs(newYaw-y),
                //where newYaw=x+k*360 where k is an arbitrary integer.
                //Thus k=min{integer k| abs(360*k+x-y)}.
                //f(k)=(360*k+x-y)^2=(360^2)*k^2+720*(x-y)*k+(x-y)^2.
                //So k should be around 720*(x-y)/(-2*(360^2))=(y-x)/360.
                //k is represented by the variable 'kkk'.
            }
            double ErrorCircle=360/YawButterErrCorrection;
            if(Math.abs(tmpYaw-yaw[len_1])>180){
                long kkk= Math.round((yaw[len_1]-tmpYaw)/ErrorCircle);
                yaw[len]=tmpYaw+kkk*ErrorCircle;
            }else yaw[len]=tmpYaw;
            //*
            ButterYaw[len]=getButterworth(yaw,ButterYaw,ButterYawA,
                    ButterYawB, len,MyLib.FilterOrder_Yaw,SavedPointNum);
                        /*/
                ButterYaw[len]=yaw[len];//*/
            //yaw!!!yaw!!!yaw!!!yaw!!!yaw!!!yaw!!!
            int len_m=(len-m+SavedPointNum)%SavedPointNum;
            exp_pitch+=(pitch[len]-pitch[len_m])/m;
            NowPitch=exp_pitch;
            exp_yaw+=(ButterYaw[len]-ButterYaw[len_m])/m;
            exp_pitch2+=(MyLib.square(pitch[len])-MyLib.square(pitch[len_m]))/m;
            var_pitch=(exp_pitch2-MyLib.square(exp_pitch))*m/m_1;
            updateFSM(pitch[len],exp_pitch,var_pitch,exp_yaw);
            DataDisplay="PitchStatic="+PitchStatic*180/ Math.PI
                    +"\nPITCH:\n"+((pitch[len]<0)?"":"+")
                    +MyLib.dataFormat.format(pitch[len])+"\nYAW:\n"
                    +((ButterYaw[len]<0)?"":"+")+MyLib.dataFormat.format(ButterYaw[len]);
//            PostToMainThread(textview_display,DataDisplay);
            DataDisplay = "";
            if (writeornot) {
                try {
                    String tmpstr=(MyLib.counterFormat.format(counter) + " "
                            + MyLib.millisecFormat.format(long_deltaTime) + " "
                            + DataToFile + " \t"
                            + ButterYaw[len]+"\t"
                            + len+"\t"+ state+"\t"+ state_len+"\t" + "\r\n");
                    output.write(tmpstr.getBytes());
                } catch (Exception e)
                { Log.d(tag, "Output to file error."); }
                //Log.d(tag, DataToFile);
                DataToFile = "";
            }
            if (flag&&long_deltaTime > (500 + 1000 * desiredSeconds)) {
                if (Math.abs(NowPitch) > 0.75)
                    desiredSeconds += 1;
                else {
                    SetFlat();
                    flag = false;
                }

            }
            len=(len+1)%SavedPointNum;
            counter++;
        }
        fileSaveNotice = "File save time: " + MyLib.sDateFormat.format(now)
                + ".\t\n" + counter + " datapoints in total.";
        Log.d(tag, fileSaveNotice);
        try {
            output.write(fileSaveNotice.getBytes());
            output.close();
            String s="PitchStatic="+PitchStatic+"\r\n";
            outputForStep.write(s.getBytes());
            outputForStep.close();
//            outputForTruth.close();
        } catch (Exception e)
        { Log.d(tag, "File close error."); }
        try {
            BToutput.write('0');
        }
        catch (IOException e){
            Log.d(tag,"Write '0' Failed!");
        }

        Log.d(tag, "Data Receiving Over.");

    }
    public void SetFlat(){
        PitchStatic=NowPitch;
    }

    private double GetYaw(double ax,double ay,double az,double gx,double gy,double gz,
                          double twokp,double twoki){
        double q0=0,q1=0,q2=0, q3=0;
        int samplefreq=50;
        double integralFBx=0,integralFBy=0,integralFBz=0;

        gx=gx*PI/180;
        gy=gy*PI/180;
        gz=gz*PI/180;
        double recipNorm=(Math.sqrt(ax*ax+ay*ay+az*az));
        ax=ax/recipNorm;
        ay=ay/recipNorm;
        az=az/recipNorm;
        double halfvx=q1*q3-q0*q2;
        double halfvy=q0*q1+q2*q3;
        double halfvz=q0*q0-0.5+q3*q3;
        double halfex=(ay*halfvz-az*halfvy);
        double halfey=(az*halfvx-ax*halfvz);
        double halfez=(ax*halfvy-ay*halfvx);
        integralFBx+=twoki*halfex/samplefreq;
        integralFBy+=twoki*halfey/samplefreq;
        integralFBz+=twoki*halfez/samplefreq;//12.32,28.14
        gx+=integralFBx;
        gy+=integralFBy;
        gz+=integralFBz;

        gx+=twokp*halfex;
        gy+=twokp*halfey;
        gz+=twokp*halfez;

        gx=(0.5*gx/samplefreq);
        gy=(0.5*gy/samplefreq);
        gz=(0.5*gz/samplefreq);
        double qa=q0,qb=q1,qc=q2;
        q0+=(-qb*gx-qc*gy-q3*gz);
        q1+=(qa*gx+qc*gz-q3*gy);
        q2+=(qa*gy-qb*gz+q3*gx);
        q3+=(qa*gz+qb*gy-qc*gx);

        recipNorm=(Math.sqrt(q0*q0+q1*q1+q2*q2+q3*q3));
        q0/=recipNorm;
        q1/=recipNorm;
        q2/=recipNorm;
        q3/=recipNorm;
        double yaw=Math.atan2(2*q1*q2+2*q0*q3,-2*q2*q2-2*q3*q3+1)*57.3;
        return yaw;
    }

}
