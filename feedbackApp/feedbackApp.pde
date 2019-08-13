
import controlP5.*;

import cc.arduino.*;
import org.firmata.*;

import processing.serial.*;
import ddf.minim.*;
import ddf.minim.ugens.*;
import java.util.LinkedList;
import java.io.File;
import java.util.List;
import codeanticode.tablet.*;
 
 
File folder;
String [] filenames;
boolean firstDraw;
String userID = "part10j";

Minim       minim;
AudioOutput out;
Oscil       wave;
Oscil       waveSuccess;

LinkedList<Float> prevVals;
int smoothCount = 5;
int valMemory = 30;  //number of values to keep in prevVals (for visual summary feedback), 30 = 1s
PrintWriter output;

public float weight;
float zeroThreshold;
public float currentLoad;  //Smoothed load
public float rawLoad;
public float jitterThreshold = 0.1;
Arduino arduino;
int vibPin = 11;
int loadPin = 0;

float intensity;
float successIntensity;
float freq;
/*final int LOW = 500;    //Low tone freq
final int HIGH = 1000;  //High tone freq
final int SUCCESS_FREQ = 250;*/
final float LOW = 493.88;        //Low tone freq B4
final float HIGH = 987.77;       //High tone freq B5
final float SUCCESS_FREQ = 659.25;  //Success tone freq E5, perfect fifth

float[] targetArr;

float targetLoad = 10;
float minLoad = 0;
float maxLoad = 10;
float successMin = 3;
float successMax = 7;
float successRange;
float range;

Box bottomBar;
Box successBar;
Box topBar;
float barHeight;
float barTopY;
float barTopX;
float successPercentage;  //Height of success bar as percentage of total visual feedback bar
float barWidth;
PImage checkMark;
Box successCover;
final int highTransparency = 250;
final int lowTransparency = 40;

boolean vibState = false;

ControlP5 controlP5;
ControlP5 controlP5a;
ControlFont f;
ControlFont fBig;
RadioButton target;
RadioButton condition;
RadioButton status;
RadioButton attempt;

Tablet tablet;

float previousAttemptLoad = -1;
float tempAttempt = -1;
float thresholdLoadRange;
int visCounter = -1;
float runningSum = 0;

int attemptCount = 0;
int attemptDuration = 0;  //Number of frames in current potential attempt
int zeroDuration = 0;     //Number of zero frames in current potential release (cane unloaded)
int durationThreshold = 60;

int targetReached = 0;

float mass = 1000;

float scaleLoad = 0;

boolean[] lines = new boolean[4];
int startButton = 0;
boolean correctPressure = false;
boolean correctLine = false;

