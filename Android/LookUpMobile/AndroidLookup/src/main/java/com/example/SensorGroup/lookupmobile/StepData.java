package com.example.SensorGroup.lookupmobile;

/**
 * Created by IssacRunmin on 18/4/23 .
 * Changed by IssacRunmin on 18/4/26-10.22
 */

public class StepData {
    static int ClassifierNum = 9;
    public double AzimuthMean;
    public double AccMagEndPeak;
//    public int State = 0; // 1: Flat; 2: UpRamp; 3: DownRamp; 4: Turn; 5: Curb ;
    public int Event = 0;
//    ---------------For Debug/ Log in file---------------
    public double AccMagThreshold;
    public double EndTime;
//    protected double[][] Features = new double[ClassifierNum][Step.FeautreNum]; /* only used in SVM*/

    public StepData( double EndPeak){
//        this.StepCount = count;
//        this.AzimuthMean = YawMean;
        this.AccMagEndPeak = EndPeak;

    }

}
