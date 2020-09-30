package com.program.sensorgroup.watchout;

import android.app.Notification;
import android.app.PendingIntent;
import android.app.Service;
import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.graphics.BitmapFactory;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Binder;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.widget.TextView;
import android.widget.Toast;

import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.DecimalFormat;
import java.util.Date;

import com.program.sensorgroup.watchout.MyLib.Butter;

/**
 * Created by IssacRunmin on 18/7/10.
 */

public class WatchOutService extends Service {
    //State:
    private static boolean isCreated = false;
    private static final String TAG = "MyService";
    private static int NoticeID = 221;
    public static int StepCount;
    private boolean Connected[] = new boolean[2];
    private boolean SecondBT;
    private String UserName;
    private AssistentThread ServiceThread;
    private boolean CreatSuccess = true;
    BluetoothDevice Device;
    //private AssistentThread ServiceThread;
    private MainBinder mainBinder = new MainBinder();
    private SensorManager sensorManager;
    private MySensorEventListener sensorEventListener;
    final static int FilterOrder=6,SavedPointNum=500;
    final private double max_step_time=1.2,min_step_time=0.0,constant_for_Thr=0.73;
    private double ThrForMag,ExpForMag_x1,ExpForMag_x1_w,ExpForMag_x2;
    private int max_step_length,min_step_length;
    private Date fileCreateTime;
    private String filename,DataStepFileName,GTFileName;
    private String stringRate,stringSeconds;
    private long longDesiredSeconds;
    private String fileSaveNotice,fileCreateNotice;
    private String InputTesterName,TesterName;
    private String[] stringsRates;
    private File file,path,StepFile,SVMFile;
    static OutputStream StepDataOut;
    DataOutputStream output;
    private long counter,counterForMag,long_fileCreateTime;
    private int counterInStep,SamplingRate,TesterChoice;
    private boolean acc_acquired,accLinear_acquired,gyr_acquired,ori_acquired;
    private boolean ClickToStop=false;
    private String tag = "WatchOutService";
    private Handler myHandler;
    final Intent StepInfoIntent = new Intent(MainActivity.ACTION_UPDATEUI);
    final Intent ErrIntent = new Intent(MainActivity.ACTION_ErrLog);
    boolean writeornot=true;
    int SampleRateHz;
    double[] ButterSegA,ButterSegB,ButterProA,ButterProB;
    long CurrentStepTime;
    private boolean TrainRamp;
    private boolean RampType;