void setup() {
  
  strokeWeight(4);
  fullScreen();
  background(0);
  fill(255);
  prevVals = new LinkedList<Float>();
  frameRate(30);
  weight = 150;
  zeroThreshold = 0;  //Zero threshold in lb used to be 1.0
  tablet = new Tablet(this); 


  try{
    println(Arduino.list());
    arduino = new Arduino(this, Arduino.list()[1], 57600);
    arduino.pinMode(vibPin, Arduino.OUTPUT);
    arduino.pinMode(loadPin, Arduino.INPUT);
  }catch(Exception e){
    println("Can't connect to Arduino :(");
  }
  
  folder = new File(dataPath(""));
  firstDraw = true;
  
  intensity = 0.0;
  freq = LOW;
  minim = new Minim(this);  
  out = minim.getLineOut();
  //Create a sine wave Oscil, set to 500 Hz, at 0.0 amplitude
  wave = new Oscil(freq, intensity, Waves.SINE);
  wave.patch(out);
  successIntensity = 0.0;
  
  barHeight = 36*height/50;
  println("Bar Height: " + barHeight);
  successPercentage = 0.20; 
  barTopY = height/50;
  barTopX = width/2;
  barWidth = width/20;
  //Change center bar with changing currentBottom
  topBar = new Box(barTopX, barTopY, barWidth, barHeight*(1-successPercentage)/2-20, -7);
  float currentBottom = barTopY + barHeight*(1-successPercentage)/2;
  //println("Current Bottom: " + currentBottom);
  println("Percentage " + successPercentage);
  println("Percentage " + successPercentage*barHeight);

  topBar.setColor(color(255,0,0));
  successBar = new Box(barTopX, currentBottom - 20, barWidth, barHeight*successPercentage + 40, -8);
  successCover = new Box(barTopX, currentBottom - 20, barWidth, barHeight*successPercentage + 40, -10);
  currentBottom += barHeight*successPercentage;
  successBar.setColor(color(0,255,0));
  successCover.setColor(color(0,0,255));
  successCover.setFill(lowTransparency);
  bottomBar = new Box(barTopX, currentBottom +20, barWidth, barHeight*(1-successPercentage)/2, -9);
  currentBottom += barHeight*(1-successPercentage)/2;
  bottomBar.setColor(color(255,0,0));
  
  checkMark = loadImage("checkmark-xxl2.png");
  checkMark.resize(floor(barWidth),
  floor(barHeight*successPercentage));
  println(barTopY + barHeight*(1-successPercentage)/2);
  
  println(barTopY);
  println(barTopX);
  println(barHeight);
  println(currentBottom);
  
  output = null;
  
  //targetArr = new float[]{10, 20, 13, 23, 16, 26, 19};
  targetArr = new float[]{0.035*mass, 0.05*mass, 0.065*mass};//{0.08*mass, 0.1*mass, 0.12*mass, 0.14*mass};
  
  controlP5 = new ControlP5(this);
  controlP5a = new ControlP5(this);
  f = new ControlFont(createFont("",12));
  fBig = new ControlFont(createFont("",25));
  controlP5.setFont(f);
  controlP5a.setFont(fBig);
  
  condition = controlP5.addRadioButton("condition",round(width/20), round(8*height/10));
  condition.setSize(20,20);
  condition.toUpperCase(false);
  condition.addItem("Scale", 0);
  condition.addItem("Visual Full", 1);
  condition.addItem("Visual Hidden", 2);
  condition.addItem("Audio Full", 3);
  condition.addItem("Audio Hidden", 4);
  condition.addItem("Visual Summary", 5);
  condition.addItem("Haptic", 6);
 // condition.addItem("Mixed", 7);
 // condition.addItem("Drawing", 8);
  condition.activate(0);
  condition.setNoneSelectedAllowed(false);
  
  status = controlP5.addRadioButton("status",round(3*width/20), round(8*height/10));
  status.setSize(20,20);
  status.addItem("Demo", 0);
  status.addItem("Practice", 1);
  status.addItem("Stationary Trial", 2);
  //status.addItem("Drawing Trial", 3);
  status.activate(0);
  status.setNoneSelectedAllowed(false);
  
  target = controlP5a.addRadioButton("target",round(5*width/20), round(8*height/10));
  target.setSize(30,30);
  for(int i = 0; i < targetArr.length; i++){
    //target.addItem(Integer.toString((int)targetArr[i]),targetArr[i]);
    target.addItem(String.format("%.1f",targetArr[i]),((float)round(targetArr[i]*10))/10);
    println(((float)round(targetArr[i]*10))/10);
  }
  target.activate(0);
  target.setNoneSelectedAllowed(false);
  setFeedbackBounds(target.getValue());
  
  attempt = controlP5.addRadioButton("attempt",round(7*width/20), round(8*height/10));
  attempt.setSize(20,20);
  attempt.addItem("1",0);
  attempt.addItem("2",1);
  attempt.addItem("3",2);
  attempt.addItem("4",3);
  attempt.addItem("5",4);
  attempt.addItem("Done!",5);
  attempt.activate(0);
  status.setNoneSelectedAllowed(false);
}


void writeData()
  {
    String newLine = "";
    newLine += str(target.getValue()) + "\t";
    newLine += str(target.getValue()/mass) + "\t";
    newLine += status.getValue() + "\t";  //0 = demo, 1 = practice, 2 = stationary trial, 3 = chair rise trial
    newLine += condition.getValue() + "\t";  //0 = scale, 1 = visual full, 2 = visual hidden, 3 = audio full, 4 = audio hidden, 5 = visual summary, 6 = haptic
    newLine += str(currentLoad) + "\t";//nf(rawLoad,2,1) + "\t";
    newLine += nf(weight,2,1) + "\t";  //Raw ADC value
    newLine += str(targetReached) + "\t";      //0 = false, 1 = true
    newLine += System.currentTimeMillis();
    
    //println(newLine);
    output.println(newLine);
  }

