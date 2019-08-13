import java.awt.geom.*;

class Box {
  float x, y, w, h;
  float cx, cy;
  int degrees;
  int size;
  color fillColor;
  
  int transparency = 127;
  int transSensitivity = 10;
  int rotSensitivity = 15;

  AffineTransform aff;
  double[] checkPoint;
  float ox, oy;
  int value;

  public Box(float newX, float newY, float newW, float newH, int valueIn) { 
    x = 0 - newW/2;  //Left of box relative to origin of page
    y = 0 - newH/2;  //Top of box relative to origin of page 
    w = newW;
    h = newH;
    cx = newX + w/2;  //Defines position of origin's x (relative to the screen frame)
    cy = newY + h/2;  //Defines position of origin's y (relative to the screen frame)
    degrees = 0;
    size = 1;
    
    fillColor = color(0,0,0);
    value = valueIn;

    aff = new AffineTransform();
    checkPoint = new double[2];
  }

  void drawBox() {
    pushMatrix();
    //translate(200,200);
    translate(cx, cy);
    rotate(radians(degrees));
    scale(size);
    fill(fillColor, transparency);
    stroke(255,255,255);
    rect(x, y, w, h);
    
    textAlign(CENTER, CENTER);
    textSize(20);
    fill(255,255,255);
    if(value >= 0){
      text(str(value), x, y, w, h);
    }else{
      switch(value){
        case -1:
          text("demo", x, y, w, h);
        break;
        case -2:
          text("practice", x, y, w, h);
        break;
        case -3:
          text("trial", x, y, w, h);
        break;
        case -4:
          //text("verbal", x, y, w, h);
          text("vis hidden", x, y, w, h);
        break;
        case -5:
          text("audio", x, y, w, h);
        break;
        case -6:
          text("vis regular", x, y, w, h);
        break;
      }
    }

    popMatrix();
  }
  
  //Translation methods
  void translateLeft(){
    cx = cx-transSensitivity;
    checkConstraints();
    //drawBox();
  }
  void translateRight(){
    cx = cx+transSensitivity;
    checkConstraints();
    //drawBox();
  }
  void translateUp(){
    cy = cy-transSensitivity;
    checkConstraints();
    //drawBox();
  }
  void translateDown(){
    cy = cy+transSensitivity;
    checkConstraints();
    //drawBox();
  }
  
  //Rotation method
  void rotateBox(boolean up){
    if(up){
      degrees = degrees + rotSensitivity;
    }
    else{
      degrees = degrees - rotSensitivity;
    }
    //drawBox();
  }
  
  //transparency method
  void changeFill(boolean up){
    if(up){
      transparency = transparency + transSensitivity;
    }
    else{
      transparency = transparency - transSensitivity;
    }
    //drawBox();
  }
  
  //transparency method
  void setFill(int transLevel){
    if(transLevel > 1){
      transparency = 1;
    }
    else if(transLevel < 0){
      transparency = 0;
    }else{
      transparency = transLevel;
    }
    //drawBox();
  }
  
  //set color method
  void setColor(color colorIn){
    fillColor = colorIn;
  }
  
  void checkConstraints(){
    //cx = constrain(cx,w/2,mouseControl.maxX-w/2);
    //cy = constrain(cy,h/2,mouseControl.maxY-h/2);
  }

  
  boolean checkForHit(float x, float y) {
    if (contains(x, y)) {
      //fillColor = color(255,255,0);
      return true;
    }
    else {
      //fillColor = color(0,0,255);
      return false;
    }
  }

  boolean contains(float px, float py) {
    aff.setToTranslation(cx, cy);
    aff.rotate(radians(degrees));
    aff.scale(size, size);
    // Store incoming coordinates in array for transforming
    checkPoint[0] = px; 
    checkPoint[1] = py;
    try {
      // Reverse the applied transformation to the coordinates 
      aff.inverseTransform(checkPoint, 0, checkPoint, 0, 1);
      ox = (float) checkPoint[0];
      oy = (float) checkPoint[1];
    } 
    catch (NoninvertibleTransformException e) {
      // Unable to invert point so not over shape
      return false;
    }
    // Is [ox,oy] over the un-transformed shape
    return (ox >= x && ox <= (y + w) && oy >= y && oy <= (y + h));
  }
  
  int getValue(){
   return value; 
  }
  
  float getX(){
    return cx+x;
  }
  
  float getY(){
    return cy+y;
  }
}
