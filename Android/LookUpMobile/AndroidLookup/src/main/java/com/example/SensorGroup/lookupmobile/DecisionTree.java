package com.example.SensorGroup.lookupmobile;

/**
 * Created by ztgni on 2018/3/31.
 */

public class DecisionTree {
    int [][] Children;
    int [] CutPredictor;
    double [] CutPoint;
    int [] NodeClass;
    int n;
    public DecisionTree(int [][] Children, int [] CutPredictor, double [] CutPoint, int [] NodeClass,int n){
        this.Children = Children;
        this.CutPoint =CutPoint;
        this.CutPredictor = CutPredictor;
        this.NodeClass = NodeClass;
        this.n = n;
        //every element int Children[][] minus 1 since matrix index in matlab is from 1 not 0
        int i=0,j=0;
        for(;i<n;i++){
            for(;j<2;j++) this.Children[i][j]--;
        }
    }
    public int PredictDecisionTree(int[] meas,int state,int k){
        if(this.Children[k][0]==-1 && this.Children[k][1]==-1){ state = this.NodeClass[k];}
        else{
            if(meas[this.CutPredictor[k]]<this.CutPoint[k]){
                PredictDecisionTree(meas,state,this.Children[k][0]);
            }
            else{
                PredictDecisionTree(meas,state,this.Children[k][1]);
            }
        }
        return state;
    }
}