void keyPressed(){
   if(key == 'r'){
       lines[0] = false;
       lines[1] = false;
       lines[2] = false;
       lines[3] = false;
       startButton = 0; 
  }
  else if(key == ' '){
    targetReached = 1;
  }
}

void keyReleased(){
  if(key == ' '){
    targetReached = 0;
  }
}
/*
void mousePressed() {
  if(currentLoad > zeroThreshold)
    targetReached = 1;
  holdCountdown();
}

void mouseReleased() {
  targetReached = 0;
}
*/
void holdCountdown(){
  //TODO: Implement a timer countdown of some sort
}

void closeFile(){
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
}

void draw(){
  background(0);//(0);
  fill(255);
  textSize(56);
  textAlign(CENTER, CENTER);
  fill(127,256); 
  
  try{
    weight = (float)arduino.analogRead(loadPin);
  }catch(Exception e){}
  currentLoad = (int)((tablet.getPressure() * 1000)/10); //smooth(prevVals, weightMap(weight));

  renderFeedback();
  attemptCounter();
  //println(System.currentTimeMillis());  One frame every ~ 16 millis, ~30 fps
  
  if(currentLoad > zeroThreshold && status.getValue() >= 1){
    writeData();
  }

  
  if(firstDraw){
    firstDraw = false;
    filenames = folder.list();
    boolean nameUsed = false;
    for(int i = 0; i < filenames.length; i++)
    {
      if(filenames[i].equals(userID+".txt") && !userID.equals("test")){
        nameUsed = true;
      }
    }
    if(nameUsed){
      println("File name already used");
      exit();
    }else{
      output = createWriter(dataPath(userID+".txt"));
      output.println("target"+"\t"+"bwtarget"+"\t"+"status"+"\t"+"feedback"+"\t"+"weight"+"\t"+"adc"+"\t"+"trigger"+"\t"+"time");
    }
  }
}

float smooth(LinkedList<Float> list, float newVal){
  float sum = 0.0;
  if(list.size() == 0){
    sum = newVal;
  }
  else if(list.size() < smoothCount){
    int countNum = list.size();
    for(int i = 0; i < (countNum-1); i++){
      sum += list.get(i);
    }
    sum += newVal;
    sum = sum/(countNum+1);
  }
  else{
    for(int i = 0; i < (smoothCount-1); i++){
      sum += list.get(i);
    }
    sum += newVal;
    sum = sum/(smoothCount);

    if(list.size() >= valMemory){
      list.removeLast();
    }
  }
  list.addFirst(newVal);
  rawLoad = sum;
  if(abs(sum - currentLoad) > jitterThreshold){
    return sum;
  }else{
    return sum;//currentLoad;
  }
}

float weightMap(float raw){
  float[] adcArr = {  118.0,
                      147.0,
                      180.0,
                      219.0,
                      242.0,
                      313.0,
                      351.0,
                      371.0,
                      412.0,
                      448.0,
                      475.0,
                      505.0,
                      548.0,
                      572.0,
                      680.0,
                      730.0
                    };
  float[] massArr = {    0.0,
                         5.0,
                         10.0,
                         15.0,
                         20.0,
                         25.0,
                         30.0,
                         35.0,
                         40.0,
                         45.0,
                         50.0,
                         55.0,
                         60.0,
                         70.0,
                         80.0,
                         90.0,
                         100.0
                      };
  if(raw <= adcArr[0]){
    return 0;
  }
  for(int i = 0; i < adcArr.length-1; i++){
    if(raw >= adcArr[i] && raw < adcArr[i+1]){
      return massArr[i]+( (raw-adcArr[i])/(adcArr[i+1]-adcArr[i]) )*(massArr[i+1]-massArr[i]);
    }
  }
  return massArr[massArr.length-1];
}

void setFeedbackBounds(float target){
  //Will need to refactor the drawTriangle method (or visual bar dimensions) if range or successRange are  changed.
  range = 10;//target*0.5;
  minLoad = target-20;
  maxLoad = target+20;
  successRange = mass*0.01/2;//2;  //Was 2 lb for original stationary exp, set to 1% BW for the extension
  thresholdLoadRange = 2*successRange;
  successMin = target - successRange;
  successMax = target + successRange;
}

