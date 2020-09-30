package com.example.SensorGroup.lookupmobile;

class Matrix {
    private int RowNum,ColNum;
    private double[][] A;
    public Matrix(){
        RowNum=1;
        ColNum=1;
        A=new double[1][1];
        A[0][0]=0;
    }
    public Matrix(int _RowNum,int _ColNum){
        RowNum=_RowNum;
        ColNum=_ColNum;
        A=new double[_RowNum][_ColNum];
    }
    public Matrix(int _RowNum,int _ColNum,double[][] _A){
        RowNum=_RowNum;
        ColNum=_ColNum;
        A=new double[_RowNum][_ColNum];
        int i,j;
        i=0;
        while(i<_RowNum&&i<_A.length){
            j=0;
            while(j<_ColNum&&j<_A[i].length){
                A[i][j]=_A[i][j];
                j++;
            }
            i++;
        }
    }
    public Matrix(int _RowNum,int _ColNum,Matrix m){
        RowNum=_RowNum;
        ColNum=_ColNum;
        A=new double[_RowNum][_ColNum];
        int i,j;
        i=0;
        while(i<_RowNum&&i<m.getRowNum()){
            j=0;
            while(j<_ColNum&&j<m.getColNum()){
                A[i][j]=m.getValue(i,j);
                j++;
            }
            i++;
        }
    }
    public int getRowNum(){return RowNum;}
    public int getColNum(){return ColNum;}
    public Double getValue(int i,int j){
        if(i<RowNum&&j<ColNum)return A[i][j];
        return null;
    }
    public String toString(){
        String ln="\r\n",s,c="\t";
        s=RowNum+"*"+ColNum+ln;
        int i,j;
        for(i=0;i<RowNum;i++){
            for(j=0;j<ColNum;j++){
                s+=A[i][j]+c;
            }
            s+=ln;
        }
        return s;
    }
    public static Matrix Product(Matrix m1,Matrix m2){
        if(m1.getColNum()!=m2.getRowNum())return null;
        double[][] _A=new double[m1.getColNum()][m2.getRowNum()];
        int i,j,k;
        for(i=0;i<m1.getRowNum();i++){
            for(j=0;j<m2.getColNum();j++){
                _A[i][j]=0;
                for(k=0;k<m1.getColNum();k++){
                    _A[i][j]+=m1.getValue(i,k)*m2.getValue(k,j);
                }
            }
        }
        Matrix ans=new Matrix(m1.getRowNum(),m2.getColNum(),_A);
        return ans;
    }
}
