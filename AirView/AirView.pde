// AirView //<>//
// Plot the graph of the air voltage from Arduino
// to predict earthquakes
// Dyson Lin dysonlin@gmail.com
// 2016-07-30 05:58 UTC+8 AirView V1.0.0
// 2016-08-10 15:42 UTC+8 AirView V2.1.3 20x data compression. Change background to Black
// 2016-08-16 21:56 UTC+8 AirView V2.1.9 Plot select range area
// 2016-08-16 22:17 UTC+8 AirView V2.2.0 Adjust text sizes
// 2016-08-17 23:43 UTC+8 AirView V2.2.1 Use noLoop() and redraw() to plot graph only after reading new data
// 2016-08-19 18:40 UTC+8 AirView V2.2.2 10K-Ohom-R Voltage
// 2016-08-19 19:14 UTC+8 AirView V2.2.3 Water Voltage
// 2016-08-20 21:04 UTC+8 AirView V2.2.4 220-Ohom-R Voltage
// 2016-08-24 04:25 UTC+8 AirView V2.2.5 Air Voltage
// 2016-08-26 17:10 UTC+8 AirView V2.2.6 Fix the minData and maxData bug
// 2016-08-27 03:53 UTC+8 AirView V2.2.7 Modify plotData(), plotSelectRange()
// 2016-08-29 01:31 UTC+8 AirView V2.2.8 Comment out noLoop() and redraw()
// 2016-08-29 02:23 UTC+8 AirView V2.2.9 Make the window resizable
// 2016-11-05 13:20 UTC+8 AirView V3.0.0 Change the input from ADC data to the converted voltage in mV
//                                Set compressionRatio to 1
// 2016-11-06 06:27 UTC+8 AirView V3.0.1 Set compressionRatio to 20
// 2016-12-06 11:12 UTC+8 AirView V3.0.2 Change the color of the min-max graph from white to gray
// 2016-12-06 14:42 UTC+8 AirView V3.0.3 Plot the mean graph in white
//                                Set compressionRatio to 32
// 2016-12-09 16:04 UTC+8 AirView V3.0.4 Set compressionRatio to 128
// 2016-12-10 10:50 UTC+8 AirView V3.0.5 Change int to float
// 2016-12-10 17:41 UTC+8 AirView V3.0.6 Plot Mean Graph only
// 2016-12-22 12:06 UTC+8 AirView V3.0.7 Set window title to show version number
// 2016-12-22 12:25 UTC+8 AirView V3.0.8 Change y-axis captions from int to float
// 2016-12-27 20:47 UTC+8 AirView V3.0.9 Change x and y axes to a box
// 2016-12-28 02:45 UTC+8 AirView V3.1.0 Plot central line for y axis
// 2016-12-31 04:45 UTC+8 AirView V3.1.1 Plot central line for x axis
// 2017-01-01 23:43 UTC+8 AirView V3.1.2 Add isLeapYear()
// 2017-01-02 03:47 UTC+8 AirView V3.1.3 Add dateAndTimeToNumber()
// 2017-01-04 03:55 UTC+8 AirView V3.1.4 Add numberToDate()
// 2017-01-04 23:59 UTC+8 AirView V3.1.5 Add timeToDate()
// 2017-01-05 00:05 UTC+8 AirView V3.1.6 Change timeToDate() to numberToTime()
// 2017-01-07 07:17 UTC+8 AirView V3.1.7 Show date and time for central x 
// 2017-01-11 09:55 UTC+8 AirView V3.1.8 Change Select Area from fill to lines to fix ghost lines
// 2017-01-12 13:44 UTC+8 AirView V3.1.9 Use GregorianCalendar
// 2017-01-19 14:12 UTC+8 AirView V3.2.0 detectMouse(): Show mouse position in Select Area
// 2017-01-20 14:07 UTC+8 AirView V3.2.1 Detect mousePressed for left button
// 2017-01-20 17:10 UTC+8 AirView V3.2.2 Select Range for the left
// 2017-01-20 17:36 UTC+8 AirView V3.2.3 Fix left time stamp
// 2017-01-20 22:54 UTC+8 AirView V3.2.4 Fix setSelectLeftTimeStamp() map() bug: don't use it with long
// 2017-01-21 12:51 UTC+8 AirView V3.2.5 Fix setSelectLeftTimeStamp() left range bug
// 2017-01-26 00:09 UTC+8 AirView V3.2.6 PlotQuarterY()