void renderFeedback(){

  //Don't offer feedback for recall trials
  if(status.getValue() == 2){//trialBox.getValue()){
    return;
  }
  else if(status.getValue() < 2){
    switch((int)condition.getValue()){
      case 0:  //Scale feedback
        scaleRender();
        break;
      case 1:  //Visual full
        visualBarRender(false);
        break;
      case 2:  //Visual hidden
        visualBarRender(true);
        break;
      case 3:  //Audio full
        audioRenderFull();
        break;
      case 4:  //Audio hidden
        audioRenderHidden();
        break;
      case 5:  //Visual summary
        summaryVisualRender();
        break;
      case 6:  //Haptic
        hapticRenderHidden();
        break;
      case 7:  //Mixed
        audioRenderFull();
        summaryVisualRender();
        break;
      case 8:
        drawingSquare();
        break;
    }
  }
  else{
   
    drawingSquareNoPractice();
  }
}

void hapticRender(){
  if(currentLoad > successMax){
    if(vibState == false){
      try{
        arduino.digitalWrite(vibPin, Arduino.HIGH);
        println("Turning motor on");
        vibState = true;
      }catch(Exception e){}
    }
  }else{
    if(vibState == true){
      try{
        arduino.digitalWrite(vibPin, Arduino.LOW);
        println("Turning motor off");
        vibState = false;
      }catch(Exception e){}
    }
  }
}

//TODO: Fix this to add success bounds
void hapticRenderHidden(){
  if(currentLoad > maxLoad){
    intensity = 1;
  /*}else if(currentLoad > target.getValue()){
    intensity =  (currentLoad-target.getValue())/(maxLoad-target.getValue());*/
  }else if(currentLoad > successMax){
    intensity =  (currentLoad-successMax)/(maxLoad-successMax);
  }else if(currentLoad < minLoad && currentLoad > zeroThreshold){
    intensity = 1;
  }else if (currentLoad < successMin && currentLoad > zeroThreshold){
    intensity = 1 - (currentLoad-minLoad)/(successMin-minLoad);
  }else{
    intensity = 0;
  }
  
  arduino.analogWrite(vibPin,round(intensity*255));  //255 is the max voltage output for the pin
  println("Haptic intensity: "+intensity);
}

void modulateHapticIntensity(){
  try{
    if(intensity == 0)
      arduino.digitalWrite(vibPin, Arduino.LOW);
    int period = 10;
    int activatedFrames = round(intensity*period);
    if(frameCount % period <= activatedFrames && intensity != 0){
      arduino.digitalWrite(vibPin, Arduino.HIGH);
    }else{
      arduino.digitalWrite(vibPin, Arduino.LOW);
    }
  }catch(Exception e){
    println("Error writing to vibration pin");
  }
}

void audioRenderHidden(){
  if(currentLoad > maxLoad){
    intensity = 1;
    freq = HIGH;
  }else if(currentLoad > successMax){
    intensity =  (currentLoad-successMax)/(maxLoad-successMax);
    freq = HIGH;
  }else if(currentLoad < minLoad && currentLoad > zeroThreshold){
    intensity = 1;
    freq = LOW;
  }else if (currentLoad < successMin && currentLoad > zeroThreshold){
    intensity = 1 - (currentLoad-minLoad)/(successMin-minLoad);
    freq = LOW;
  }else{
    intensity = 0;
  }
  
  intensity = intensity*intensity;
  
  if(wave.getWaveform() != Waves.SQUARE){
    wave.setWaveform(Waves.SQUARE);
  }
  wave.setAmplitude(intensity);
  wave.setFrequency(freq);
  
  println("Audio Hidden intensity: "+intensity);
}

void audioRenderFull(){
  
  if(currentLoad > maxLoad){
    intensity = 1;
    freq = HIGH;
  }else if(currentLoad > target.getValue()){
    //intensity =  (currentLoad-target.getValue())/(maxLoad-target.getValue());
    intensity =  (currentLoad-target.getValue())/(maxLoad-target.getValue());
    freq = HIGH;
  }else if(currentLoad < minLoad && currentLoad > zeroThreshold){
    intensity = 1;
    freq = LOW;
  }else if (currentLoad <= target.getValue() && currentLoad > zeroThreshold){
    intensity = 1 - (currentLoad-minLoad)/(target.getValue()-minLoad);
    freq = LOW;
  }else{
    intensity = 0;
  }
  
  Waveform waveForm = Waves.SQUARE;
  if(currentLoad <= successMax && currentLoad >= successMin){
    waveForm = Waves.SINE;
    intensity = pow(intensity,2);
  }else{
    intensity = pow(intensity,2.5);
    
  }
  println("Audio Full intensity: "+intensity);
  
    
  if(wave.getWaveform() != waveForm){
    wave.setWaveform(waveForm);
  }
  wave.setAmplitude(intensity);
  wave.setFrequency(freq);
}

