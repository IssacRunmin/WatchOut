package com.program.sensorgroup.watchout;

import android.content.Intent;
import android.os.Message;
import android.util.Log;
import android.os.Handler;
import java.util.Arrays;


import static java.lang.Double.NaN;

/**
 * Created by lijw on 2018/1/30.
 * Changed by ORM on 2018/4/25-01:17
 */
//change 53
public class Step extends Thread {
    protected static int FeatureNum = 24;
    private int StartStep = 6;
    private static double TurnThreshold = 68;
    private static double CurbWeight[] = new double[]{0.18,0.32,0.25,0,0.11,0.14};
    private static double CurbThreshold = 1.56;
    private static String tag = "StepProcess";
    private int n;
    final private double[][] Data;
    private double Time[];
    private double Sumt;
    private StepData AStep;
    private int StepCount,CircleStep;
    private static Handler myHandler;

    /*final private int MEAN=1;
    final public int DURATION=2;
    final public int FFT_PEAK1=3;
    final public int FFT_PEAK2=4;
    final public int MEANVALUE=5;
    final public int MAX=6;
    final public int MIN=7;
    final public int PRCTILE_90=8;
    final public int PRCTILE_10=9;
    final public int RANGE=10;
    final public int STD=11;
    final public int SKEWNESS=12;
    final public int KURTOSIS=13;
    final public int ENTROPY=14;
    final public int CV=15;*/

