function Yaw = 	IMU(Data,twoKp,twoKi)
sampleFreq = 70 ;
acc_x = Data(:,1);
data_point = size(acc_x,1);   
len=data_point/ sampleFreq;

% twoKp =  5 ;
% twoKi =  0.005 ;

q0 = 1;
q1 = 0;
q2 = 0;
q3 = 0; 
integralFBx = 0; 
integralFBy = 0;
integralFBz = 0; %定义姿态解算误差的积分

Yaw = zeros(data_point,1);

for i = 1:len * sampleFreq
ax=Data(i,1);
ay=Data(i,2);
az=Data(i,3);
gx=Data(i,4)/180*pi;
gy=Data(i,5)/180*pi;
gz=Data(i,6)/180*pi;
% mx=Data(i,7);
% my=Data(i,8);
% mz=Data(i,9);
% 
% q0q0 = q0*q0;
% q0q1 = q0*q1;
% q0q2 = q0*q2;
% q0q3 = q0*q3;
% q1q1 = q1*q1;
% q1q2 = q1*q2;
% q1q3 = q1*q3;
% q2q2 = q2*q2;   
% q2q3 = q2*q3;
% q3q3 = q3*q3;


recipNorm = 1/sqrt(ax * ax + ay * ay + az * az);
ax = recipNorm * ax;
ay = recipNorm * ay;
az = recipNorm * az;

halfvx = q1 * q3 - q0 * q2;
halfvy = q0 * q1 + q2 * q3;
halfvz = q0 * q0 - 0.5 + q3 * q3;

halfex = (ay * halfvz - az * halfvy);
halfey = (az * halfvx - ax * halfvz);
halfez = (ax * halfvy - ay * halfvx);

integralFBx = twoKi * halfex * (1.0 / sampleFreq) + integralFBx; 
integralFBy = twoKi * halfey * (1.0 / sampleFreq) + integralFBy;
integralFBz = twoKi * halfez * (1.0 / sampleFreq) + integralFBz;
gx = integralFBx + gx;
gy = integralFBy + gy;
gz = integralFBz + gz;


gx = twoKp * halfex + gx;
gy = twoKp * halfey + gy;
gz = twoKp * halfez + gz;


gx = (0.5 * (1.0 / sampleFreq)) * gx; 
gy = (0.5 * (1.0 / sampleFreq)) * gy;
gz = (0.5 * (1.0 / sampleFreq)) * gz;
qa = q0;
qb = q1;
qc = q2;
q0 = (-qb * gx - qc * gy - q3 * gz) + q0;
q1 = (qa * gx + qc * gz - q3 * gy) + q1;
q2 = (qa * gy - qb * gz + q3 * gx) + q2;
q3 = (qa * gz + qb * gy - qc * gx) + q3;

recipNorm = 1/sqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
q0 = recipNorm * q0;
q1 = recipNorm * q1;
q2 = recipNorm * q2;
q3 = recipNorm * q3;

  Yaw (i)= atan2(2 * q1 * q2 + 2 * q0 * q3, -2 * q2*q2 - 2 * q3* q3 + 1)* 57.3;
end;