package com.program.sensorgroup.watchout;

import android.annotation.TargetApi;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.SystemClock;
import android.provider.Settings;
import android.support.annotation.NonNull;
import android.support.constraint.ConstraintLayout;
import android.support.design.widget.BottomNavigationView;
import android.support.design.widget.FloatingActionButton;
import android.support.design.widget.Snackbar;
import android.support.v4.content.LocalBroadcastManager;
import android.support.v7.app.AlertDialog;
import android.support.v7.widget.AppCompatCheckBox;
import android.text.Layout;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.support.design.widget.NavigationView;
import android.support.v4.view.GravityCompat;
import android.support.v4.widget.DrawerLayout;
import android.support.v7.app.ActionBarDrawerToggle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.CompoundButton;
import android.widget.EditText;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import com.wang.avi.AVLoadingIndicatorView;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.RandomAccessFile;
import java.io.StringWriter;
import java.io.Writer;
import java.text.Normalizer;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Set;
import java.util.UUID;

public class MainActivity extends AppCompatActivity
        implements NavigationView.OnNavigationItemSelectedListener,Thread.UncaughtExceptionHandler {

    private String UserName = "Xu J.C.";
    private String Rate = "Fastest";
    private String Brand = "";
    private int RateIndex = 0;
    public static final String ACTION_UPDATEUI = "com.program.sensorgroup.watchout.action.updateUI";
    public static final String ACTION_UPDATESTEP = "com.program.sensorgroup.watchout.action.updateStep";
    public static final String ACTION_ErrLog = "com.program.sensorgroup.watchout.action.ShowError";
    private boolean UseBT = false;
    private boolean LogFile = false;
    private int StepCount,StartStep;
    private boolean ServiceOpened;
    private boolean StartRecording = false;
    private SimpleDateFormat Formatter = new SimpleDateFormat("MM-dd HH:mm:ss");
    private SimpleDateFormat FormatterFileName = new SimpleDateFormat("MM-dd--HH-mm-ss");
    private String mytag = "Main";
    File path;
    File LogcatFile;
    //Bluetooth:
    private int DeviceNum;
    private boolean[] Connected = {false,false};
    private String[] Device_S = new String[2];
    private BluetoothDevice[] Devices = new BluetoothDevice[2];
    private Thread[] BTThread = new Thread[2];
    public static BluetoothSocket[] Socket = new BluetoothSocket[2];


    private String[] UserSet;
    private String[] RateSet;
    public static Handler mHandler;
    private WatchOutService.MainBinder myBinder;
    private ServiceBroadcastReceiver broadcastReceiver;
    private DataOutputStream GTOut;
    private File InfoFile;
    int[] EventID = new int[9];
    long FileCreateTime;
    int GTCounter;
    boolean RecGTWhenStart = false;
    boolean TrainRamp = false;
    boolean DownRampRecord = true;
    int FileCount = 0;
    private long exitTime = 0;

    private ConstraintLayout[] TLayout = new ConstraintLayout[3];
    private AppCompatCheckBox BTCheck;
    private EditText OtherTester;
    private TextView[] TDevice = new TextView[2];
    private AVLoadingIndicatorView[] LDevice = new AVLoadingIndicatorView[2];
    private AVLoadingIndicatorView LState;
    private TextView mTextMessage;
    private TextView TState,Logcat,TUser,TStepInfo,TQA,TStepCount,TGTState,TGTText,TRamp,TFileCount,TBrand;
    private Button ServiceB, StartRec;
    private BottomNavigationView.OnNavigationItemSelectedListener mOnNavigationItemSelectedListener
            = new BottomNavigationView.OnNavigationItemSelectedListener() {

        @Override
        public boolean onNavigationItemSelected(@NonNull MenuItem item) {
            switch (item.getItemId()) {
                case R.id.navigation_home:
                    mTextMessage.setText(R.string.title_home);
                    SwitchLayout(0);
                    return true;
                case R.id.navigation_dashboard:
                    mTextMessage.setText(R.string.title_Logcat);
                    SwitchLayout(1);
                    return true;
                case R.id.navigation_notifications:
                    mTextMessage.setText(R.string.title_Q_A);
                    SwitchLayout(2);
                    return true;
            }
            return false;
        }
    };
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
//        FloatingActionButton fab = (FloatingActionButton) findViewById(R.id.fab);
//        fab.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View view) {
//                Snackbar.make(view, "Replace with your own action", Snackbar.LENGTH_LONG)
//                        .setAction("Action", null).show();
//            }
//        });

        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        ActionBarDrawerToggle toggle = new ActionBarDrawerToggle(
                this, drawer, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close);
        drawer.addDrawerListener(toggle);
        toggle.syncState();

        NavigationView navigationView = (NavigationView) findViewById(R.id.nav_view);
        navigationView.setNavigationItemSelectedListener(this);
        mTextMessage = (TextView) findViewById(R.id.message);
        BottomNavigationView navigation = (BottomNavigationView) findViewById(R.id.navigation);
        navigation.setOnNavigationItemSelectedListener(mOnNavigationItemSelectedListener);
        // Above: Auto-Created
        mHandler = new Handler();
        TLayout[0] = (ConstraintLayout) findViewById(R.id.MainLayout);
        TLayout[1] = (ConstraintLayout) findViewById(R.id.LogcatLayout);
        TLayout[2] = (ConstraintLayout) findViewById(R.id.QALayout);
        Logcat = (TextView) findViewById(R.id.textView_Logcat);
        BTCheck = (AppCompatCheckBox) findViewById(R.id.BTCheck);
        OtherTester = (EditText) findViewById(R.id.EditText_tester);
        TDevice[0] = (TextView) findViewById(R.id.textView_Device1);
        TDevice[1] = (TextView) findViewById(R.id.textView_Device2);
        LDevice[0] = (AVLoadingIndicatorView) findViewById(R.id.avi_Device1);
        LDevice[1] = (AVLoadingIndicatorView) findViewById(R.id.avi_Device2);
        TState = (TextView) findViewById(R.id.textview_state);
        LState = (AVLoadingIndicatorView) findViewById(R.id.load_state);
        ServiceB = (Button) findViewById(R.id.ServiceButton);
        StartRec = (Button) findViewById(R.id.Rec_Start);
        TStepInfo = (TextView) findViewById(R.id.StepShow);
//        TQA = (TextView) findViewById(R.id.textView_QA);
        TStepCount = (TextView) findViewById(R.id.textView_StepCount);
        TGTState = (TextView) findViewById(R.id.Rec_State);
        TGTText = (TextView) findViewById(R.id.Rec_Text);
        TRamp = (TextView) findViewById(R.id.textView_Ramp);
        TFileCount = (TextView) findViewById(R.id.textView_CountTimes);
        TBrand = (TextView) findViewById(R.id.textView_Brand);
        UserSet = getResources().getStringArray(R.array.Testers);
        RateSet = getResources().getStringArray(R.array.samplingRates);
        Spinner UserSpinner = (Spinner) findViewById(R.id.TesterSpinner);
        Spinner RateSPinner = (Spinner) findViewById(R.id.ModeSelect);
        Brand = Build.BRAND;
        TBrand.setText(Brand);
        EventID[0] = R.id.Rec_Special;
        EventID[1] = R.id.Rec_Flat;
        EventID[2] = R.id.Rec_UpRamp;
        EventID[3] = R.id.Rec_DownRamp;
        EventID[4] = R.id.Rec_UpCurb;
        EventID[5] = R.id.Rec_DownCurb;
        EventID[6] = R.id.Rec_LTurn;
        EventID[7] = R.id.Rec_RTurn;
        EventID[8] = R.id.Rec_Stand;
        Logcat.setMovementMethod(ScrollingMovementMethod.getInstance());
        TStepInfo.setMovementMethod((ScrollingMovementMethod.getInstance()));
//        TQA.setMovementMethod(ScrollingMovementMethod.getInstance());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            String channelId = "state";
            String channelName = "State Info";
            int importance = NotificationManager.IMPORTANCE_HIGH;
            createNotificationChannel(channelId, channelName, importance);
        }
        // Broadcast Register
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_UPDATEUI);
        filter.addAction(ACTION_UPDATESTEP);
        filter.addAction(ACTION_ErrLog);
        broadcastReceiver = new ServiceBroadcastReceiver();
        // Set Global Exception Catch Handler
        Thread.setDefaultUncaughtExceptionHandler(this);
        LocalBroadcastManager.getInstance(this).registerReceiver(broadcastReceiver,filter);
