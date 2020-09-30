package com.example.SensorGroup.lookupmobile;
/**
 * Created by lijw on 2018/1/30.
 * Changed by ZTG on 2018/4/24 - 22:43
 */
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.text.DecimalFormat;
import java.util.Date;

//latest change 190 309 166 196 319 337-344 建一个stepdata数组放stepdata的数据 写一个方法：
public class SensorActivity extends AppCompatActivity {
    static TextView accelerometerView,gyroscopeView,orientationView;
    private SensorManager sensorManager;
    private MySensorEventListener sensorEventListener;
    static TextView textView_acc,textView_gyr,textView_ori;//,textView_mag
    static TextView samplingRateView,textView_filenotice,textView_time;
    final static int FilterOrder=6,SavedPointNum=500;
    private int StepCount=0;
    final private double max_step_time=1.5,min_step_time=0.0,constant_for_Thr=0.73;
    private double ThrForMag,ExpForMag_x1,ExpForMag_x1_w,ExpForMag_x2;
    private int max_step_length,min_step_length;
    private Date fileCreateTime;
    private String filename,DataStepFileName;
    private String stringRate,stringSeconds;
    private long longDesiredSeconds;
    private String fileSaveNotice,fileCreateNotice;
    private String InputTesterName,TesterName;
    private String[] stringsRates;
    private File file,path,StepFile,SVMFile;
    static OutputStream  StepDataOut;
    DataOutputStream output;
    private long counter,counterForMag,long_fileCreateTime;
    private int counterInStep,SamplingRate,TesterChoice;
    private boolean acc_acquired,accLinear_acquired,gyr_acquired,ori_acquired;
    private boolean ClickToStop=false;
    private Handler mHandler;
    
