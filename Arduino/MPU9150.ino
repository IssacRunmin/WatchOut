#include "I2Cdev.h"
#include "MPU9150.h"
#include <stdlib.h>
#include <Wire.h>
#include <SoftwareSerial.h>
#define LED_PIN 13
/*const int MPUAdd = 0x68;        //MPU9150的I2C地址
const int nReadRegister = 9;    //读取寄存器的数量
unsigned long nLastTime = 0;    //上一次读数的时间
int RecivedData[nReadRegister]; //接收的数据*/
MPU9150 accelGyroMag;//MPU9150
int interval = 14;
int16_t ax, ay, az;//acceleration
int16_t gx, gy, gz;//gyroscope
int16_t mx, my, mz;//Magnetometer
uint64_t Time,Duration,StartTime, TimeStamp;
char Buffer[8];
const unsigned long int BluetoothBaud = 115200; //蓝牙模块波特率
SoftwareSerial mySerial(8,9); //
//  Arduino D9 to BT RX through a voltage divider
//  Arduino D8 BT TX (no need voltage divider)
bool blinkState = false;        //To show the MPU9150 collecting the data
int Start = 0;
char CollectData = '0';
double az_m;

void setup() {  
  Serial.begin(115200); //初始化串口，指定波特率
  Wire.begin(); //初始化Wire库
  mySerial.begin(BluetoothBaud);
  Serial.println("Initializing I2C devices...");
  accelGyroMag.initialize();
  accelGyroMag.setFullScaleAccelRange(0x02);
  accelGyroMag.setFullScaleGyroRange(0x00);
  Serial.println("Testing device connections...");
  Serial.println(accelGyroMag.testConnection() ? "MPU9150 connection successful" : "MPU9150 connection failed");
  pinMode(LED_PIN, OUTPUT);
  delay(10);
  Time = millis();
  StartTime = millis();
}

void loop() {
    while (mySerial.available()>0)
    {
      CollectData= mySerial.read();
    }
    if ('1' == CollectData){
      /*accelGyroMag.getMotion9(&ax, &ay, &az, &gx, &gy, &gz, &mx, &my, &mz);*/
      accelGyroMag.getAcceleration(&ax, &ay, &az);
      accelGyroMag.getRotation(&gx, &gy, &gz);
      /*accelGyroMag.getMag3(&mx, &my, &mz);*/
      /*az_m = (double)az / 4096 * 9.806;
      Serial.print(ax); Serial.print("\t");
      Serial.print(ay); Serial.print("\t");
      Serial.print(az_m); Serial.print("\t");
      
      Serial.print(gx); Serial.print("\t");
      Serial.print(gy); Serial.print("\t");
      Serial.print(gz); Serial.print("\n");*/
      /*TimeStamp = millis() - StartTime;
      sprintf(Buffer, "%08d", int32_t(TimeStamp));
      Serial.print(Buffer);Serial.print("\t");*/
      az_m = (double)az / 4096 * 9.806;
      Serial.print(az_m); Serial.print("\t");
      mySerial.print(ax); mySerial.print("\t");
      mySerial.print(ay); mySerial.print("\t");
      mySerial.print(az); mySerial.print("\t");
      mySerial.print(gx); mySerial.print("\t");
      mySerial.print(gy); mySerial.print("\t");
      mySerial.print(gz); mySerial.print("\n");
      if (!blinkState){
        blinkState = !blinkState;
        digitalWrite(LED_PIN, blinkState);
      }
      Duration = millis() - Time;
      if (Duration < interval){
        delay(interval - Duration);
      }
      Time = millis();
      sprintf(Buffer, "%08d", int32_t(Duration));
      Serial.print(Buffer);Serial.print("\n");
    }
    else
    {
      delay(500);
      StartTime = millis();
      blinkState = !blinkState;
      digitalWrite(LED_PIN, blinkState);
    }
    
    
}