    @Override
    public int onStartCommand(Intent intent, int flags, int startId){
        Log.d(TAG,"onStartCommand");
        Notification.Builder builder;
//        Notification.Builder builder = new Notification.Builder(this.getApplicationContext());
        //获取一个Notification构造器
        /* 对于API > 26 的系统，通知需要渠道，没有渠道的通知不能显示
        * 通知的渠道“state”在MainActivity 注册了，因此这里直接用*/
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            builder = new Notification.Builder(this.getApplicationContext(),"state");
        else
            builder = new Notification.Builder(this.getApplicationContext());
        Intent NoticeIntent = new Intent(this,MainActivity.class);
        builder.setContentIntent(PendingIntent.getActivity(this,0, NoticeIntent,0))// 设置PendingIntent
                .setLargeIcon(BitmapFactory.decodeResource(this.getResources(),R.mipmap.ic_launcher))// 大图标
                .setSmallIcon(R.drawable.ic_notice) // 小图标
                .setContentTitle("服务已开启")//标题
                .setContentText("请注意行走安全！")// 内容
                .setWhen(System.currentTimeMillis());//设置通知发生的时间，即立即发生
        Notification Notice = builder.build(); //获取构建好的Notification
//        StepCount = intent.getIntExtra("StepCount",0);
        StepCount = 0;
        UserName = intent.getStringExtra("UserName");
        SecondBT = intent.getBooleanExtra("SecondBT",false);
        stringRate = intent.getStringExtra("SampleRate");
        String DeviceName[] = new String[2];
        Connected[0] = intent.getBooleanExtra("Connect1",false);
        Connected[1] = intent.getBooleanExtra("Connect2",false);
        DeviceName[0] = intent.getStringExtra("DeviceName1");
        DeviceName[1] = intent.getStringExtra("DeviceName2");
        TrainRamp = intent.getBooleanExtra("TrainRamp",false);
        RampType = intent.getBooleanExtra("DownRampRecord",false);
        int RateIndex = intent.getIntExtra("RateIndex",0);
        switch (RateIndex){
            case 0:if (android.os.Build.BRAND.equals("xiaomi")) SampleRateHz = 200;
                else    SampleRateHz = 100;break;
            case 1: SampleRateHz = 50;break;
            case 2: SampleRateHz = 20;break;
            case 3: SampleRateHz = 2; break;
            default:SampleRateHz = 100;
        }
        ButterSegA = Butter.GetButter('W',1,'A',SampleRateHz);
        ButterSegB = Butter.GetButter('W',1,'B',SampleRateHz);
        ButterProA = Butter.GetButter('W',2,'A',SampleRateHz);
        ButterProB = Butter.GetButter('W',2,'B',SampleRateHz);
        intent.setAction(MainActivity.ACTION_UPDATEUI);
        myHandler = new Handler(){
            @Override
            public void handleMessage(Message msg){
                super.handleMessage(msg);
                StepInfoIntent.putExtra("StepInfo",(String)msg.obj);
//                sendBroadcast(StepInfoIntent);
                LocalBroadcastManager.getInstance(WatchOutService.this).sendBroadcast(StepInfoIntent);
                Log.d(tag,"Broadcast Sended!");
            }
        };
        fileCreateTime=new Date();
        long_fileCreateTime = System.currentTimeMillis();
        for (int i = 0;i < 2; i++) {
            if (Connected[i]) {
                try {
                    ServiceThread = new AssistentThread(UserName, myHandler, DeviceName[i],i,fileCreateTime,long_fileCreateTime);
                } catch (IOException e) {
                    Toast.makeText(WatchOutService.this,
                            "Service Start Failed!", (Toast.LENGTH_SHORT)).show();
                    CreatSuccess = false;
                    stopSelf();
                }
            }
        }
        sensorEventListener = new MySensorEventListener();
        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        counter=0;
        counterForMag=1000;
        ThrForMag=9.99511891955305; //1.4 threshold
        ExpForMag_x1=ThrForMag;
        ExpForMag_x1_w = ThrForMag;
        ExpForMag_x2=ThrForMag*ThrForMag;
        counterInStep=0;
        max_step_length=(int)(max_step_time*SampleRateHz); //dont copy samplingrate here
        min_step_length=(int)(min_step_time*SampleRateHz); //dont copy samplingrate here

        //Constants
        stringsRates = getResources().getStringArray(R.array.samplingRates);
        SamplingRate = RateIndex;

//        stringRate=stringsRates[SamplingRate];
//        myLog(tag,stringRate);


        String NowerDate = MyLib.GetDate(fileCreateTime);
        filename= MyLib.sDateFormat.format(fileCreateTime)+"-"+stringRate+"-"+UserName+".txt";
        GTFileName = "GT" + MyLib.sDateFormat.format(fileCreateTime)+"-"+UserName+".txt";
        fileCreateNotice="File create time: "+MyLib.sDateFormat.format(fileCreateTime)+".";
        path=new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                + File.separator + "WatchOut" + File.separator + NowerDate + '-' + UserName);
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
            myLog(tag,"Error1:SVM File Not Found!.");
            SendErrMessage("SVM_File_Not_Found",e.getMessage());
            e.printStackTrace();
        }
        catch (IOException e){
            myLog(tag,"Error2: Read SVM Parameters");
            SendErrMessage("Read_SVM_File_Failed",e.getMessage());
            e.printStackTrace();
        }
        catch (Exception e){
            myLog(tag,"Other Error");
            SendErrMessage("SVM_File_Other_Exception",e.getMessage());
            e.printStackTrace();
        }
        if (TrainRamp){
            File PathT;
            PathT = new File(path, "UpRamp");
            if (!PathT.exists()) {
                PathT.mkdir();
                PathT = new File(PathT, "Unused");
                PathT.mkdir();
                PathT = new File(path, "DownRamp");
                PathT.mkdir();
                PathT = new File(PathT, "Unused");
                PathT.mkdir();
                PathT = new File(path, "Unused");
                PathT.mkdir();
            }
            if (RampType)
                path = new File(path,"DownRamp" + File.separator);
            else
                path = new File(path,"UpRamp" + File.separator);
        }
        file=new File(path,filename);
        DataStepFileName = "StepData-" + filename;
        try {
            output = new DataOutputStream( new BufferedOutputStream(new FileOutputStream(file)));
        } catch (Exception e) {
            e.printStackTrace();
            myLog(tag,"Error1: Open error: Data.");
            SendErrMessage("Open_File_Failed",e.getMessage());
        }
        StepFile = new File(path,DataStepFileName);
        try{
            StepDataOut = new BufferedOutputStream( new FileOutputStream(StepFile));
//            StepDataOut.write('N');
//            StepDataOut.close();
        }
        catch (FileNotFoundException e) {
            e.printStackTrace();
            myLog(tag,"Error1: Open error: StepData.");
        }
        StepArray.LastStepLog = 1;
        acc_acquired=false;gyr_acquired=false;ori_acquired=false;
        Sensor accelerometerSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        sensorManager.registerListener(sensorEventListener, accelerometerSensor, SamplingRate);
        Sensor accelerometerSensorLinear = sensorManager.getDefaultSensor(Sensor.TYPE_LINEAR_ACCELERATION);
        sensorManager.registerListener(sensorEventListener,accelerometerSensorLinear,SamplingRate);
        Sensor gyroscopeSensor = sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        sensorManager.registerListener(sensorEventListener, gyroscopeSensor, SamplingRate);
        Sensor orientationSensor = sensorManager.getDefaultSensor(Sensor.TYPE_ORIENTATION);
        sensorManager.registerListener(sensorEventListener, orientationSensor, SamplingRate);
        writeornot = true;

        Toast.makeText(WatchOutService.this,
                "服务已开启，请注意行走安全！", (Toast.LENGTH_SHORT)).show();

        startForeground(NoticeID,Notice);

        return super.onStartCommand(intent,flags,startId);
    }
    @Override
    public void onDestroy(){
        //ServiceThread.StopWritingAndExit();
        try{
            output.close();
            StepDataOut.close();
        }catch (Exception e) {
            e.printStackTrace();
            //textView_mag.setText("Error2: Save error.");
        }
        sensorManager.unregisterListener(sensorEventListener);
        AssistentThread.StopWritingAndExit();
        writeornot = false;
        Toast.makeText(WatchOutService.this,
                "服务结束", (Toast.LENGTH_SHORT)).show();

        isCreated = false;
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent){

        return mainBinder;
    }
    class MainBinder extends Binder {
        public int GetSteps(){
            return StepCount;
        }
        public String GetGTFileName(){
            return GTFileName;
        }
        public File GetPathDir(){return path;}
        public long GetFileCreateTime(){return long_fileCreateTime;}
        public long GetNowerTime(){return CurrentStepTime;}
    }

    @Override
    public void onCreate(){
        super.onCreate();
        isCreated = true;
        Log.d(TAG,"onCreate");
    }
    // Above: Auto-Created


    private final class MySensorEventListener implements SensorEventListener
    {
        double acc_x=0,acc_y=0,acc_z=0;
        double accLinear_x=0,accLinear_y=0,accLinear_z=0;
        double gyr_x=0,gyr_y=0,gyr_z=0;
        double ori_x=0,ori_y=0,ori_z=0;
        long long_nowTime,long_nowTime2,long_deltaTime;
        long long_lastTime=long_fileCreateTime;

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
                            counterInStep-1,StepCount,TimeSeriesInStep,ThrForMag,xn_1,myHandler);
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
            if(!writeornot) stopSelf();