//        registerReceiver(broadcastReceiver, filter);
        UserSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                if (i == UserSet.length - 1) {
                    OtherTester.setVisibility(View.VISIBLE);
                    UserName = "";
                }
                else{
                    if (OtherTester.getVisibility() == View.VISIBLE)
                        OtherTester.setVisibility(View.INVISIBLE);
                    UserName = UserSet[i];
                }
            }
            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {
            }
        });
        RateSPinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> adapterView, View view, int i, long l) {
                Rate = RateSet[i];
                RateIndex = i;
            }
            @Override
            public void onNothingSelected(AdapterView<?> adapterView) {

            }
        });
        BTCheck.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton compoundButton, boolean isCheck){
                if (isCheck){
                    UseBT = true;
                    TDevice[0].setText(R.string.Device1);
                    TDevice[1].setText(R.string.Device2);
                    BTConnect();

                }
                else{
                    UseBT = false;
                    for(int i = 0;i < DeviceNum;i++)
                        TDevice[i].setVisibility(View.INVISIBLE);
                    TState.setVisibility(View.GONE);
                    LState.setVisibility(View.GONE);
                }
            }
        });
        Date LogFileCreateTime = new Date();
        String NowerDate = MyLib.GetDate(LogFileCreateTime);
        path=new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                + File.separator + "WatchOut" + File.separator + "Log");
        File PathInfo = new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                + File.separator + "WatchOut" + File.separator);
        InfoFile = new File(PathInfo,"UserInfo.txt");
        try{
            DataInputStream InfoIn = new DataInputStream(new FileInputStream(InfoFile));
            String count = InfoIn.readLine();
            TStepCount.setText(count.substring(7));
            InfoIn.close();
        }
        catch (IOException e){
            e.printStackTrace();
            myLog(mytag,"Read Info File Error");
        }
        catch (Exception e){
            e.printStackTrace();
            myLog(mytag,"Other Exception" + e.getMessage());
        }
        if (!path.exists()){
            path.mkdirs();
        }
        String LogFileName = NowerDate + ".txt";
        LogcatFile = new File(path,LogFileName);
        String Content = "";
        if (LogcatFile.exists()){
            try{
                DataInputStream LogIn = new DataInputStream(new BufferedInputStream(new FileInputStream(LogcatFile)));
                int b = 0;
                while ((b=LogIn.read()) != -1){
                    Content += (char)b;
                }
                LogIn.close();
            }
            catch (IOException e){
                myLog(mytag,e.getMessage());
            }
            Logcat.append(Content);

        }
        myLog(mytag,"Create Activity Success");
    }
    @Override
    public void onBackPressed() {
        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        if (drawer.isDrawerOpen(GravityCompat.START)) {
            drawer.closeDrawer(GravityCompat.START);
        } else {
            if (Math.abs(System.currentTimeMillis() - exitTime) > 2000 ){
                Toast.makeText(MainActivity.this,
                        "再按一次退出", Toast.LENGTH_LONG).show();
                exitTime = System.currentTimeMillis();
            }
            else
                super.onBackPressed();
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }
        if (id == R.id.action_SaveLog){

            String Content = Logcat.getText().toString();
            try {
                DataOutputStream LogOut = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(LogcatFile)));
                LogOut.write(Content.getBytes());
                LogOut.close();
                Toast.makeText(MainActivity.this,
                        "LogFile Saved!", Toast.LENGTH_LONG).show();
            }
            catch (IOException e){
                Toast.makeText(MainActivity.this,
                        "Saving LogFile Failed!", Toast.LENGTH_LONG).show();
                e.printStackTrace();
            }
            return true;
        }
        if (id == R.id.action_RecordGT){
            RecGTWhenStart = !RecGTWhenStart;
            Toast.makeText(MainActivity.this,
                    "Rec GT When Start: "+ RecGTWhenStart, Toast.LENGTH_LONG).show();
        }
        if (id == R.id.action_RampTrain){
            TrainRamp = !TrainRamp;
            FileCount = 0;
            if (TrainRamp) {
                TRamp.setVisibility(View.VISIBLE);
                DownRampRecord = true;
                TRamp.setText(R.string.TextDownRamp);
            }
            else {
                TRamp.setVisibility(View.INVISIBLE);
            }
            TFileCount.setText("0");
            Toast.makeText(MainActivity.this,
                    "Train Ramp: "+ TrainRamp, Toast.LENGTH_LONG).show();
        }

        return super.onOptionsItemSelected(item);
    }

    @SuppressWarnings("StatementWithEmptyBody")
    @Override
    public boolean onNavigationItemSelected(MenuItem item) {
        // Handle navigation view item clicks here.
        int id = item.getItemId();

        if (id == R.id.nav_camera) {
            // Handle the camera action
        } else if (id == R.id.nav_gallery) {

        } else if (id == R.id.nav_slideshow) {

        } else if (id == R.id.nav_manage) {

        } else if (id == R.id.nav_share) {

        } else if (id == R.id.nav_send) {

        }

        DrawerLayout drawer = (DrawerLayout) findViewById(R.id.drawer_layout);
        drawer.closeDrawer(GravityCompat.START);
        return true;
    }

    private ServiceConnection connection = new ServiceConnection() {
        @Override
        public void onServiceConnected(ComponentName componentName, IBinder iBinder) {
            myBinder = (WatchOutService.MainBinder) iBinder;
//            StepCount = myBinder.GetSteps();
            if (RecGTWhenStart) {
                String GTFileName = myBinder.GetGTFileName();
                File Path = myBinder.GetPathDir();
                File GTFile = new File(Path, GTFileName);
                try {
                    GTOut = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(GTFile)));
                    myLog(mytag, "File Created!");
                } catch (IOException e) {
                    myLog(mytag, e.toString());
                }
                FileCreateTime = myBinder.GetFileCreateTime();
            }
        }

        @Override
        public void onServiceDisconnected(ComponentName componentName) {

        }
    };

    // Above: Auto-Create
    @Override
    public void onResume(){
        super.onResume();

    }

    @Override
    public void uncaughtException(final Thread thread, final Throwable ex) {
        //当有异常产生时执行该方法

        new Thread(new Runnable() {
            @Override
            public void run() {
                Looper.prepare();
                String Msg = "currentThread:"+Thread.currentThread()+"---thread:"+thread.getId()+"---ex:\n";
                String TLogcatContent = Logcat.getText().toString();

                Writer info = new StringWriter();
                PrintWriter printWriter = new PrintWriter(info);
                ex.printStackTrace(printWriter);
                Throwable cause = ex.getCause();
                while (cause != null) {
                    cause.printStackTrace(printWriter);
                    cause = cause.getCause();
                }
                String result = info.toString();
                printWriter.close();
                TLogcatContent += Formatter.format(new Date()) + "  " + Msg + '\n' + result + '\n';
                try {
                    DataOutputStream LogOut = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(LogcatFile)));
                    LogOut.write(TLogcatContent.getBytes());
                    LogOut.close();
                }
                catch (IOException e){
                    e.printStackTrace();
                }
                Toast.makeText(MainActivity.this,
                        "Logcat File Saved!", Toast.LENGTH_LONG).show();
                AlertDialog dialog = new AlertDialog.Builder(MainActivity.this)
                        .setTitle("FATAL EXCEPTION")//设置对话框的标题
                        .setMessage(ex.toString())//设置对话框的内容
                        //设置对话框的按钮
                        .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                            @Override
                            public void onClick(DialogInterface dialog, int which) {
                                dialog.dismiss();
                                android.os.Process.killProcess(android.os.Process.myPid());
                            }
                        }).create();
                dialog.show();
                Looper.loop();
            }
        }).start();
        SystemClock.sleep(2000);
        android.os.Process.killProcess(android.os.Process.myPid());
    }
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (ServiceOpened){
            unbindService(connection);
            Intent stopIntent = new Intent(this, WatchOutService.class);
            stopService(stopIntent);
        }
        // 注销广播