    public Step(final double[][] DataIn, int Ending, int length, int count, long[] TimeSeries,
                double MagMean, double ButterPeak, Handler HandleIn){
        // They should be calculated in for(int j).
//        super();
        if (myHandler == null)
            myHandler = HandleIn;
        int ArrayLen = 500;
        int ClassifierNum = StepData.ClassifierNum;
        int Starting = (Ending - length + 1 + ArrayLen) % ArrayLen;
        int i;
        double YawValue;
        double temp;
        int IndexTemp;
        Time = new double[length + 1];
        Data  = new double[StepData.ClassifierNum][length + 1];
        //temp = 0;
        //for (i = 0; i < 3; i++)
        //    temp += DataIn[i][Ending] * DataIn[i][Ending];
        temp = ButterPeak - MagMean; // the Acc Magnitude peak of this step.

        AStep = new StepData(temp);

        if (count >= StepArray.MaxStepsNum){
            StepArray.Circle = true;
            StepArray.CurrentStep = CircleStep = count % StepArray.MaxStepsNum;
        }
        else StepArray.CurrentStep = CircleStep = count;
        this.StepCount = count;
        AStep.EndTime = (double)TimeSeries[Ending] /1000;
        StepArray.Steps[CircleStep] = AStep;

        // Calculate Duration
        temp = TimeSeries[Ending] - TimeSeries[Starting]; // Duration
        if (!StepArray.Circle) {
            if (count == 1) {
                StepArray.StepDurationMean = temp;
            } else {
                temp = (StepArray.StepDurationMean * (count - 1) + temp) / count;
                StepArray.StepDurationMean = temp;
            }
        }
        else{
            temp = (StepArray.StepDurationMean * ((count - 1) % StepArray.MaxStepsNum) + temp) / count;
            StepArray.StepDurationMean = temp;
        }
        Sumt = 0;
        IndexTemp = Starting;
        YawValue = 0;
        for (i = 0; i < length; i++) {
            temp = TimeSeries[IndexTemp]; // Time Point, ms
            YawValue += DataIn[6][IndexTemp];
            IndexTemp = (IndexTemp + 1) % ArrayLen;
            Sumt += temp / 1000;
            Time[i] = temp / 1000;  // Time Point, s
        }
        YawValue = YawValue / length;
        AStep.AzimuthMean = YawValue;
//        Copy array from DataIn

        for (i = 0; i < ClassifierNum; i++) {
//                System.arraycopy(DataIn[i], Starting, Data[i], 0, ArrayLen - Starting);
//                System.arraycopy(DataIn[i], 0, Data[i], ArrayLen - Starting, Ending + 1);
            IndexTemp = Starting;
            for (int j = 0; j < length; j++) {
                Data[i][j] = DataIn[i][IndexTemp];
                IndexTemp = (IndexTemp + 1) % ArrayLen;
            }
        }
        n = length;
//        if (Data[7][length - 1] == DataIn[7][Ending]) ;// for testing

    }
    public void run(){
//feature extraction **when step.start()
        double Sum1,Sum2,Sum3,Sum4, SumCov,Sumt1,Sumt2,SumD,Sum_Log;
        double[][] Features = new double[StepData.ClassifierNum][FeatureNum];
        double temp,tempT,tempT1,Peak1,Peak2,Std_N,Mean;
        int count = this.CircleStep;
        int MaxStep = StepArray.MaxStepsNum;
        double avgTime = Sumt / n;
        int EventNum,StateNum;
        int DFTLenHalf;
        int i,j;
        int[] Count_ = new int[6];
        if (StepCount > 3) {
            if (StepArray.Circle)
                for (i = 0; i < 6; i++)
                    Count_[i] = (count - i + MaxStep) % MaxStep;
            else for (i = 0; i < 6; i++)
                Count_[i] = count - i;
        }
        if ((count > this.StartStep) || (StepArray.Circle)) {

            if (StepArray.Turned > 0)
                StepArray.Turned--;
            temp = 0; // for AccMagPeak Threshold Calculate
            for(i = 0;i <= 5;i++)
                if (!StepArray.Circle)
                    temp += CurbWeight[i] * StepArray.Steps[count - 5 + i].AccMagEndPeak;// Weighted
                else
                    temp += CurbWeight[i] * StepArray.Steps[(count - 5 + i + MaxStep) % MaxStep].AccMagEndPeak;// Weighted
            temp = temp * CurbThreshold;// Threshold of Curb, Acc magnitude
            Log.d(tag, (StepCount-2) + ":"  + temp);
            StepArray.Steps[Count_[2]].AccMagThreshold = temp;
            if (temp < StepArray.Steps[Count_[2]].AccMagEndPeak){
                EventNum = MyLib.EVENT_UPCURB;
                if (StepArray.Steps[Count_[1]].Event < EventNum) {
                    StepArray.Steps[Count_[1]].Event = EventNum;
                    StepArray.HMMSeq[Count_[1]] = EventNum;
                }
                if (StepArray.Steps[Count_[2]].Event < EventNum) {
                    StepArray.Steps[Count_[2]].Event = EventNum;
                    StepArray.HMMSeq[Count_[2]] = EventNum;
                }
            }
            else if (StepArray.Turned == 0) {
                temp = StepArray.Steps[count].AzimuthMean;// mean Azimuth of the steps
                tempT = StepArray.Steps[Count_[3]].AzimuthMean + StepArray.Steps[Count_[4]].AzimuthMean;
                tempT = tempT /2;// mean Azimuth of the previous 3-4 steps
                if (Math.abs(tempT - temp) > TurnThreshold){
                    EventNum = MyLib.EVENT_TURN;
                    if (StepArray.Steps[Count_[1]].Event < EventNum) {
                        StepArray.Steps[Count_[1]].Event = EventNum;
                        StepArray.HMMSeq[Count_[1]] = EventNum;
                    }
                    if (StepArray.Steps[Count_[2]].Event < EventNum) {
                        StepArray.Steps[Count_[2]].Event = EventNum;
                        StepArray.HMMSeq[Count_[2]] = EventNum;
                    }
                    StepArray.Turned = 2;
                }
            }
        }

        for(j = 0;j < StepArray.SVM_NEEDED.length;j++){
            i = StepArray.SVM_NEEDED[j];
            Sum1 = 0;Sum2 = 0;Sum3 = 0;Sum4 = 0;SumCov = 0; Sumt1 = 0; Sumt2 = 0; SumD = 0;
            Features[i][0]=(Data[i][n-1]+Data[i][0])/2.0;            // 1. Avg of peak value;
            Features[i][1]=Time[n-1] - Time[0];                      // 2. Time duration of this step
                Complex[] DFTIn = new Complex[n];
                for(j = 0;j < n;j++){
                    DFTIn[j] = new Complex(Data[i][j],0);
                    temp = Data[i][j];
                    Sum1 += temp;
                    Sum2 += temp * temp;
                    Sum3 += temp * temp * temp;
                    Sum4 += temp * temp * temp * temp;
                    tempT = Time[j] - avgTime; // Y - E(Y)
                    Sumt1 += tempT;
                    Sumt2 += tempT * tempT;
                    tempT *= temp;     // X(Y-E(Y))
                    SumCov += tempT;
                }
                Complex[] DFTOut = DFT.dft(DFTIn,n - 1);
                DFTLenHalf = n / 2;
                Peak1 = 0;
                Peak2 = 0;
                tempT = DFTOut[0].abs() * Math.log(DFTOut[0].abs()); // For calculating the sum of xi * log(xi)
                Sum_Log = tempT;
                for(j = 1;j < DFTLenHalf;j++){
                    temp = DFTOut[j].abs();
                    if ((temp > DFTOut[j-1].abs()) && (temp > DFTOut[j + 1].abs())){
                        if (temp > Peak1){
                            Peak2 = Peak1;
                            Peak1 = temp;
                        }
                        else if(temp > Peak2)
                            Peak2 = temp;
                    }
                    tempT += temp * Math.log(temp);
                    Sum_Log += temp;
                }
                if (Peak1 == 0) Peak1 = NaN;
                if (Peak2 == 0) Peak2 = NaN;
            Features[i][2] = Peak1;											//3. FFT Largest Peak
            Features[i][3] = Peak2;											//4. FFT Second Peak
                Arrays.sort(Data[i], 0, n);//from start to end
            Features[i][4] = Sum1 / n;										// 5. Mean value
                Mean = Features[i][4];
            Features[i][5] = Data[i][n - 1]; 								// 6. Max value of the step
            Features[i][6] = Data[i][0];									// 7. Min
            Features[i][7] = MyLib.prctile(Data[i],n,90);				// 8. max 90%
            Features[i][8] = MyLib.prctile(Data[i],n,10);				// 9. min 10%
            Features[i][9] = Features[i][5]-Features[i][6]; 				// 10. range : Max - Min
            Features[i][10]= Math.sqrt((Sum2 / n - Mean * Mean) * n/(n-1));	// 11. Std: sqrt(E(x^2)-E(x)^2)
                Std_N = Features[i][10]* Math.sqrt((double)(n - 1) / n);
                temp = (Sum3 - 3 * Sum2 * Mean
                        + 3 * Sum1 * Mean * Mean
                        - n * Mean * Mean * Mean) / n;
            Features[i][11]= temp / (Std_N * Std_N * Std_N);				// 12. skewness;
                temp = (Sum4 - 4 * Sum3 * Mean
                        + 6 * Sum2 * Mean * Mean
                        - 4 * Sum1 * Mean * Mean * Mean
                        + n * Mean * Mean * Mean * Mean) / n;
                // E{[X-E(X)]^4} = Σ{X^4 - 4X^3μ +6X^2μ^2 * 4Xμ^3 +μ^4} / n;
            // Kurtosis(X) = m4/m2^2 = E{[X-E(X)]^4}/(σ^4) ;
            Features[i][12]= temp / (Std_N * Std_N * Std_N * Std_N);		// 13. kurtosis
            Features[i][13]= -(tempT / Sum_Log - Math.log(Sum_Log));		// 14. entropy
                        // = {Σ(i=0,[n/2])xi * log(xi)}/ Σ(i=0,[n/2])xi - log(Σ(i=0,[n/2])xi)
            Features[i][14]= 100 * Features[i][10] / Features[i][4];		// 15. CV: Std/Mean*100
            Features[i][15]= MyLib.prctile(Data[i],n,50);				// 16. Median
            Features[i][16]= MyLib.prctile(Data[i],n,75);	 			// 17. Q3
            Features[i][17]= MyLib.prctile(Data[i],n,25);	 			// 18. Q1
            Features[i][18]= Features[i][16] - Features[i][17];				// 19. Q3 - Q1
            Features[i][19]= 0.25 * Features[i][17] + 0.5 * Features[i][15] + 0.25 * Features[i][16];
															// 20. SM: 1/4 * Q1 + 1/2 * Median + 1/4 * Q3;
            Features[i][20]= Sum2 / n;										// 21. E(x^2)
            Features[i][21]= SumCov / (n - 1);								// 22. Cov(X,(Y - E(Y)))
                temp = Sumt1 / n; // E(Y-E(Y)) = E(T)
                tempT = Math.sqrt((Sumt2 / n - temp * temp) * n / (n - 1)); // Std(Y-E(Y))
            Features[i][22]= Features[i][21] / (Features[i][10] * tempT);	// 23. Coefficient = Cov()/Std(X)Std(T)
                for(j = 0;j < n;j++){
                    temp = Data[i][j] - Features[i][4]; // X - E(X)
                    tempT1 = Time[j] - avgTime; // Y - E(Y)
                    SumD += temp * tempT1;
                }
            Features[i][23]= SumD / (n * (Features[i][10] * tempT));		// 24.

        }
        /* SVM Here*/
        if (StepArray.PreformML)
        EventNum = StepArray.SVM(Features);
        else EventNum = MyLib.EVENT_FLAT;
        if (StepArray.Steps[count].Event < EventNum) {
            StepArray.Steps[count].Event = EventNum;
            StepArray.HMMSeq[count] = EventNum;
        }

//        AStep.Features = Features;
//        StepArray.Steps[count].Features = AStep.Features;
        if (count > 3) {
            StepArray.LogData(StepCount - 2);

        }
        StateNum = 0;
        if ((StepCount > 10) & StepArray.PreformML)
            StateNum = StepArray.HMM(StepCount);
        StepArray.Steps[count].State = StateNum;
        if (StepCount > 3) {
            String TempStr = (StepCount - 2) + ": " + MyLib.EVENT[StepArray.Steps[Count_[2]].Event]
                    + " - " + MyLib.STATE[StepArray.Steps[Count_[2]].State] + '\n';
            Message message = new Message();
            message.obj = TempStr;
            myHandler.sendMessage(message);
            Log.d(tag, TempStr);
        }
    }
}
