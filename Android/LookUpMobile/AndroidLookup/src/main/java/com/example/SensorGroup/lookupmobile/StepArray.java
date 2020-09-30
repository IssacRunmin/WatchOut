package com.example.SensorGroup.lookupmobile;

import android.os.Handler;
import android.widget.TextView;

import java.io.DataInputStream;
import java.io.File;
import java.io.IOException;
import java.text.DecimalFormat;

import static com.example.SensorGroup.lookupmobile.SensorActivity.textView_filenotice;

/**
 * Created by IssacRunmin on 18/4/25.
 * Changed by IssacRunmin on 18/4/25-15:23;
 */

public class StepArray {
    protected static int MaxStepsNum = 600; //the max Steps that logs
    protected static int CurrentStep = 0;
    protected static boolean Circle = false;
    protected static double StepDurationMean = 0;
    protected static int HMMOutState[] = new int[MaxStepsNum];
    protected static int HMMSeq[] = new int[MaxStepsNum];
    protected static int Turned = 0;
    public static StepData Steps[] = new StepData[MaxStepsNum];
    public static int LastStepLog = 1;
    static private int FeatureNum = 23;
    private static final int SVM_Simple_Classifier[] = {2,3,8};
    private static final int SVM_Advanced_Classifier[] = {1,2,3,8};
    public static final int SVM_NEEDED[] = {1,2,3,8};
    private static double SVM_Bias_S;
    private static int Feature_Len_S = FeatureNum * SVM_Simple_Classifier.length;
    private static double SVM_Beta_S[] = new double[Feature_Len_S];
    private static double SVM_Mu_S[] = new double[Feature_Len_S];
    private static double SVM_Sigma_S[] = new double[Feature_Len_S];
    private static double SVM_Bias_A;
    private static int Feature_Len_A = FeatureNum * SVM_Advanced_Classifier.length;
    private static double SVM_Beta_A[] = new double[Feature_Len_A];
    private static double SVM_Mu_A[] = new double[Feature_Len_A];
    private static double SVM_Sigma_A[] = new double[Feature_Len_A];
    private static final int HMM_States_Num = MyLib.HMM_States.length,
            HMM_Events_Num = MyLib.HMM_Events.length;
    private static double HMM_Trans[][] = new double[HMM_States_Num][HMM_States_Num];
    private static double HMM_Emit[][] = new double[HMM_States_Num][HMM_Events_Num];
    final protected static double HMM_Pi[] = {1, 0, 0, 0, 0, 0};
    public static boolean PreformML = false;
    static Handler mHandler;
    public static void init(Handler _handler){mHandler=_handler;}