import java.util.*;
import processing.serial.*;
String titleString = "AirView V3.2.5";

GregorianCalendar startCalendar = null;
long startTime = 0;
String startTimeString = "";
String startDateString = "";

GregorianCalendar currentCalendar = null;
long currentTime = 0;
String currentTimeString = "";
String currentDateString = "";

GregorianCalendar halfCalendar = null;
long halfTime = 0;
String halfTimeString = "";
String halfDateString = "";

int selectLeftDataNumber = 1;
GregorianCalendar selectLeftCalendar = null;
long selectLeftTime = 0;
String selectLeftTimeString = "";
String selectLeftDateString = "";

int graphLeft = 0;
int graphRight = 0;
int graphTop = 0;
int graphBottom = 0;

int selectRangeLeft = 0;
int selectRangeRight = 0;
int selectRangeTop = 0;
int selectRangeBottom = 0;
int selectLeft = 0;

int isFirstRead = 1;

float maxData = 0.0;
float minData = 0.0;
float rangeMaxData = 0.0;
float rangeMinData = 0.0;


//int maxTime = 0;
//int minTime = 0;

final int compressionRatio = 128;

final int bufferSize = compressionRatio; // compression ratio = bufferSize/2. So bufferSize must be even.
float [] buffer = new float[bufferSize];
int [] bufferTime = new int[bufferSize];
int bufferNumber = 0;

int dataLimit = 1000000;
float[] data = new float[dataLimit];
int[] dataTime = new int[dataLimit];
int dataNumber = 0;


void setup()
{ //<>//
  // Set window title to show version number
  surface.setTitle(titleString);

  size(1200, 800);
  surface.setResizable(true);

  openSerialPort();
  setStartTimeStamp();
  setCurrentTimeStamp();
  setSelectLeftTimeStamp();
}


void   openSerialPort()
{
  int lf = 10;    // Linefeed in ASCII
  Serial myPort;  // The serial port

  // List all the available serial ports
  print("Available serial ports: ");
  printArray(Serial.list());

  myPort = new Serial(this, Serial.list()[0], 9600);
  myPort.clear(); // Clear buffer
  myPort.bufferUntil(lf); // Trigger serialEvent() only after linefeed is read.
}


void draw()
{
  background(0);  // black background
  stroke(0);
  fill(0);

  // Set the location of graph
  graphLeft = 80;
  graphRight = width - 50;
  graphTop = 50;
  graphBottom = height - 100;
  //maxTime = graphRight - graphLeft;
  
  // Set the location of graph
  selectRangeLeft = graphLeft + 50;
  selectRangeRight = width - 100;
  selectRangeBottom = height - 15;
  selectRangeTop = height - 48;
  
  if (selectLeft < selectRangeLeft)
  {
    selectLeft = selectRangeLeft;
  }
  else
  {
    if (selectLeft > selectRangeRight - 10)
    {
      selectLeft = selectRangeRight - 10;
    }
  }


  setCurrentTimeStamp();
  plotSelectRange();
  //plotAxes();
  
  detectMouse();
  
  plotData(selectLeftDataNumber, graphLeft, graphRight, graphBottom, graphTop);
  plotAxes();
}


void plotData(int leftDataNumber, int leftBorder, int rightBorder, int bottomBorder, int topBorder) 
{ 
  float x1 = 0;
  float y1 = 0;
  float x2 = 0;
  float y2 = 0;

  stroke(255); // white
  
  
  if (leftDataNumber < 1)
  {
    return;
  }

  if (dataNumber < 1) {
    return;
  }

  if (dataNumber == 1) {
    point(leftBorder, bottomBorder);
    return;
  }
  
  rangeMaxData = data[leftDataNumber - 1];
  rangeMinData = data[leftDataNumber - 1];
  
  for (int i=leftDataNumber; i<dataNumber; i++)
  {
    if (data[i] > rangeMaxData)
    {
      rangeMaxData = data[i];
    }
    else 
    {
      if (data[i] < rangeMinData)
      {
        rangeMinData = data[i];
      }
    }
  }

  // set first point
  x1 = leftBorder;
  y1 = map(data[leftDataNumber - 1], rangeMinData, rangeMaxData, bottomBorder, topBorder);
  //y1 = map(data[0], minData, maxData, bottomBorder, topBorder);

  // plot lines
  for (int i=leftDataNumber; i<dataNumber; i++)
  //  for (int i=1; i<dataNumber; i++)
  {
    x2 = map(i, leftDataNumber-1, dataNumber-1, leftBorder, rightBorder); // auto range
    //x2 = map(i, 0, dataNumber-1, leftBorder, rightBorder); // auto range
    y2 = map(data[i], rangeMinData, rangeMaxData, bottomBorder, topBorder); // auto range
    //y2 = map(data[i], minData, maxData, bottomBorder, topBorder); // auto range
    line(x1, y1, x2, y2);
    x1 = x2;
    y1 = y2;
  }
}


