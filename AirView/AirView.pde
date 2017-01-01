// AirView //<>//
// Plot the graph of the air voltage from Arduino
// to predict earthquakes.
// Dyson Lin dysonlin@gmail.com
// 2016-07-30 05:58 UTC+8 AirView V1.0.0
// 2016-08-10 15:42 UTC+8 AirView V2.1.3 20x data compression. Change background to Black.
// 2016-08-16 21:56 UTC+8 AirView V2.1.9 Plot select range area.
// 2016-08-16 22:17 UTC+8 AirView V2.2.0 Adjust text sizes.
// 2016-08-17 23:43 UTC+8 AirView V2.2.1 Use noLoop() and redraw() to plot graph only after reading new data.
// 2016-08-19 18:40 UTC+8 AirView V2.2.2 10K-Ohom-R Voltage!
// 2016-08-19 19:14 UTC+8 AirView V2.2.3 Water Voltage!
// 2016-08-20 21:04 UTC+8 AirView V2.2.4 220-Ohom-R Voltage!
// 2016-08-24 04:25 UTC+8 AirView V2.2.5 Air Voltage.
// 2016-08-26 17:10 UTC+8 AirView V2.2.6 Fix the minData and maxData bug.
// 2016-08-27 03:53 UTC+8 AirView V2.2.7 Modify plotData(), plotSelectRange().
// 2016-08-29 01:31 UTC+8 AirView V2.2.8 Comment out noLoop() and redraw().
// 2016-08-29 02:23 UTC+8 AirView V2.2.9 Make the window resizable.
// 2016-11-05 13:20 UTC+8 AirView V3.0.0 Change the input from ADC data to the converted voltage in mV
//                               Set compressionRatio to 1.
// 2016-11-06 06:27 UTC+8 AirView V3.0.1 Set compressionRatio to 20.
// 2016-12-06 11:12 UTC+8 AirView V3.0.2 Change the color of the min-max graph from white to gray.
// 2016-12-06 14:42 UTC+8 AirView V3.0.3 Plot the mean graph in white.
//                               Set compressionRatio to 32.
// 2016-12-09 16:04 UTC+8 AirView V3.0.4 Set compressionRatio to 128.
// 2016-12-10 10:50 UTC+8 AirView V3.0.5 Change int to float.
// 2016-12-10 17:41 UTC+8 AirView V3.0.6 Plot Mean Graph only.
// 2016-12-22 12:06 UTC+8 AirView V3.0.7 Set window title to show version number.
// 2016-12-22 12:25 UTC+8 AirView V3.0.8 Change y-axis captions from int to float.
// 2016-12-27 20:47 UTC+8 AirView V3.0.9 Change x and y axes to a box.
// 2016-12-28 02:45 UTC+8 AirView V3.1.0 Plot central line for y axis.
// 2016-12-31 04:45 UTC+8 AirView V3.1.1 Plot central line for x axis.
// 2017-01-01 23:43 UTC+8 AirView V3.1.2 Add isLeapYear().

import processing.serial.*;
String titleString = "AirView V3.1.2";

int startTime = 0;
int currentTime = 0;

String timeStringStart = null;
String dateStringStart = null;
String timeStringNow = null;
String dateStringNow = null;

int graphLeft = 0;
int graphRight = 0;
int graphTop = 0;
int graphBottom = 0;

int selectRangeLeft = 0;
int selectRangeRight = 0;
int selectRangeTop = 0;
int selectRangeBottom = 0;

int isFirstRead = 1;

float maxData = 1;
float minData = 0;

int maxTime = 0;
int minTime = 0;

final int compressionRatio = 128;

final int bufferSize = compressionRatio; // compression ratio = bufferSize/2. So bufferSize must be even.
float [] buffer = new float[bufferSize];
int [] bufferTime = new int[bufferSize];
int bufferNumber = 0;

int dataLimit = 1000000;
float[] data = new float[dataLimit];
int[] dataTime = new int[dataLimit];
int dataNumber = 0;



boolean mouseInZoomArea(int x, int y)
{
  boolean inZoomArea = false;
  int zoomAreaLength = 10;
  int zoomLeft = width - zoomAreaLength;;
  int zoomRight = width;
  int zoomBottom = height;
  int zoomTop = height - zoomAreaLength;
  
  if ((x >= zoomLeft) && (x <= zoomRight) && (y <= zoomBottom) && (y >= zoomTop))
  {
    inZoomArea = true;
  }
  
  return inZoomArea;
}


//void mouseDragged() 
//{
//  if (mouseInZoomArea(mouseX, mouseY))
//  {
//    int newWidth = width + (mouseX - pmouseX);
//    int newHeight = height + (mouseY - pmouseY);