    private double UpdateExp(double OldExp1,double OldExp2,long num1,long num2){ //正常平均
        return (num1*OldExp1+num2*OldExp2)/(num1+num2);
    }
    private double UpdateExp_w(double OldExp1,double OldExp2,long num1,long num2){ //带权平均
        double a=3;//10为总权数
        double p2=a/((10-a)*num1+a*num2),p1=(10-a)*p2/a;
        return p1*num1*OldExp1+p2*num2*OldExp2;
    }
    
    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_sensor);
        sensorEventListener = new MySensorEventListener();
        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);

        accelerometerView =this.findViewById(R.id.accelerometerView);
        gyroscopeView =this.findViewById(R.id.gyroscopeView);
        orientationView =this.findViewById(R.id.orientationView);
        textView_acc=this.findViewById(R.id.textView_Acc);
        textView_gyr=this.findViewById(R.id.textView_Gyr);
        textView_ori=this.findViewById(R.id.textView_Ori);
        samplingRateView=this.findViewById(R.id.SamplingRateView);
        textView_filenotice=this.findViewById(R.id.Filename_Notice);
        textView_time=this.findViewById(R.id.textView_time);

        mHandler=new Handler();
        StepArray.init(mHandler);
        stringsRates = getResources().getStringArray(R.array.samplingRates);
        final String[] StringsTesters = getResources().getStringArray(R.array.Testers);
        int defaultTesterChoice=getResources().getInteger(R.integer.TesterNumber);
        Intent intent=getIntent();
        stringSeconds=intent.getStringExtra(MainActivity.SECONDS);
        try{
            longDesiredSeconds=Long.valueOf(stringSeconds);
        }catch (NumberFormatException e){
            longDesiredSeconds=86401;//24hours
        }
        SamplingRate=intent.getIntExtra(MainActivity.PPP,0);
        TesterChoice=intent.getIntExtra(MainActivity.CHOICE,defaultTesterChoice);
        Log.d(MyLib.TAG,"TesterChoice="+TesterChoice+"");
        Log.d(MyLib.TAG,"defaultTesterChoice="+defaultTesterChoice+"");
        try{
            InputTesterName=intent.getStringExtra(MainActivity.TESTER);
        }catch(Exception e){
            Log.d(MyLib.TAG,"No tester name input.");
        }
        if(0==InputTesterName.length())InputTesterName="UnknownTester";
        Log.d(MyLib.TAG,"****"+InputTesterName);
        if(TesterChoice==defaultTesterChoice)TesterName=InputTesterName;
        else TesterName=StringsTesters[TesterChoice];

        counter=0;
        counterForMag=1000;
        ThrForMag=9.99511891955305; //1.4 threshold
        ExpForMag_x1=ThrForMag;
        ExpForMag_x1_w = ThrForMag;
        ExpForMag_x2=ThrForMag*ThrForMag;
        counterInStep=0;
        max_step_length=(int)(max_step_time*100); //dont copy samplingrate here
        min_step_length=(int)(min_step_time*100); //dont copy samplingrate here

        //Constants
        stringRate=stringsRates[SamplingRate];
        samplingRateView.setText(stringRate);
        fileCreateTime=new Date();
        long_fileCreateTime=0;

        long_fileCreateTime = System.currentTimeMillis();
        String NowerDate = MyLib.GetDate(fileCreateTime);
        filename= MyLib.sDateFormat.format(fileCreateTime)+"-"+stringRate+"-"+TesterName+".txt";
        fileCreateNotice="File create time: "+MyLib.sDateFormat.format(fileCreateTime)+".";
        path=new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
            + File.separator + NowerDate);
        SVMFile = new File(Environment.getExternalStoragePublicDirectory
                (Environment.DIRECTORY_DOCUMENTS) + File.separator + "SVM_PARAMETER.dat");
        if (!path.exists()){
            path.mkdirs();
        }
        try{
            DataInputStream SVMIn = new DataInputStream(new FileInputStream(SVMFile));
            StepArray.ReadSVMParameters(SVMIn);
        }
        catch (FileNotFoundException e){
            textView_gyr.setText("Error1:SVM File Not Found!.");
            e.printStackTrace();
        }
        catch (IOException e){
            textView_gyr.setText("Error2: Read SVM Parameters");
            e.printStackTrace();
        }
        catch (Exception e){
            textView_gyr.setText("Other Error");
            e.printStackTrace();
        }
        file=new File(path,filename);
        DataStepFileName = "StepData-" + filename;
        try {
            output = new DataOutputStream( new BufferedOutputStream(new FileOutputStream(file)));
        } catch (Exception e) {
            e.printStackTrace();
            textView_acc.setText("Error1: Open error: Data.");
        }
        StepFile = new File(path,DataStepFileName);
        try{
            StepDataOut = new BufferedOutputStream( new FileOutputStream(StepFile));
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            textView_acc.setText("Error1: Open error: StepData.");
        }
        StepArray.LastStepLog = 1;
        acc_acquired=false;gyr_acquired=false;ori_acquired=false;
    }
    @Override
    protected void onResume()
    {
        Sensor accelerometerSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        sensorManager.registerListener(sensorEventListener, accelerometerSensor, SamplingRate);
        Sensor accelerometerSensorLinear = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION);
        sensorManager.registerListener(sensorEventListener,accelerometerSensorLinear,SamplingRate);
        Sensor gyroscopeSensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        sensorManager.registerListener(sensorEventListener, gyroscopeSensor, SamplingRate);
        Sensor orientationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ORIENTATION);
        sensorManager.registerListener(sensorEventListener, orientationSensor, SamplingRate);
        super.onResume();
    }
    private final class MySensorEventListener implements SensorEventListener
    {
        double acc_x=0,acc_y=0,acc_z=0;
        double accLinear_x=0,accLinear_y=0,accLinear_z=0;
        double gyr_x=0,gyr_y=0,gyr_z=0;
        double ori_x=0,ori_y=0,ori_z=0;
        long long_nowTime,long_nowTime2,long_deltaTime;
        long long_lastTime=long_fileCreateTime;
        boolean writeornot=true;
        double[][] RawData=new double[12][SavedPointNum+1];
        double[][] ButterData=new double[9][SavedPointNum+1];
        double[] RawAccMagnitude=new double[SavedPointNum+1];
        double[] ButterAccMagnitude=new double[SavedPointNum+1];
        double[] ButterAccMagNoMean=new double[SavedPointNum+1];
        int[] len={FilterOrder+1,FilterOrder+1,FilterOrder+1,FilterOrder+1,FilterOrder+1};
        int LEN=9,id=0;
        Step[] steps = new Step[LEN];
        double ExpForMagInStep_x1=0,ExpForMagInStep_x1_w=0,ExpForMagInStep_x2=0;
        double ExpTmp_x1,ExpTmp_x1_w,ExpTmp_x2,NewThr,LastAccMagPeak;
        int StateInStep=1;
        private long[] TimeSeriesInStep = new long[SavedPointNum]; //一步里各个点的时间序列;
        //1:Low stage i.e. less than Thr;
        //2:Waiting for peak;
        //3:After peak but greater than Thr;
        //4:High stage to be discarded;
        //5:Low stage to be discarded;
//        
        private void updateFSM(){
            double xn,xn_1,xn_2;
            int i=0;
            xn=ButterAccMagnitude[len[0]];
            xn_1=ButterAccMagnitude[(len[0]-1+SavedPointNum)%SavedPointNum];
            xn_2=ButterAccMagnitude[(len[0]-2+SavedPointNum)%SavedPointNum];
            if(1==StateInStep){
                if(xn>ThrForMag){
                    if(counterInStep >= min_step_length && counterInStep <= max_step_length) {
                        StateInStep = 2;
                        ExpTmp_x1_w = UpdateExp(ExpForMag_x1_w, ExpForMagInStep_x1_w,
                                counterForMag - counterInStep, counterInStep);//mag mean with weight update
                        ExpForMag_x1_w = ExpTmp_x1_w;
                    }
                    else{
                        StateInStep=5;
                        counterInStep=1;
                    }
                }
            }
            else if(2==StateInStep){
                if(xn_1>xn&&xn_1>xn_2){ //find peaks
                    //Toast.makeText(SensorActivity.this, "peaks!", Toast.LENGTH_SHORT).show();
                    StateInStep=3;
                    StepCount++;
                    id = (id+1)%LEN;
                    steps[id]=new Step(ButterData,
                            (len[0]-1+SavedPointNum)%SavedPointNum,//peak index
                            counterInStep-1,StepCount,TimeSeriesInStep,ThrForMag,xn_1);
                    steps[id].start();//New Thread for a step!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    ExpTmp_x1=UpdateExp(ExpForMag_x1,ExpForMagInStep_x1,
                            counterForMag-counterInStep,counterInStep);//mag mean update
                    ExpForMag_x1 = ExpTmp_x1;
                    ExpTmp_x1_w=UpdateExp_w(ExpForMag_x1_w,ExpForMagInStep_x1_w,
                            counterForMag-counterInStep,counterInStep);//mag mean with weight update
                    ExpForMag_x1_w = ExpTmp_x1_w;
                    ExpTmp_x2=UpdateExp(ExpForMag_x2,ExpForMagInStep_x2,
                            counterForMag-counterInStep,counterInStep);
                    ExpForMag_x2 = ExpTmp_x2;
                    NewThr=ExpTmp_x1+constant_for_Thr*Math.sqrt(counterForMag/(counterForMag-1)//std
                            *(ExpTmp_x2-MyLib.square(ExpTmp_x1))); //for judging stateinstep
                    counterInStep=1;
                    ExpForMagInStep_x1=xn;
                    ExpForMagInStep_x1_w=xn;
                    ExpForMagInStep_x2=xn*xn;
                }
            }
            else if(3==StateInStep){
                if(xn<xn_1&&xn_1<ThrForMag){ //&&xn_1<NewThr
                    if(counterInStep<=min_step_length||counterInStep>=max_step_length){
                        counterInStep=1;
                        StateInStep=5;
                    }
                    else{
                        ThrForMag=NewThr; //for judging stateinstep
                        StateInStep=1;
                        ExpTmp_x1_w=UpdateExp(ExpForMag_x1_w,ExpForMagInStep_x1_w,
                                counterForMag-counterInStep,counterInStep);//mag mean with weight update
                        ExpForMag_x1_w = ExpTmp_x1_w;
                    }
                }
                ExpTmp_x1_w=UpdateExp(ExpForMag_x1_w,ExpForMagInStep_x1_w,
                        counterForMag-counterInStep,counterInStep);//mag mean with weight update
                ExpForMag_x1_w = ExpTmp_x1_w;
            }
            else if(4==StateInStep){
                if(xn<xn_1&&xn_1<=xn_2)LastAccMagPeak=xn_1; //这个变量有用么？
                if(xn<ThrForMag){
                    counterInStep=1;
                    StateInStep=1;
                    ExpTmp_x1_w=xn;
                }
            }
            else if(5==StateInStep){
                if(xn>ThrForMag){
                    counterInStep=1;
                    StepCount++;
                    StepArray.SetStand(StepCount);
                    StateInStep=4;
                }
            }
        }
        @Override
        public void onSensorChanged(SensorEvent event)
        {
            if(!writeornot)return;
            Date now;
            now=new Date();
            long_nowTime = System.currentTimeMillis();
            long_nowTime2=long_nowTime;
            while(long_nowTime2<long_lastTime)long_nowTime2+=86400000;
            long_lastTime=long_nowTime2;
            long_deltaTime=long_nowTime2-long_fileCreateTime;
            String viewText_time;
            if(long_deltaTime<500+1000*longDesiredSeconds && !ClickToStop) {
                if(10 >= long_nowTime%1000)
                {
                    textView_time.setText(fileCreateNotice+ "\r\nNow time: "+
                            MyLib.nowtimeFormat.format(now)+ "\r\nDesired length: "+
                            longDesiredSeconds+" seconds.");
                }
            }else if(writeornot){
                writeornot=false;
                textView_filenotice.setText("File: \""+filename+"\" saved in : \""+path+
                        "\".\r\nSampling rate is: "+SamplingRate+".");
                viewText_time=MyLib.sDateFormat.format(now);
                fileSaveNotice="File save time: "+viewText_time+
                        ".\t\n"+counter+" datapoints in total.";
                textView_time.setText(fileCreateNotice+"\r\n"+fileSaveNotice);
                try{
                    output.write(fileSaveNotice.getBytes());
                    output.close();
                    StepDataOut.close();
                }catch (Exception e) {
                    e.printStackTrace();
                    //textView_mag.setText("Error2: Save error.");
                }
            }
            double x = event.values[SensorManager.DATA_X];
            double y = event.values[SensorManager.DATA_Y];
            double z = event.values[SensorManager.DATA_Z];
            DecimalFormat viewDecimalFormat=new DecimalFormat("00.000");
            String xx=viewDecimalFormat.format(x);
            String yy=viewDecimalFormat.format(y);
            String zz=viewDecimalFormat.format(z);
            if(event.sensor.getType() == Sensor.TYPE_LINEAR_ACCELERATION){
                if(!accLinear_acquired){
                    len[0] = (len[0] + 1) % SavedPointNum;
                    RawData[0][len[0]] = accLinear_x = x;
                    RawData[1][len[0]] = accLinear_y = y;
                    RawData[2][len[0]] = accLinear_z = z;
                    accLinear_acquired = true;
                    //accelerometerView.setText("X:" + xx + "\r\nY:" + yy + "\r\nZ:" + zz);
                }
            }
            else if(event.sensor.getType()==Sensor.TYPE_ACCELEROMETER) {
                if (!acc_acquired) {
                    len[4] = (len[4] + 1) % SavedPointNum;
                    RawData[9][len[4]] = acc_x = x;
                    RawData[10][len[4]] = acc_y = y;
                    RawData[11][len[4]] = acc_z = z;
                    RawAccMagnitude[len[4]]=Math.sqrt(x*x+y*y+z*z);
                    ButterAccMagnitude[len[4]]=MyLib.getButterworth(RawAccMagnitude,ButterAccMagnitude,
                            MyLib.butterForMag_a,MyLib.butterForMag_b,len[4],SavedPointNum);
                    ButterAccMagNoMean[len[4]] = ButterAccMagnitude[len[4]] - ThrForMag;//ExpTmp_x1_w;
                    acc_acquired = true;
//                    accelerometerView.setText("X:" + xx + "\r\nY:" + yy + "\r\nZ:" + zz);
//                    accelerometerView.setText("X:" + xx + "\r\nY:" + yy + "\r\nZ:" + zz
//                            +"\r\nRawAccMag:\r\n"+RawAccMagnitude[len[4]]
//                            +"\r\nButterAccMag:\r\n"+ButterAccMagnitude[len[4]]);s
                }
            }
            else if(event.sensor.getType()==Sensor.TYPE_GYROSCOPE){
                if(!gyr_acquired)
                {
                    len[1] = (len[1] + 1) % SavedPointNum;
                    RawData[3][len[1]] = gyr_x = x;
                    RawData[4][len[1]] = gyr_y = y;
                    RawData[5][len[1]] = gyr_z = z;
                    gyr_acquired = true;
                    //gyroscopeView.setText("X:"+xx+"\r\nY:"+yy+"\r\nZ:"+zz);
                }
            }
            else if(event.sensor.getType()==Sensor.TYPE_ORIENTATION) {
                if (!ori_acquired) {
                    len[2] = (len[2] + 1) % SavedPointNum;
                    //judge leap
                    if(Math.abs(x-RawData[6][(len[3]-1+SavedPointNum)%SavedPointNum])>180){
                        long kn=Math.round((RawData[6][(len[3]-1+SavedPointNum)%SavedPointNum]-x)/360);
                        x=x+kn*360;
                    }
                    RawData[6][len[2]] = ori_x = x;
                    RawData[7][len[2]] = ori_y = y;
                    RawData[8][len[2]] = ori_z = z;
                    ori_acquired = true;
                    //orientationView.setText("X:" + xx + "\r\nY:" + yy + "\r\nZ:" + zz);
                }
            }
            if(writeornot&&(acc_acquired&&accLinear_acquired&&gyr_acquired&&ori_acquired)) {
                len[3] = (len[3] + 1) % SavedPointNum;
                TimeSeriesInStep[len[3]] = long_deltaTime;
                String sx, sy, sz, ss;
                counter++;
                counterForMag++;
                ExpForMagInStep_x1=UpdateExp(ExpForMagInStep_x1,
                        ButterAccMagnitude[len[0]],counterInStep,1);
                ExpForMagInStep_x1_w = ExpForMagInStep_x1;
                ExpForMagInStep_x2=UpdateExp(ExpForMagInStep_x2,
                        MyLib.square(ButterAccMagnitude[len[0]]),counterInStep,1);
                counterInStep++;

                /******************/
                updateFSM();
                /******************/
                for(int i=0;i<9;i++) {
                    ButterData[i][len[i / 3]] = MyLib.getButterworth(RawData[i], ButterData[i],
                            MyLib.butterForRawdata_a, MyLib.butterForRawdata_b, len[i / 3], SavedPointNum);
                }
                //test curb 4&5
                /*double thr4curb = peaks[counterInStep-5]*Weight[0]+peaks[counterInStep-4]*Weight[1]+
                        peaks[counterInStep-3]*Weight[2]+peaks[counterInStep-2]*Weight[3]+
                        peaks[counterInStep-1]*Weight[4]+peaks[counterInStep]*Weight[5];
                if(peaks[counterInStep-2]>thr4curb) //state of peaks[counterInStep-2] =4&5*/
                ss = MyLib.counterFormat.format(counter) + "\t"
                        + MyLib.millisecFormat.format(long_deltaTime) + "\t";
                acc_acquired=gyr_acquired=ori_acquired= accLinear_acquired =false;
                try {

                    sx = MyLib.dataFormat.format(accLinear_x);
                    sy = MyLib.dataFormat.format(accLinear_y);
                    sz = MyLib.dataFormat.format(accLinear_z);
                    ss+=(sx + "  " + sy + "  " + sz +"\t");
                    sx = MyLib.dataFormat.format(gyr_x);
                    sy = MyLib.dataFormat.format(gyr_y);
                    sz = MyLib.dataFormat.format(gyr_z);
                    ss+=(sx + "  " + sy + "  " + sz + "\t");
                    sx = MyLib.dataFormat.format(ori_x);
                    sy = MyLib.dataFormat.format(ori_y);
                    sz = MyLib.dataFormat.format(ori_z);
                    ss+=(sx + "  " + sy + "  " + sz + "\t");
                    sx = MyLib.dataFormat.format(acc_x);
                    sy = MyLib.dataFormat.format(acc_y);
                    sz = MyLib.dataFormat.format(acc_z);
                    ss+=(sx + "  " + sy + "  " + sz + "\t");
                    ss+=(StateInStep+"\r\n");
                    ss+=(ThrForMag+"\t");
                    ss+=(ButterAccMagnitude[len[0]]+"\t");
                    ss+=(ButterAccMagNoMean[len[0]]+"\t");
                    ss+=(ExpTmp_x1_w+"\r\n");
                    output.write(ss.getBytes());
                } catch (Exception e) {
                    e.printStackTrace();
                    textView_gyr.setText("Error3: Write error.");
                }
            }
        }
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy)
        {
        }
    }
    public void ClickToStop(View view){
        ClickToStop=true;
    }
    static synchronized public void ChangeTextview(TextView textView,String s){
        textView.setText(s);
    }
    @Override
    protected void onPause()
    {
        sensorManager.unregisterListener(sensorEventListener);
        super.onPause();
    }
    @Override
    protected void onDestroy(){
        stringSeconds="";
        TesterChoice=0;
        InputTesterName="";
        TesterName="";
        super.onDestroy();
    }
}