void detectMouse()
{
  int x = mouseX;
  int y = mouseY;
  
  stroke(0, 128, 0, 128);
  fill(0, 128, 0, 128);
   
  // Show mouse position in Select Area
  if ((x >= (selectRangeLeft - 5)) && (x <= (selectRangeRight + 5)) &&
      (y >= selectRangeTop - 5) && (y <= selectRangeBottom + 5))
  {
    if (x < selectRangeLeft)
    {
      x = selectRangeLeft;
    }
    
    if (x > selectRangeRight - 10)
    {
      x = selectRangeRight - 10;
    }
       
    line(x, selectRangeBottom, x, selectRangeTop);
  
  
    // Detect mousePressed for left button
    if (mousePressed && (mouseButton == LEFT))
    {
      selectLeft = mouseX; //<>//
      
      if (selectLeft < selectRangeLeft)
      {
        selectLeft = selectRangeLeft;
      }
      else 
      {
        if (selectLeft > selectRangeRight - 10)
        {
          selectLeft = selectRangeRight - 10;
        }
      }
      
      setSelectLeftTimeStamp();
      // setSelectLeftTimeStamp(selectLeft);
    }
  }
}




void plotSelectRange()
{
  int textSize = 12;
  textSize(textSize);

  stroke(0, 128, 0, 128);
  fill(0, 128, 0, 128);

  line(selectRangeLeft, selectRangeBottom, selectRangeRight, selectRangeBottom);
  line(selectRangeLeft, selectRangeTop, selectRangeRight, selectRangeTop);
  line(selectRangeLeft, selectRangeBottom, selectRangeLeft, selectRangeTop);
  line(selectRangeRight, selectRangeBottom, selectRangeRight, selectRangeTop);
  if (selectLeft > selectRangeLeft)
  {
    line(selectLeft, selectRangeBottom, selectLeft, selectRangeTop);
  }

  stroke(255);
  fill(255);

  textAlign(CENTER);
  text(startTimeString, graphLeft, selectRangeTop + textSize*1);
  text(startDateString, graphLeft, selectRangeTop + textSize*2.5);

  textAlign(CENTER);
  text(currentTimeString, graphRight, selectRangeTop + textSize*1);
  text(currentDateString, graphRight, selectRangeTop + textSize*2.5);

  //stroke(0);
  //fill(0);

  plotData(1, selectRangeLeft, selectRangeRight, selectRangeBottom, selectRangeTop);
}


void plotAxes() {
  int textSize = 12;

  // plot x and y axes as a box
  stroke(0, 128, 0);

  // plot x-axis
  line(graphLeft, graphBottom, graphRight, graphBottom); 
  line(graphLeft, graphTop, graphRight, graphTop); 
  line(graphLeft, (graphBottom + graphTop)/2, graphRight, (graphBottom + graphTop)/2); 

  // plot y-axis
  line(graphLeft, graphBottom, graphLeft, graphTop); 
  line(graphRight, graphBottom, graphRight, graphTop); 
  line((graphLeft + graphRight)/2, graphBottom, (graphLeft + graphRight)/2, graphTop); 

  // plot graph title and captions
  stroke(255);
  fill(255);

  textAlign(CENTER);
  textSize = 24;
  textSize(textSize);
  text("Air Voltage", (graphLeft+graphRight)/2, graphTop - textSize);

  textSize = 16;
  textSize(textSize);
  text("Time", (graphRight + graphLeft)/2, graphBottom + textSize * 3);
  text("V (mV)", graphLeft, graphTop - textSize);

  textSize = 12;
  textSize(textSize);
  textAlign(RIGHT);

  text(rangeMinData, graphLeft - textSize/2, graphBottom + textSize/2);
  text(rangeMaxData, graphLeft - textSize/2, graphTop + textSize/2);
  text((rangeMinData + rangeMaxData)/2, graphLeft - textSize/2, (graphBottom + graphTop)/2 + textSize/2);
 
  textAlign(CENTER);
  text(selectLeftTimeString, graphLeft, graphBottom + textSize*1.5);
  text(selectLeftDateString, graphLeft, graphBottom + textSize*2.5); 
 
  text(currentTimeString, graphRight, graphBottom + textSize*1.5);
  text(currentDateString, graphRight, graphBottom + textSize*2.5);
  
  // Show date and time for central x
  text(halfTimeString, (graphLeft+graphRight)/2, graphBottom + textSize*1.5);
  text(halfDateString, (graphLeft+graphRight)/2, graphBottom + textSize*2.5);
  //text(halfTimeNumber, (graphLeft+graphRight)/2, graphBottom + textSize*3.5);  


  textSize = 16;
  textSize(textSize);
  //textAlign(CENTER);
  text("Time", (graphRight + graphLeft)/2, graphBottom + textSize * 3);
  text("V (mV)", graphLeft, graphTop - textSize);
}