//    surface.setSize(newWidth, newHeight);
//  }
//}


void setup()
{
  // Set window title to show version number
  surface.setTitle(titleString);
  
  size(1200, 800);
  surface.setResizable(true);

  openSerialPort();
  setStartTimeStamp();
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


void setStartTimeStamp()
{
  startTime = millis();
  timeStringStart = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  dateStringStart = year() + "-" + nf(month(), 2) + "-" + nf(day(), 2);
}


void setTimeStamp()
{
  currentTime = millis();
  timeStringNow = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  dateStringNow = year() + "-" + nf(month(), 2) + "-" + nf(day(), 2);
}


void draw()
{
  background(0);  // black background
  stroke(0);
  fill(0);

  // Set the location of graph
  graphLeft = 80;
  //graphLeft = 50;
  graphRight = width - 50;
  graphTop = 50;
  graphBottom = height - 100;
  maxTime = graphRight - graphLeft;

  setTimeStamp();
  plotSelectRange();
  plotAxes();
  plotData(graphLeft, graphRight, graphBottom, graphTop);
  //plotData(graphLeft+3, graphRight, graphBottom-3, graphTop);
}


void plotData(int leftBorder, int rightBorder, int bottomBorder, int topBorder) {
  float x1 = 0;
  float y1 = 0;
  float x2 = 0;
  float y2 = 0;
  
  stroke(255); // white

  if (dataNumber < 1) {
    return;
  }
  
  if (dataNumber == 1) {
    point(leftBorder, bottomBorder);
    return;
  }

  // set first point
  x1 = leftBorder;
  y1 = map(data[0], minData, maxData, bottomBorder, topBorder);
  
  // plot lines
  for (int i=1; i<dataNumber; i++)
  {
    x2 = map(i, 0, dataNumber-1, leftBorder, rightBorder); // auto range
    y2 = map(data[i], minData, maxData, bottomBorder, topBorder); // auto range
    line(x1, y1, x2, y2);
    x1 = x2;
    y1 = y2;
  }
}


void plotSelectRange()
{
  // Set the location of graph
  selectRangeLeft = graphLeft + 50;
  //selectRangeLeft = 100;
  selectRangeRight = width - 100;
  selectRangeBottom = height - 15;
  selectRangeTop = height - 48;

  int textSize = 12;
  textSize(textSize);

  stroke(0, 128, 0, 128);
  fill(0, 128, 0, 128);
  rect(selectRangeLeft, selectRangeTop, selectRangeRight - selectRangeLeft, selectRangeBottom - selectRangeTop);

  stroke(255);
  fill(255);

  textAlign(CENTER);
  text(timeStringStart, graphLeft, selectRangeTop + textSize*1);
  text(dateStringStart, graphLeft, selectRangeTop + textSize*2.5);

  textAlign(CENTER);
  text(timeStringNow, graphRight, selectRangeTop + textSize*1);
  text(dateStringNow, graphRight, selectRangeTop + textSize*2.5);
  
  //stroke(0);
  //fill(0);

  plotData(selectRangeLeft, selectRangeRight, selectRangeBottom, selectRangeTop);
}


void plotAxes() {
  int textSize = 12;
  //float minVoltage = 0;
  //float maxVoltage = 0; 
  
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
  
  text(minData, graphLeft - textSize/2, graphBottom + textSize/2);
  //minVoltage = minData;
  //text(minVoltage, graphLeft - textSize/2, graphBottom);

  text(maxData, graphLeft - textSize/2, graphTop + textSize/2);
  //maxVoltage = maxData;
  //text(maxVoltage, graphLeft - textSize/2, graphTop + textSize);
 
  text((minData + maxData)/2, graphLeft - textSize/2, (graphBottom + graphTop)/2 + textSize/2);

  textAlign(CENTER);
  text(timeStringStart, graphLeft, graphBottom + textSize*1.5);
  text(dateStringStart, graphLeft, graphBottom + textSize*2.5);

  textAlign(CENTER);
  text(timeStringNow, graphRight, graphBottom + textSize*1.5);
  text(dateStringNow, graphRight, graphBottom + textSize*2.5);

  textAlign(CENTER);

  textSize = 16;
  textSize(textSize);
  textAlign(CENTER);
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

Boolean isLeapYear(int year)
{
  int remainder = 0;
  
  remainder = year % 400;
  if (remainder == 0)
  {
    return true;
  }
  
  remainder = year % 100;
  if (remainder == 0)
  {
    return false;
  }
  
  remainder = year % 4;
  if (remainder == 0)
  {
    return true;
  }
  
  return false;
}