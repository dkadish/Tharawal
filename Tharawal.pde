import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;
Kinect2 kinect;

import processing.video.*;
Movie backgroundVideo;

int[] backgroundDepth;
FloatImage ghostlyImage;

float newImageFade = 0.01;
float ghostlyImageFade = 0.99;
float depthThresholdOffset = 0.95;

static int MIN_DEPTH_INIT=100;

public enum DisplayMode {
  GHOSTLY, DEPTH, COLOUR, FOREGROUND, FOREGROUND_FLOAT, FOREGROUND_FADE
}

DisplayMode mode;

void setup() {
  fullScreen();
  //size(displayWidth, displayHeight);//size(512, 424);
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initRegistered();
  kinect.initDevice();
  
  // Load the background
  backgroundVideo = new Movie(this, "loop.mp4");
  backgroundVideo.loop();
  
  backgroundDepth = new int[kinect.getRawDepth().length];
  //println(kinect.getRawDepth().length + " " + kinect.getRegisteredImage().width*kinect.getRegisteredImage().height);
  setBackgroundDepth();

  PImage foreground = removeBackground(
    kinect.getRegisteredImage().copy(), 
    kinect.getRawDepth()
    );

  ghostlyImage = new FloatImage(foreground);
  ghostlyImage.fade(newImageFade);
  
  mode = DisplayMode.GHOSTLY;
}

void draw() {
  image(backgroundVideo, 0, 0, width, height);

  PImage foreground = removeBackground(
    kinect.getRegisteredImage().copy(), 
    kinect.getRawDepth()
    );

  FloatImage foregroundFloat = new FloatImage(foreground.copy());
  foregroundFloat.fade(newImageFade);

  // Blend with new foreground
  ghostlyImage.blend(foregroundFloat, 0, 0, width, height, 0, 0, width, height, BLEND); //<>//

  switch( mode ){
    case GHOSTLY:
      image(ghostlyImage.toPImage(), 0, 0, width, height);
      break;
    case DEPTH:
      background(255);
      image(kinect.getDepthImage(), 0, 0, width, height);
      break;
    case COLOUR:
      background(255);
      image(kinect.getRegisteredImage(), 0, 0, width, height);
      break;
    case FOREGROUND:
      background(255);
      image(foreground, 0, 0, width, height);
      break;
    case FOREGROUND_FLOAT:
      background(255);
      image(foregroundFloat.toPImage(), 0, 0, width, height);
      break;
    case FOREGROUND_FADE:
      background(255);
      image(ghostlyImage.toPImage(), 0, 0, width, height);
      break;
  }
  
  // Fade the old image
  ghostlyImage.fade(ghostlyImageFade);

  //println("Framerate: " + int(frameRate));
}

void setBackgroundDepth() {
  int[] minDepth = new int[backgroundDepth.length];
  for( int i=0; i < minDepth.length; i++ ){
    minDepth[i] = MIN_DEPTH_INIT;
  }
  
  for( int i=0; i<10; i++ ){
    int[] newDepth = kinect.getRawDepth();
    for( int j=0; j<minDepth.length; j++ ){
      if( newDepth[j] > minDepth[j] ){
        minDepth[j] = newDepth[j];
      }
    }
    delay(100);
  }
  
  backgroundDepth = minDepth; // Get the background image
}

PImage removeBackground(PImage img, int[] depth) {
  // NOTE: Close is high values, Far is low values
  img.loadPixels();
  //println(depth[100] + ", " + backgroundDepth[100] + ", " + DEPTH_THRESHOLD_OFFSET*backgroundDepth[100]);
  //println(img.pixels.length);
  float bgPercent = 0.0, bgDepth = 0.0, newDepth = 0.0,
    remNew = 0.0, remOld = 0.0, keepNew = 0.0, keepOld = 0.0;
  for ( int i=0; i<img.pixels.length; i++ ) {
    // If it's background, get rid of it
    newDepth += depth[i];
    bgDepth += backgroundDepth[i];
    if ( depth[i] <= ((1.0+depthThresholdOffset) * backgroundDepth[i]) ) {
      bgPercent = bgPercent + 1.0;
        img.pixels[i] = color(0, 0, 0, 0);
    }
  }
  //println( "Background Pixels " + bgPercent*100.0/img.pixels.length + "% " + newDepth /img.pixels.length + " " +  bgDepth /img.pixels.length + " " + (1.0+depthThresholdOffset) + " " + (1.0+depthThresholdOffset) * bgDepth /img.pixels.length);
  img.updatePixels();
  return img;
}

void keyPressed() {
  if (key == 'b') {  
    setBackgroundDepth();
  } else if ( key == '1' ){
    mode = DisplayMode.GHOSTLY;
  } else if ( key == '2' ){
    mode = DisplayMode.DEPTH;
  } else if ( key == '3' ){
    mode = DisplayMode.COLOUR;
  } else if ( key == '4' ){
    mode = DisplayMode.FOREGROUND; // Improper handling of objects in foreground
  } else if ( key == '5' ){
    mode = DisplayMode.FOREGROUND_FLOAT; //Still Colour
  } else if ( key == '6' ){
    mode = DisplayMode.FOREGROUND_FADE; // Black
  } else if ( key == 'd' ){ // Adjust the depth (): Zero -> No buffer, One -> Too much buffer
    depthThresholdOffset = ((float)mouseY) / height;
    println("New depth threshold offset: " + depthThresholdOffset);
  } else if ( key == 'f' ){ // Adjust the fade on new frames (0.1): 0 -> total fade, 1 -> no fade
    newImageFade = ((float)mouseY) / height;
    println("New new image fade: " + newImageFade);
  } else if ( key == 'g' ){ // Adjust the composite image fade (0.9): 0 -> total fade, 1 -> no fade
    ghostlyImageFade = ((float)mouseY) / height;
    println("New ghostly image fade: " + ghostlyImageFade);
  }
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
}