void serialEvent(Serial whichPort) {
  int lf = 10;    // Linefeed in ASCII
  String inString = null;  // Input string from serial port
  int voltage = 0;

  inString = whichPort.readStringUntil(lf);
  if (inString == null)
  {    
    return;
  }

  inString = trim(inString);
  voltage = int(inString);

  if (isFirstRead == 1)
  {
    print("Discard first read: ");
    println(inString);
    isFirstRead = 0;
    return;
  }

  buffer[bufferNumber] = voltage;
  bufferTime[bufferNumber] = millis();

  if (bufferNumber < bufferSize-1)
  {
    bufferNumber++;
  } else 
  {
    // bufferNumber == bufferSize-1
    // That means buffer is full.
    // Compress data: compute the mean.

    float sum = 0;
    int i = 0;
    float yMean = 0;
    String s = null;



    sum = 0;
    for (i=0; i<bufferSize; i++)
    {
      sum = sum + buffer[i];
    }
    yMean = sum / bufferSize;


    bufferNumber = 0;

    if (dataNumber == 0)
    {
      maxData = yMean;
      minData = yMean;
    } else {
      if (yMean > maxData)
      {
        maxData = yMean;
      }

      if (yMean < minData)
      {
        minData = yMean;
      }
    }

    data[dataNumber] = yMean;
    s = "data[" + dataNumber + "] = " + data[dataNumber];
    println(s);
    dataNumber++;
  }
}


void setStartTimeStamp()
{
  int yearInt = 0;
  int monthInt = 0;
  int dateInt = 0;
  int hourInt = 0;
  int minuteInt = 0;
  int secondInt = 0;
    
  startCalendar = new GregorianCalendar();
  startTime = startCalendar.getTimeInMillis();
  
  yearInt = startCalendar.get(Calendar.YEAR);
  monthInt = startCalendar.get(Calendar.MONTH) + 1;
  dateInt = startCalendar.get(Calendar.DATE);
  
  hourInt = startCalendar.get(Calendar.HOUR_OF_DAY);
  minuteInt = startCalendar.get(Calendar.MINUTE);
  secondInt = startCalendar.get(Calendar.SECOND);
  
  startDateString = nf(yearInt, 4) + "-" + nf(monthInt, 2) + "-" + nf(dateInt, 2);
  startTimeString = nf(hourInt, 2) + ":" + nf(minuteInt, 2) + ":" + nf(secondInt, 2);
}