void scaleRender(){
  fill(255,255,255);
  text("Load on :", width/2, 10*height/50);
  if(frameCount % 3 == 0)
  //if(frameCount % 1 == 0)
    scaleLoad = currentLoad;
  text(nf(scaleLoad,2,0)+" %", width/2, 14*height/50);
}

void visualBarRender(boolean hide){
  strokeWeight(1);
  bottomBar.drawBox();
  successBar.drawBox();
  topBar.drawBox();
  
  drawTriangle(hide); //Don't hide triangle in success zone
}

void drawTriangle(boolean hide){
  float targetY = barTopY + barHeight;  //Base case, load below minLoad;
  if(currentLoad > minLoad){
    targetY = barHeight * (maxLoad - currentLoad) / (maxLoad-minLoad);
    targetY += barTopY;
  }
  if(currentLoad >= maxLoad){
    targetY = barTopY;
  }

  if(currentLoad >= successMin && currentLoad <= successMax){
    tint(255,highTransparency);
    image(checkMark, floor(successBar.getX()), floor(successBar.getY() + 20));
    if(hide){
      return;
    }
  }else{
   tint(255,lowTransparency);
   image(checkMark, floor(successBar.getX()), floor(successBar.getY()+ 20));
  }
  
  float triWidth = width/50;
  triangle(width/2, targetY, width/2-triWidth, targetY-triWidth/2, width/2-triWidth, targetY+triWidth/2);
}

void summaryVisualRender(){
  println(previousAttemptLoad);
  if(previousAttemptLoad < 0){
    text("Push pen to target", width/2, 10*height/50);
  }else{
    text("Previous Attempt:", width/2, 10*height/50);
    text(nf(previousAttemptLoad,2,1)+" %", width/2, 14*height/50);
  }
  
  //if(targetReached == 1){
  if(targetReached == 1 && visCounter < 1){
    println("In here");
    visCounter = 0;  //Was 1 before
    runningSum = 0;
  }
  println(currentLoad +" "+ zeroThreshold + " " + visCounter + " " + valMemory);
  //if(currentLoad > zeroThreshold){
  if(targetReached == 1){
    if(visCounter < 0){
      return;
    }
    if(visCounter < valMemory){  //Queue of loads is too short
      visCounter++;
      runningSum += currentLoad;
      println("Running sum = "+nf(runningSum,2,1)+" , currentLoad = "+nf(currentLoad,2,1)+" , VisCounter = "+nf(visCounter,2,1));
      return;
    }else{
      tempAttempt = runningSum/(float)visCounter;
      println("Temp " + tempAttempt);
      //println("tabulating average, tempAttempt = "+nf(tempAttempt,2,1)+" , visCounter = "+visCounter+" , runningSum = "+nf(runningSum,2,1)+" currentLoad = "+nf(currentLoad,2,1));
      runningSum = 0;
      visCounter = -1;
      
    }
  }else{
    if(tempAttempt > 0){
      previousAttemptLoad = tempAttempt;
      tempAttempt = -1;
    }
  }
}

void attemptCounter(){
  /*attemptCount
  attemptDuration
  zeroDuration
  durationThreshold*/
  if(currentLoad > zeroThreshold && key == ' '){
    zeroDuration = 0;
    attemptDuration++;
  }else{
    zeroDuration++;
    if(zeroDuration > durationThreshold/2){
      if(attemptCount == attempt.getItems().size())
        return;
      if(attemptDuration > durationThreshold){
        attemptCount++;
        attempt.activate(attemptCount);
      }
      attemptDuration = 0;
    }
  }
}

void resetAttempts(){
  try{  //Some strange synchronization error is causing null pointer exceptions at start
    attemptCount = 0;
    attemptDuration = 0;
    zeroDuration = 0;
    attempt.activate(attemptCount);
  }catch(Exception e){
    println(e.getMessage());
  }
}