//            Date now;
//            now=new Date();
            long_nowTime = System.currentTimeMillis();
            long_nowTime2=long_nowTime;
            while(long_nowTime2<long_lastTime)long_nowTime2+=86400000;
            long_lastTime=long_nowTime2;
            long_deltaTime=long_nowTime2-long_fileCreateTime;
//            String viewText_time;
//            if(long_deltaTime<500+1000*longDesiredSeconds && !ClickToStop) {
////                if(10 >= long_nowTime%1000)
////                {
////                    textView_time.setText(fileCreateNotice+ "\r\nNow time: "+
////                            MyLib.nowtimeFormat.format(now)+ "\r\nDesired length: "+
////                            longDesiredSeconds+" seconds.");
////                }
//            }else if(writeornot){
//                writeornot=false;
////                textView_filenotice.setText("File: \""+filename+"\" saved in : \""+path+
////                        "\".\r\nSampling rate is: "+SamplingRate+".");
//                viewText_time=MyLib.sDateFormat.format(now);
//                fileSaveNotice="File save time: "+viewText_time+
//                        ".\t\n"+counter+" datapoints in total.";
////                textView_time.setText(fileCreateNotice+"\r\n"+fileSaveNotice);
//
//            }
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
                           ButterSegA,ButterSegB,len[4],SavedPointNum);
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
                CurrentStepTime = long_deltaTime; // Outer Class
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
                            ButterProA, ButterProB, len[i / 3], SavedPointNum);
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
//                    textView_gyr.setText("Error3: Write error.");
                }
            }
        }
        private double UpdateExp(double OldExp1,double OldExp2,long num1,long num2){ //正常平均
            return (num1*OldExp1+num2*OldExp2)/(num1+num2);
        }
        private double UpdateExp_w(double OldExp1,double OldExp2,long num1,long num2){ //带权平均
            double a=3;//10为总权数
            double p2=a/((10-a)*num1+a*num2),p1=(10-a)*p2/a;
            return p1*num1*OldExp1+p2*num2*OldExp2;
        }
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy)
        {
        }
    }
    private void myLog(String tag,String message){
        Log.d(tag,message);
    }
    private class StepInfoHandler extends Handler{
        @Override
        public void handleMessage(Message msg){
            super.handleMessage(msg);
            Intent StepInfoIntent = new Intent("com.program.sensorgroup.watchout.StepInfoBroadcast");
            StepInfoIntent.putExtra("StepInfo",msg.obj.toString());
            sendBroadcast(StepInfoIntent);
        }
    }
    private void SendErrMessage(String Type, String Cause){
        String TempStr = Type + "-- " + Cause;
        ErrIntent.putExtra("ErrorInfo",TempStr);
        LocalBroadcastManager.getInstance(WatchOutService.this).sendBroadcast(ErrIntent);
        Log.d(tag,"Error Broadcast sent");
    }
}



