// Air-1
//
// Read the air voltage of (A0 - A1) to predict quakes
// 測量(A0 - A1)的空氣電壓以預測地震
// 
// 台灣地震預測研究所 所長 
// 林湧森
// dysonlin@gmail.com
// 
// 2016-10-03 11:50 UTC+8 V1.0
// 2016-10-25 02:16 UTC+8 V1.1 Change baud rate to 115200 for ESP8266 WeMos-D1R2
// 2016-11-06 15:43 UTC+8 V1.2 Change baud rate to 9600
//                             Change output from raw data to mV
// 2016-12-18 22:21 UTC+8 V1.3 Change program name to Air-2
// 2019-11-07 16:28 UTC+8 V1.4 Modidy Air-2 to get Air-1

// analogRead() returns 0 ~ 1023
// 0 means 0 mV.
// 1023 means 5000 mV

void setup()
{
  Serial.begin(9600);
}

void loop()
{
  int valueA0 = analogRead(A0);
  int valueA1 = analogRead(A1);
  
  // Convert 10 bit ADC value 0 ~ 1023 to 0 mV ~ 5000 mV
  int mV = round(((valueA0 - valueA1) * 5000.0 ) / 1023.0);
  
  Serial.println(mV);
  delay(200);
}
