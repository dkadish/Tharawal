/* Code for Cheryl L'Hirondelle's piece for the Campbelltown Arts Centre in Australia 
* 
* USAGE:
* 'b' - Re-calibrate background
* 'd' - Adjust the depth threshold offset. Makes the thresholding more or less sensitive
* 'f' - Adjust how much new images fade. Affects how quickly people appear in the scene.
* 'g' - Adjust how much the ghostly composite fades. Affects how quickly people disappear from the scene.
* 'm' - Toggle show/hide the cursor
* 'r' - Show/hide the framerate
*
* '1' - Presentation mode (this is the default and what should be shown)
* '2' - Depth image view (what the Kinect sees)
* '3' - Colour depth image (the colour version of what the Kinect is seeing)
* '4' - Foreground image (the thresholded version, excluding the background)
* '5' - Ghostly image (the faded version of the image)
*/


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
float depthThresholdOffset = 0.05;

static int MIN_DEPTH=10; // One is as close as we can go because zero is TOO far
static int MAX_DEPTH=4500; // the largest

boolean showCursor = false, showFrameRate = false;

public enum DisplayMode {
  GHOSTLY, DEPTH, COLOUR, FOREGROUND, FOREGROUND_FLOAT, FOREGROUND_FADE, BACKGROUND
}

DisplayMode mode;

void setup() {
  //fullScreen(FX2D);
  size(512, 424, FX2D);
  
  noCursor();
  //size(displayWidth, displayHeight);
  kinect = new Kinect2(this);
  kinect.initDepth();
  kinect.initRegistered();
  kinect.initDevice();
  
  // Load the background
  backgroundVideo = new Movie(this, "loop-1280x800.mp4");
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
  
  noSmooth(); // Speeds up drawing by not interpolating pixels
  //noLoop(); // Doesn't call draw automagically
  //frameRate(30); // Sets the maximum framerate to be 30 frames/sec
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
    case BACKGROUND:
      background(255);
      PImage bg = createImage(width, height, RGB);
      bg.loadPixels();
      for( int i=0; i < backgroundDepth.length; i++ ){
        bg.pixels[i] = color((int)map((float)backgroundDepth[i], 0.0, 4500.0, 0.0, 255.0)); // Scale to 255
      }
      bg.updatePixels();
      image(bg, 0, 0, width, height);
      break;
  }
  
  if (showFrameRate){
      text(frameRate, width/2, height/2);
  }
  
  // Fade the old image
  ghostlyImage.fade(ghostlyImageFade);

  //println("Framerate: " + int(frameRate));
}

void setBackgroundDepth() {
  int[] minDepth = new int[backgroundDepth.length];
  for( int i=0; i < minDepth.length; i++ ){
    minDepth[i] = MAX_DEPTH; // As far away as possible
  }
  
  printArray(subset(minDepth,0,20));
  
  for( int i=0; i<10; i++ ){
    int[] newDepth = kinect.getRawDepth();
    for( int j=0; j<minDepth.length; j++ ){
      if( newDepth[j] < minDepth[j] && newDepth[j] > MIN_DEPTH){ // if the new reading is closer
        minDepth[j] = newDepth[j];
      }
    }
    delay(100);
  }
  printArray(subset(minDepth,0,20));
  
  backgroundDepth = minDepth; // Get the background image
}

PImage removeBackground(PImage img, int[] depth) {
  // NOTE: Close is high values, Far is low values
  // NOTE (AGAIN, I THINK): Close is low values, but zero is REALLY FAR
  img.loadPixels();
  for ( int i=0; i<img.pixels.length; i++ ) {
    // If it's background, get rid of it
    if ( (depth[i] >= ((1.0-depthThresholdOffset) * backgroundDepth[i])) || depth[i] < MIN_DEPTH ) {
        img.pixels[i] = color(0, 0, 0, 0);
    }
  }
  img.updatePixels();
  
  //img.resize(img.width, img.height);
  
  return img;
}

void keyPressed() {
  println(key);
  if (key == 'b' || key == 'B') {
    println("Resetting background...");
    setBackgroundDepth();
  } else if ( key == '1' ){
    mode = DisplayMode.GHOSTLY;
  } else if ( key == '2' ){
    mode = DisplayMode.DEPTH;
  } else if ( key == '3' ){
    mode = DisplayMode.COLOUR;
  } else if ( key == '4' ){
    mode = DisplayMode.FOREGROUND; // Improper handling of objects in foreground
  } /*else if ( key == '5' ){
    mode = DisplayMode.FOREGROUND_FLOAT; //Still Colour
  }*/ else if ( key == '5' ){
    mode = DisplayMode.FOREGROUND_FADE; // Black
  }  else if ( key == '6' ){
    mode = DisplayMode.BACKGROUND; // Black
  } else if ( key == 'd' || key == 'D' ){ // Adjust the depth (0.95): Zero -> No buffer, One -> Too much buffer
    depthThresholdOffset = ((float)mouseY) / height;
    println("New depth threshold offset: " + depthThresholdOffset);
  } else if ( key == 'f' || key == 'F' ){ // Adjust the fade on new frames (0.01): 0 -> total fade, 1 -> no fade
    newImageFade = ((float)mouseY) / height;
    println("New new image fade: " + newImageFade);
  } else if ( key == 'g' || key == 'G' ){ // Adjust the composite image fade (0.99): 0 -> total fade, 1 -> no fade
    ghostlyImageFade = ((float)mouseY) / height;
    println("New ghostly image fade: " + ghostlyImageFade);
  } else if( key == 'm' || key == 'M' ){
    if( showCursor ){
      noCursor();
      showCursor = false;
    } else {
      cursor();
      showCursor = true;
    }
  } else if( key == 'r' ){
    if( showFrameRate ){
      showFrameRate = false;
    } else {
      showFrameRate = true;
    }
  }
}

// Called every time a new frame is available to read
void movieEvent(Movie m) {
  m.read();
  //redraw();
}