//        unregisterReceiver(broadcastReceiver);
        LocalBroadcastManager.getInstance(this).unregisterReceiver(broadcastReceiver);
    }
    /***********************
     * Broadcast Receiver
     * */
    private class ServiceBroadcastReceiver extends BroadcastReceiver{
        String tagS = "WatchOutService";
        @Override
        public void onReceive(Context context, Intent intent) {
            String TempStr;
            String DateStr = Formatter.format(new Date(System.currentTimeMillis())) + "  ";
            int StepCount_t;
            if (null != intent){
                String Act = intent.getAction();
                if (Act != null)
                    switch (Act){
                        case ACTION_UPDATEUI:
                            TempStr = intent.getStringExtra("StepInfo");
                            if (!TempStr.equals("")) {
                                int index = TempStr.indexOf(':');
                                String tempS = TempStr.substring(0,index); // StepCount From 1
                                try{
                                    StepCount_t = Integer.valueOf(tempS);
                                }
                                catch (Exception e){
                                    e.printStackTrace();
                                    StepCount_t = 0;
                                }
                                StepCount = StartStep + StepCount_t;
                                TStepCount.setText(StepCount+"");
                                if (StepCount_t % 2 == 0) {
                                    Log.d(tagS, "Step:" + TempStr);
                                    TStepInfo.append(TempStr);
                                    RollTextView(TStepInfo);
                                }
                                if (StepCount_t % 10 == 0) {
                                    String TagStr = DateStr + tagS + ":  " + TempStr;
                                    Logcat.append(TagStr);
                                    RollTextView(Logcat);
                                }
                            }
                            else{
                                Log.d(tagS,"NoStepInfo");
                            }
                        break;
                        case ACTION_ErrLog:
                            TempStr = intent.getStringExtra("ErrorInfo");
                            if (!TempStr.equals("")){
                                String TagStr = DateStr + tagS + ":  " + TempStr;
                            }
                            break;
                        default: Log.d(mytag,"Other Broadcast Received.");
                    }
            }
        }
    }
    /************************
     * StartService: Start Collecting data
     *
     * */
    public void Service(View view){
        String StartS = getResources().getString(R.string.button_showsensordata);
        String StopS = getResources().getString(R.string.button_StopService);
        if (ServiceB.getText().equals(StartS)){
            if (UserName.equals("")){
                UserName = OtherTester.getText().toString();
                if (UserName.equals("")) {
                    Toast.makeText(MainActivity.this,
                            "Please Enter UserName", Toast.LENGTH_LONG).show();
                    return;
                }
            }
            try {
                StartStep = Integer.valueOf(TStepCount.getText().toString());
            }
            catch (Exception e){
                e.printStackTrace();
                StartStep = 812;
            }
            Intent StartIntent = new Intent(this,WatchOutService.class);
            StartIntent.putExtra("UserName",UserName);
//            StartIntent.putExtra("StepCount",StepCount);
            StartIntent.putExtra("Connect1",Connected[0]);
            StartIntent.putExtra("Connect2",Connected[1]);
            StartIntent.putExtra("RateIndex",RateIndex);
            StartIntent.putExtra("SampleRate",Rate);
            StartIntent.putExtra("DeviceName1",Device_S[0]);
            StartIntent.putExtra("DeviceName2",Device_S[1]);
            StartIntent.putExtra("TrainRamp",TrainRamp);
            StartIntent.putExtra("DownRampRecord",DownRampRecord);
            Intent bindIntent = new Intent(this,WatchOutService.class);
            bindService(bindIntent,connection,BIND_ABOVE_CLIENT);
            startService(StartIntent);


            myLog(mytag,"Service Started!");
            if (RecGTWhenStart) {
                StartRecording = true;
                GTCounter = 0;

            }
            StartRec.setVisibility(View.INVISIBLE);
            ServiceB.setText(R.string.button_StopService);
            TStepInfo.setText(R.string.StepState);
            TStepInfo.scrollTo(0,0);
            ServiceOpened = true;

        }
        else{
            unbindService(connection);
            Intent stopIntent = new Intent(this, WatchOutService.class);
            stopService(stopIntent);
            myLog(mytag,"Service Stopped!");
            if (RecGTWhenStart) {
                try {
                    GTOut.close();
                    TGTText.setText("END");
                    Date now = new Date();
                    String s = "Done.\r\n" + " saved at " + MyLib.sDateFormat.format(now);
                    TGTState.setText(s);
                } catch (IOException e) {
                    e.printStackTrace();
                    myLog(mytag, "Close GT File Error:" + e.toString());
                }
                StartRecording = false;
                FileCreateTime = 0;

                StartRecording = false;
            }
            StartRec.setVisibility(View.VISIBLE);
            ServiceOpened = false;
            ServiceB.setText(R.string.button_showsensordata);
            if (TrainRamp){
                if (DownRampRecord){
                    TRamp.setText(R.string.TextUpRamp);
                }
                else{
                    TRamp.setText(R.string.TextDownRamp);
                    FileCount++;
                    TFileCount.setText(FileCount + "");
                }
                DownRampRecord = !DownRampRecord;
            }
            else{
                FileCount++;
                TFileCount.setText(FileCount + "");
            }
            try{
                DataOutputStream InfoOut = new DataOutputStream(new FileOutputStream(InfoFile));
                String Count_t = TStepCount.getText().toString();
                String FileIn = "Count: " + Count_t;
                InfoOut.write(FileIn.getBytes());
                InfoOut.close();
            }
            catch (IOException e){
                e.printStackTrace();
                myLog(mytag,"Save Info File Failed" + e.getMessage());
            }
        }
    }

    /***************************
     * BT Connect Thread
     *
     * */
    private void BTConnect(){
        int REQUEST_ENABLE_BT = 1;
        final String SensorName1="LookUp",SensorName2="LookUp2";
        BluetoothAdapter mBluetoothAdapter;
        Set<BluetoothDevice> pairedDevices;
        mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (mBluetoothAdapter==null){
            Toast.makeText(MainActivity.this,
                    "No Bluetooth", (Toast.LENGTH_SHORT)).show();
            return;
        }
        // Test if bluetooth is opened.
        if (!mBluetoothAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
            return;
        }
        pairedDevices = mBluetoothAdapter.getBondedDevices();
        // If there are paired devices
        if (pairedDevices.size() > 0) {
            // Loop through paired devices
            DeviceNum = 0;
            for (BluetoothDevice device : pairedDevices) {
                // Add the name and address to an array adapter to show in a ListView
                String DName = device.getName();
                myLog(mytag, "BT dev " + DName + " Found !");
                if (DName.equals(SensorName1) || DName.equals(SensorName2)) {
                    if (Device_S[DeviceNum] == null || !Device_S[DeviceNum].equals(DName)){
                        Device_S[DeviceNum] = DName;
                        Devices[DeviceNum] = device;
                        Connected[DeviceNum] = false;
                    }
                    DeviceNum++;
                    if (DeviceNum == 2) break;
                }
            }
        }
        if (DeviceNum == 0){
            AlertDialog dialog = new AlertDialog.Builder(this)
                    .setTitle("无蓝牙设备配对")//设置对话框的标题
                    .setMessage("是否前往蓝牙设置界面？")//设置对话框的内容
                    //设置对话框的按钮
                    .setNegativeButton("取消", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            Toast.makeText(MainActivity.this,
                                    "无蓝牙设备", (Toast.LENGTH_SHORT)).show();
                            dialog.dismiss();
                        }
                    })
                    .setPositiveButton("确定", new DialogInterface.OnClickListener() {
                        @Override
                        public void onClick(DialogInterface dialog, int which) {
                            startActivity(new Intent(Settings.ACTION_BLUETOOTH_SETTINGS));
                            dialog.dismiss();
                        }
                    }).create();
            dialog.show();
        }
        else{
            for (int i = 0;i < DeviceNum;i++)
                BTThread[i] = new ConnTestThread(Devices[i],i);
        }

    }
    private class ConnTestThread extends Thread{
        private int DI;
        private BluetoothDevice device;
        public ConnTestThread(BluetoothDevice deviceIn,int DeviceNoIn){
            device = deviceIn;
            DI = DeviceNoIn;
            this.start();
        }
        public void run(){
            BluetoothSocket socket = null;
            String TempStr;
            OutputStream BTOUT;
            PostToMainThread(TState,"Connect to BT");
            SetVisiable(TState,View.VISIBLE);
            SetVisiable(LState,View.VISIBLE);
            AviCtrl(true);
            try{
                if (Connected[DI]) {
                    socket = Socket[DI];
                    Connected[DI] = false;
                }
                else socket = device.createInsecureRfcommSocketToServiceRecord(UUID.fromString(MyLib.MY_UUID));
                SetVisiable(TDevice[DI],View.VISIBLE);
                Thread.sleep(500);
                if (!socket.isConnected())
                    socket.connect();
                BTOUT = socket.getOutputStream();
                BTOUT.write('0');
//                BTOUT.close();
//                socket.close();
                Connected[DI] = true;
                TempStr = "▷Device" + (DI+1) + ": √  ";
                PostToMainThread(TDevice[DI],TempStr);

                Socket[DI] = socket;
            }
            catch (IOException E){
                if (socket == null)
                    PostToMainThread(TState, " : Failed Create Socket");
//                else if (!socket.isConnected())
//                    PostToMainThread(TState,"Conn Failed, Try Again");

            }
            catch (Exception e){
                e.printStackTrace();
            }
            finally {
                AviCtrl(false);
                if (DI == DeviceNum-1){
                    if (DI != 0)
                        try {
                            BTThread[0].join();
                        }
                        catch (InterruptedException e){
                            e.printStackTrace();
                        }
                    SetVisiable(LState,View.GONE);
                    SetVisiable(TState,View.GONE);

                }
            }


        }
        private void SetVisiable(final View view,final int Show){
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    if (view.getVisibility() != Show)
                        view.setVisibility(Show);
                    // Show Must be View.VISIBLE\INVISIBLE\GONE
                }
            });
        }
        private void PostToMainThread(final TextView textview,final String message){
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    textview.setText(message);
                }
            });//
        }
        private void AviCtrl(final boolean Show){
            mHandler.post(new Runnable() {
                @Override
                public void run() {
                    if (Show)
                        LDevice[DI].smoothToShow();
                    else LDevice[DI].smoothToHide();
                }
            });//
        }
    }
    private void SwitchLayout(int Num){
        if ((Num > 2)||(Num < 0))return;
        for (int i = 0; i < 3;i++){
            if (i == Num) {
                if (TLayout[i].getVisibility() == View.INVISIBLE)
                    TLayout[i].setVisibility(View.VISIBLE);
            }
            else{
                if (TLayout[i].getVisibility() == View.VISIBLE)
                    TLayout[i].setVisibility(View.INVISIBLE);
            }
        }
        if (Num == 1) RollTextView(Logcat);
    }
    private void myLog(String tag,String message){
        Log.d(tag,message);
        String TempStr = Formatter.format(new Date(System.currentTimeMillis())) + "  ";
        Logcat.append(TempStr + tag + ": " + message+'\n');
    }
    @TargetApi(Build.VERSION_CODES.O)
    private void createNotificationChannel(String channelId, String channelName, int importance) {
        NotificationChannel channel = new NotificationChannel(channelId, channelName, importance);
        NotificationManager notificationManager = (NotificationManager) getSystemService(
                NOTIFICATION_SERVICE);
        notificationManager.createNotificationChannel(channel);
    }

    /*******************
     * Tester: for test
     * */
    public void TestOnClick(View view){
        Intent StepInfoIntent = new Intent();
    }

    /**********************
     * Write GroundTruth
     *
     * ********************/
    public void RecordEvent(View view){
        String[] Events = {"Special","_Flat","↗Ramp","↙Ramp","↑Curb","↓Curb","Turn ▜","▛ Turn","Stand"};
        int ViewID = view.getId();
        long NowerTime;
        if (!StartRecording){
            Toast.makeText(MainActivity.this,
                    "Please Start Record First!", Toast.LENGTH_LONG).show();
            return;
        }
        if (ServiceOpened)
            NowerTime = myBinder.GetNowerTime();
        else
            NowerTime = System.currentTimeMillis() - FileCreateTime;
        while(NowerTime<=0)NowerTime+=86400000;
        for(int i = 0;i < 9;i++){
            if (EventID[i] == ViewID){
                GTCounter++;
                String TempStr = MyLib.millisecFormat.format(NowerTime)+"\t"+i+"\r\n";
                String s2="RECORDING, "+GTCounter+" lines in total\r\n"+
                        "Now time: "+MyLib.sDateFormat.format(NowerTime);
                try{
                    GTOut.write(TempStr.getBytes());
                    TGTText.setText(Events[i]);
                    TGTState.setText(s2);
                }
                catch (IOException e){
                    TGTState.setText("Wrong Recording!");
                    myLog(mytag,"GTFile: " + e.toString());
                }
            }
        }
    }

    /********************
     * Record
     * */
    public void Record(View view){
        if (view.getId() == R.id.Rec_Start){
            if (!StartRecording){
                if (UserName.equals("")){
                    UserName = OtherTester.getText().toString();
                    if (UserName.equals("")) {
                        Toast.makeText(MainActivity.this,
                                "Please Enter UserName", Toast.LENGTH_LONG).show();
                        return;
                    }
                }
                FileCreateTime = System.currentTimeMillis();
                String GTFileName = "GT" + MyLib.sDateFormat.format(FileCreateTime) + "-" + UserName + ".txt";
                File GTpath=new File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS)
                        + File.separator + "WatchOut" + File.separator +MyLib.GetDate(new Date()));
                if (!GTpath.exists()){
                    GTpath.mkdir();
                }
                File GTFile = new File(GTpath,GTFileName);
                StartRecording = true;
                try {
                    GTOut = new DataOutputStream(new BufferedOutputStream(new FileOutputStream(GTFile)));
                    TGTText.setText(R.string.Rec_Start);
                }
                catch (IOException e){
                    e.printStackTrace();
                    StartRecording = false;
                    myLog(mytag,"GTFile Created Error:" + e.toString());
                    Toast.makeText(MainActivity.this,
                            "Failed", (Toast.LENGTH_SHORT)).show();
                }
            }
        }
        else{
            if (StartRecording){
                FileCreateTime = 0;
                try{
                    GTOut.close();
                    TGTText.setText("END");
                    Date now=new Date();
                    String s="Done.\r\n" + " saved at "+MyLib.sDateFormat.format(now);
                    TGTState.setText(s);
                    GTCounter = 0;
                }
                catch (IOException e){
                    e.printStackTrace();
                    myLog(mytag,"Close GT File Error:" + e.toString());
                }
                StartRecording = false;
            }
        }
    }
    /**********************
     * Roll TextView
     * ********************/
    private void RollTextView(TextView View){
        int offset = View.getLineCount()*View.getLineHeight();
        if (offset > View.getHeight()) // Auto Scroll to the last line
            View.scrollTo(0,offset - View.getHeight());
    }
}


