package com.example.SensorGroup.lookupmobile;

import android.content.Intent;
import android.graphics.ColorSpace;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.view.View;
import android.widget.AdapterView;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.Spinner;
import android.widget.Toast;

import java.io.File;
import java.util.List;

public class MainActivity extends AppCompatActivity {
    public static final String SAMPLING_RATE="com.example.lijw.myfirstapp.RATE";
    public static final String SECONDS="com.example.lijw.myfirstapp.SECONDS";
    public static final String PPP="com.example.lijw.myfirstapp.PPP";
    static final String TESTER="com.example.lijw.groundtruthrecord.TESTER";
    static final String CHOICE="com.example.lijw.groundtruthrecord.CHOICE";
    private int testerChoice,PPPos;
    private Spinner spinner1,spinner2;
    private String[] stringsRates;




    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        spinner1=(Spinner)findViewById(R.id.spinner);
        spinner2=(Spinner)findViewById(R.id.TesterSpinner);
        final String[] StringsTesters = getResources().getStringArray(R.array.Testers);
        stringsRates = getResources().getStringArray(R.array.samplingRates);
        spinner1.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {
                PPPos = pos;
                String s = "\"" + stringsRates[pos] + "\" chosen.";
                Toast.makeText(com.example.SensorGroup.lookupmobile.MainActivity.this,
                        s, Toast.LENGTH_LONG).show();
            }
            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });
        spinner2.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override
            public void onItemSelected(AdapterView<?> parent, View view, int pos, long id) {
                testerChoice=pos;
                Toast.makeText(MainActivity.this,
                        "\""+StringsTesters[pos]+"\" chosen.",Toast.LENGTH_LONG).show();
            }
            @Override
            public void onNothingSelected(AdapterView<?> parent) {}
        });
    }
    public void showSensorData(View view){
        Intent intent=new Intent(this, com.example.SensorGroup.lookupmobile.SensorActivity.class);
        EditText textview_seconds=(EditText) findViewById(R.id.textView_seconds);
        String RateString=stringsRates[PPPos];
        String seconds=textview_seconds.getText().toString();
        EditText textview_tester=(EditText) findViewById(R.id.EditText_tester);
        String TesterName=textview_tester.getText().toString();
        intent.putExtra(TESTER,TesterName);
        intent.putExtra(CHOICE,testerChoice);
        intent.putExtra(SAMPLING_RATE,RateString);
        intent.putExtra(SECONDS,seconds);
        intent.putExtra(PPP,PPPos);
        startActivity(intent);

    }
}