    public static synchronized void LogData(int ToStep){
        if (ToStep < LastStepLog)
            return;
        DecimalFormat DataFormat = MyLib.dataFormat;
        String TempString;
        String OutString;
        try {
            while (ToStep >= LastStepLog) {
                StepData LogStep = Steps[LastStepLog];
                OutString = "";
                OutString += LastStepLog + '\t';
                OutString += LogStep.Event + '\t';
                OutString += DataFormat.format(LogStep.EndTime) + "\t";
                OutString += DataFormat.format(LogStep.AccMagEndPeak) + "\t";
                OutString += DataFormat.format(LogStep.AccMagThreshold) + "\t";
//                for (int i = 0; i < Step.FeautreNum; i++) {
//                    TempString = DataFormat.format(LogStep.Features[0][i]) + "\t";
//                    OutString += TempString;
//                }
                OutString += "\r\n";
                SensorActivity.StepDataOut.write((OutString.toString()).getBytes());
                LastStepLog++;
            }
        }
        catch (IOException e){
            e.printStackTrace();
            textView_filenotice.setText("Err: StepData file Write");
        }
    }
    protected synchronized static void HMM(int count){
        int Observation[];
//        for(int i = 0;i < ToStep;i++)
//            Observation[i] = StepArray.HMMSeq[i];
        int ToStep = count % MaxStepsNum;
        if (!Circle) {
            Observation = new int[ToStep];
            System.arraycopy(HMMSeq, 0, Observation, 0, ToStep);
        }
        else{
            Observation = new int[MaxStepsNum];
            System.arraycopy(HMMSeq, ToStep+1, Observation, 0, MaxStepsNum - ToStep);
            System.arraycopy(HMMSeq, 0,Observation,MaxStepsNum - ToStep,ToStep);
        }
        HMMOutState = Viterbi.compute(Observation, MyLib.HMM_States, HMM_Pi, HMM_Trans, HMM_Emit);
        int i;
        final int templen=5;
        int[] hmmseq_templen=new int[templen];
        int[] hmmoutstate_templen=new int[templen];

        for(i=0;i<templen;i++){
            hmmseq_templen[i]=(LastStepLog-i+MaxStepsNum)%MaxStepsNum;
            hmmoutstate_templen[i]=(LastStepLog>=MaxStepsNum)?MaxStepsNum-1-i:LastStepLog-i;
        }
        String s="";
        s+="Seq:  \t\t States:\r\n";
        for(i=0;i<templen;i++) {
            s += MyLib.EVENT[HMMSeq[hmmseq_templen[i]]] + "\t\t";
            s += MyLib.STATE[HMMOutState[hmmoutstate_templen[i]]] + "\r\n";
        }
        PostToMainThread(SensorActivity.accelerometerView,s);
    }
    private static void PostToMainThread(final TextView textview, final String message){
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                textview.setText(message);
            }
        });
    }
    protected static void SetStand(int StepCount){
        int LastStepCount = (StepCount - 1 + MaxStepsNum) % MaxStepsNum;
        if (Steps[LastStepCount] == null){
            StepData LastStep = new StepData(0);
            LastStep.Event = MyLib.EVENT_STAND;
//            LastStep.State = 0;
            LastStep.AccMagEndPeak=0;
            LastStep.AzimuthMean = 0;
            Steps[StepCount] = LastStep;
        }
        else {
            StepData LastStep = Steps[LastStepCount];
            LastStep.Event = MyLib.EVENT_STAND;
            Steps[StepCount] = LastStep;
        }
    }
    protected static void ReadSVMParameters(DataInputStream SVMIn) throws IOException{
        int i,j;
        SVM_Bias_S = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_S;i++)
            SVM_Beta_S[i] = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_S;i++)
            SVM_Mu_S[i] = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_S;i++)
            SVM_Sigma_S[i] = SVMIn.readDouble();
        SVM_Bias_A = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_A;i++)
            SVM_Beta_A[i] = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_A;i++)
            SVM_Mu_A[i] = SVMIn.readDouble();
        for(i = 0;i < Feature_Len_A;i++)
            SVM_Sigma_A[i] = SVMIn.readDouble();
        for(j = 0;j < HMM_States_Num;j++)
            for(i = 0;i < HMM_States_Num;i++)
                HMM_Trans[i][j] = SVMIn.readDouble();
        for(j = 0;j < HMM_Events_Num;j++)
            for(i = 0;i < HMM_States_Num;i++)
                HMM_Emit[i][j] = SVMIn.readDouble();
        PreformML = true;
    }

    protected static int SVM(double Feautres[][]){
        if (!PreformML) return 0;
        double FeatureCombine[] = new double[Feature_Len_S];
        int i;
        double Score;
        for(i = 0;i < SVM_Simple_Classifier.length;i++)
            System.arraycopy(Feautres[SVM_Simple_Classifier[i]],0,FeatureCombine, i*FeatureNum,FeatureNum);
        Score = 0;
        for(i = 0;i < FeatureCombine.length ;i++)
            Score += (FeatureCombine[i] - SVM_Mu_S[i]) / SVM_Sigma_S[i] * SVM_Beta_S[i];
        Score += SVM_Bias_S;
        if (Score < 0) return MyLib.EVENT_FLAT;
        else{
            FeatureCombine = new double[FeatureNum * SVM_Advanced_Classifier.length];
            for(i = 0;i < SVM_Advanced_Classifier.length;i++)
                System.arraycopy(Feautres[SVM_Advanced_Classifier[i]],0,FeatureCombine, i*FeatureNum,FeatureNum);
            Score = 0;
            for(i = 0;i < FeatureCombine.length ;i++)
                Score += (FeatureCombine[i] - SVM_Mu_A[i]) / SVM_Sigma_A[i] * SVM_Beta_A[i];
            Score += SVM_Bias_A;
            if (Score < 0) return MyLib.EVENT_UPRAMP;
            else return MyLib.EVENT_DOWNRAMP;
        }
    }

}