void setCurrentTimeStamp()
{
  int yearInt = 0;
  int monthInt = 0;
  int dateInt = 0;
  int hourInt = 0;
  int minuteInt = 0;
  int secondInt = 0;
  
  currentCalendar = new GregorianCalendar();
  currentTime = currentCalendar.getTimeInMillis();
  
  yearInt = currentCalendar.get(Calendar.YEAR);
  monthInt = currentCalendar.get(Calendar.MONTH) + 1;
  dateInt = currentCalendar.get(Calendar.DATE);
  
  hourInt = currentCalendar.get(Calendar.HOUR_OF_DAY);
  minuteInt = currentCalendar.get(Calendar.MINUTE);
  secondInt = currentCalendar.get(Calendar.SECOND);
  
  currentDateString = nf(yearInt, 4) + "-" + nf(monthInt, 2) + "-" + nf(dateInt, 2);
  currentTimeString = nf(hourInt, 2) + ":" + nf(minuteInt, 2) + ":" + nf(secondInt, 2);
  
  setHalfTimeStamp();
  
  //halfTime = (startTime + currentTime) / 2;
  //halfCalendar = new GregorianCalendar();
  //halfCalendar.setTimeInMillis(halfTime);
  
  //yearInt = halfCalendar.get(Calendar.YEAR);
  //monthInt = halfCalendar.get(Calendar.MONTH) + 1;
  //dateInt = halfCalendar.get(Calendar.DATE);
  
  //hourInt = halfCalendar.get(Calendar.HOUR_OF_DAY);
  //minuteInt = halfCalendar.get(Calendar.MINUTE);
  //secondInt = halfCalendar.get(Calendar.SECOND);
  
  //halfDateString = nf(yearInt, 4) + "-" + nf(monthInt, 2) + "-" + nf(dateInt, 2);
  //halfTimeString = nf(hourInt, 2) + ":" + nf(minuteInt, 2) + ":" + nf(secondInt, 2);
 }
 
 void setHalfTimeStamp()
 {
   int yearInt = 0;
   int monthInt = 0;
   int dateInt = 0;
   int hourInt = 0;
   int minuteInt = 0;
   int secondInt = 0;
  
   halfTime = (selectLeftTime + currentTime) / 2;
   //halfTime = (startTime + currentTime) / 2;
   
   halfCalendar = new GregorianCalendar();
   halfCalendar.setTimeInMillis(halfTime);
  
   yearInt = halfCalendar.get(Calendar.YEAR);
   monthInt = halfCalendar.get(Calendar.MONTH) + 1;
   dateInt = halfCalendar.get(Calendar.DATE);
  
   hourInt = halfCalendar.get(Calendar.HOUR_OF_DAY);
   minuteInt = halfCalendar.get(Calendar.MINUTE);
   secondInt = halfCalendar.get(Calendar.SECOND);
  
   halfDateString = nf(yearInt, 4) + "-" + nf(monthInt, 2) + "-" + nf(dateInt, 2);
   halfTimeString = nf(hourInt, 2) + ":" + nf(minuteInt, 2) + ":" + nf(secondInt, 2);
}


void setSelectLeftTimeStamp()
//void setSelectLeftTimeStamp(int selectLeft)
{
   int yearInt = 0;
   int monthInt = 0;
   int dateInt = 0;
   int hourInt = 0;
   int minuteInt = 0;
   int secondInt = 0;
   int fullRange = 0;
   int selectLeftRange = 0;
   double leftRatio = 0.0;
   long fullTime = 0;
   
   //if ((selectLeft == 0) || (dataNumber < 3))
   if (selectLeft <= selectRangeLeft)
   {
      selectLeft = selectRangeLeft;
      selectLeftDataNumber = 1;
      selectLeftTime = startTime;
   }
   else
   {
     if (selectLeft > selectRangeRight - 10)
     {
       selectLeft = selectRangeRight - 10;
     }
     
     selectLeftDataNumber = round(map(selectLeft, selectRangeLeft, selectRangeRight, 1, dataNumber - 1)); //<>//
     fullRange = selectRangeRight - selectRangeLeft;
     selectLeftRange = selectLeft - selectRangeLeft;
     leftRatio = selectLeftRange/((double)fullRange);
     //leftRatio = selectLeft/((double)fullRange);
     fullTime = currentTime - startTime;
     selectLeftTime = (long)(fullTime * leftRatio); //<>//
     selectLeftTime = startTime + selectLeftTime;
     //selectLeftTime = round((selectLeft, selectRangeLeft, selectRangeRight, startTime, currentTime));  
   }
  
   selectLeftCalendar = new GregorianCalendar(); //<>//
   selectLeftCalendar.setTimeInMillis(selectLeftTime);
  
   yearInt = selectLeftCalendar.get(Calendar.YEAR);
   monthInt = selectLeftCalendar.get(Calendar.MONTH) + 1;
   dateInt = selectLeftCalendar.get(Calendar.DATE);
  
   hourInt = selectLeftCalendar.get(Calendar.HOUR_OF_DAY);
   minuteInt = selectLeftCalendar.get(Calendar.MINUTE);
   secondInt = selectLeftCalendar.get(Calendar.SECOND);
  
   selectLeftDateString = nf(yearInt, 4) + "-" + nf(monthInt, 2) + "-" + nf(dateInt, 2);
   selectLeftTimeString = nf(hourInt, 2) + ":" + nf(minuteInt, 2) + ":" + nf(secondInt, 2);
}