int activatedButton(RadioButton buts){
  for(int i=0; i<buts.getItems().size(); i++){
    if(buts.getState(i))
      return i;
  }
  return 0;
}

public void controlEvent(ControlEvent event) {
  if(event.isFrom(attempt)){
    attemptDuration = 0;
    zeroDuration = 0;
    attemptCount = activatedButton(attempt);
  }else if(event.isFrom(target)){
    setFeedbackBounds(target.getValue());
    resetAttempts();
  }else if(event.isFrom(condition)){
    wave.setAmplitude(0);
    previousAttemptLoad = -1;
    resetAttempts();
  }else if(event.isFrom(status)){
    resetAttempts();
    previousAttemptLoad = -1;
  }
}

void drawingSquare(){
      background(0);
    double targetPercentage = targetArr[(int)target.getValue()/20-1]/100;
    strokeWeight(10);
    stroke(255);
    if(lines[0]){
      line(width/2.5, height/2.5, width/1.5, height/2.5);
    }
    else{
      textSize(32);
      text("Start Here", width/2.5, height/2.5 - 40); 
    }
    if(startButton == 0){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/2.5, height/2.5, 30, 30); //Top Left
    
    stroke(255);
    if(lines[1]){
      line(width/1.5, height/1.5, width/1.5, height/2.5);
    }
    if(startButton == 1){
      stroke(0,255,0);
      ellipse(width/1.5, height/2.5, 30, 30); //Top Right
    }
    else{
      stroke(255);
      ellipse(width/1.5, height/2.5, 30, 30); //Top Right
    }


    stroke(255);
    if(lines[2]){
      line(width/1.5, height/1.5, width/2.5, height/1.5);
    }
   if(startButton == 2){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/1.5, height/1.5, 30, 30); //Bottom Right
    
    stroke(255);
    if(lines[3]){
      line(width/2.5, height/1.5, width/2.5, height/2.5);
    }
    if(startButton == 3){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/2.5, height/1.5,30, 30); //Bottom Left
    
    textSize(32);
    text("Go Clockwise", 120, 20);
     if (mousePressed) {
      int whichButton = whichClicked(mouseX, mouseY);
      if(whichButton != -1 && startButton == (whichButton)%4 && correctLine){
        startButton = (startButton+1)%4;
        println("Setting up line: " + whichButton);
        if(whichButton>0){
          lines[whichButton - 1] = true;
        }
        else{
          if(lines[0]){
            lines[3] = true;
          }
        }        
      }
        
      }
      strokeWeight(75 * tablet.getPressure());
      if(tablet.getPressure() <= targetPercentage+0.0999999999 && tablet.getPressure() >= targetPercentage-0.0999999999){
        stroke(0,255,0);
        correctPressure = true;
      }
      else{
        stroke(255,0,0);
        correctPressure = false;
      }
      if(correctLine && !correctPressure){
        println("Error");
        startButton--;
        if(startButton == -1){
          startButton = 3; 
        }
        correctLine = false;
      }
      textSize(32);
      line(pmouseX, pmouseY, mouseX, mouseY);  
}

void drawingSquareNoPractice(){
      background(0);
    double targetPercentage = targetArr[(int)target.getValue()/20-1]/100;
    strokeWeight(10);
    stroke(255);
    if(lines[0]){
      line(width/2.5, height/2.5, width/1.5, height/2.5);
    }
    else{
      textSize(32);
      text("Start Here", width/2.5, height/2.5 - 40); 
    }
    if(startButton == 0){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/2.5, height/2.5, 30, 30); //Top Left
    
    stroke(255);
    if(lines[1]){
      line(width/1.5, height/1.5, width/1.5, height/2.5);
    }
    if(startButton == 1){
      stroke(0,255,0);
      ellipse(width/1.5, height/2.5, 30, 30); //Top Right
    }
    else{
      stroke(255);
      ellipse(width/1.5, height/2.5, 30, 30); //Top Right
    }


    stroke(255);
    if(lines[2]){
      line(width/1.5, height/1.5, width/2.5, height/1.5);
    }
   if(startButton == 2){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/1.5, height/1.5, 30, 30); //Bottom Right
    
    stroke(255);
    if(lines[3]){
      line(width/2.5, height/1.5, width/2.5, height/2.5);
    }
    if(startButton == 3){
      stroke(0,255,0);
    }
    else{
      stroke(255);
    }
    ellipse(width/2.5, height/1.5,30, 30); //Bottom Left
    
    textSize(32);
    text("Go Clockwise", 120, 20);
     if (mousePressed) {
      int whichButton = whichClickedNoPractice(mouseX, mouseY);
      if(whichButton != -1 && startButton == (whichButton)%4 && correctLine){
        startButton = (startButton+1)%4;
        println("Setting up line: " + whichButton);
        if(whichButton>0){
          lines[whichButton - 1] = true;
        }
        else{
          if(lines[0]){
            lines[3] = true;
          }
        }        
      }
        
      }
      strokeWeight(40);
      if(tablet.getPressure() <= targetPercentage+0.0999999999 && tablet.getPressure() >= targetPercentage-0.0999999999){
        correctPressure = true;
      }
      else{
        correctPressure = false;
      }
      textSize(32);
      stroke(100,100,255);
      line(pmouseX, pmouseY, mouseX, mouseY);  
}
void exit(){
  try{
    closeFile();
    output.flush(); // Writes the remaining data to the file
    output.close(); // Finishes the file
  }catch(Exception e){
    println("Error closing file");
  }
  super.exit();
}

int whichClicked(double x, double y){
   int clickedOn = -1;
   if(Math.sqrt((x-width/2.5)*(x-width/2.5) + (y-height/2.5)*(y-height/2.5)) < 30 && correctPressure){
     clickedOn = 0;
     if(startButton == 0){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/1.5)*(x-width/1.5) + (y-height/2.5)*(y-height/2.5)) < 30 && correctPressure){
     clickedOn = 1;
     if(startButton == 1){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/1.5)*(x-width/1.5) + (y-height/1.5)*(y-height/1.5)) < 30 && correctPressure){
     clickedOn = 2;
     if(startButton == 2){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/2.5)*(x-width/2.5) + (y-height/1.5)*(y-height/1.5)) < 30 && correctPressure){
     clickedOn = 3;
     if(startButton == 3){
       correctLine = true;
     }
   }
   return clickedOn;  
}

int whichClickedNoPractice(double x, double y){
   int clickedOn = -1;
   if(Math.sqrt((x-width/2.5)*(x-width/2.5) + (y-height/2.5)*(y-height/2.5)) < 30){
     clickedOn = 0;
     if(startButton == 0){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/1.5)*(x-width/1.5) + (y-height/2.5)*(y-height/2.5)) < 30){
     clickedOn = 1;
     if(startButton == 1){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/1.5)*(x-width/1.5) + (y-height/1.5)*(y-height/1.5)) < 30){
     clickedOn = 2;
     if(startButton == 2){
       correctLine = true;
     }
   }
   else if(Math.sqrt((x-width/2.5)*(x-width/2.5) + (y-height/1.5)*(y-height/1.5)) < 30){
     clickedOn = 3;
     if(startButton == 3){
       correctLine = true;
     }
   }
   return clickedOn;  
}
/*
void summaryVisualRender(){
  //Framerate is approx 30 fps
  
  if(previousAttemptLoad < 0){
    text("Load cane to target", width/2, 10*height/50);
  }else{
    text("Previous Attempt:", width/2, 10*height/50);
    text(nf(previousAttemptLoad,2,1)+" lbs", width/2, 14*height/50);
  }
  
  if(currentLoad > zeroThreshold){
    if(prevVals.size() < valMemory){  //Queue of loads is too short
      return;
    }
    float min = 1050;  //Arbitrarily high number
    float max = -1;
    float listMean = 0;
    int count = 0;
    for(int i = 0; i < prevVals.size(); i++){
      if(prevVals.get(i) < zeroThreshold){
        continue;
      }
      listMean += prevVals.get(i);
      count++;
      if(prevVals.get(i) > max){
        max = prevVals.get(i);
      }
      if(prevVals.get(i) < min){
        min = prevVals.get(i);
      }
    }
    listMean = listMean/(float)count;
    if(max - min < thresholdLoadRange){  //valMemory number of samples must be within thresholdLoadRange of each other to consider it a possible attempt
      tempAttempt = listMean;
    }
  }else{
    if(tempAttempt > 0){
      previousAttemptLoad = tempAttempt;
      tempAttempt = -1;
    }
  }
}*/
