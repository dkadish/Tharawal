//package com.davidkadish.floatimage;

import processing.core.PApplet;
import processing.core.PConstants;
import processing.core.PImage;

import papaya.*;
import org.ejml.simple.SimpleMatrix;

public class FloatImage{  
  //double[][] pixels;
  SimpleMatrix pixels;
  int width, height;
  
  public FloatImage(){
  }  
  
  public FloatImage(PImage _img){
    this.fromPImage(_img);
  }
  
  public void fromPImage(PImage _img){
    width = _img.width;
    height = _img.height;
    
    _img.loadPixels();
    pixels = new SimpleMatrix(_img.pixels.length,4);//double[_img.pixels.length][4]; // Create an array of the right length
    for(int i = 0; i < _img.pixels.length; i++){
      pixels.set(i,3, _img.pixels[i] >> 24 & 0xFF);
      pixels.set(i,0, _img.pixels[i] >> 16 & 0xFF);
      pixels.set(i,1, _img.pixels[i] >> 8 & 0xFF);
      pixels.set(i,2, _img.pixels[i] & 0xFF);
      
      // Set pixels as new values in array.
      /*pixels[i][0] = (float)r/255.0;
      pixels[i][1] = (float)g/255.0;
      pixels[i][2] = (float)b/255.0;
      pixels[i][3] = (float)a/255.0;*/
    }
    
    pixels.divide(255.0);
    //pixels = Mat.divide(pixels, 255.0);
    
  }
  
  public PImage toPImage(){
    PImage _img = createImage(width, height, ARGB);
    _img.loadPixels();
    
    //float intPix[][] = Mat.multiply(pixels,255.0);
    
    for (int i = 0; i < pixels.length; i++) {
      _img.pixels[i] = (((int)intPix[i][3]) << 24) +
                       (((int)intPix[i][0]) << 16) +
                       (((int)intPix[i][1]) << 8) +
                        (int)(intPix[i][2]);
     /*_img.pixels[i] = color(
                          (int)(_img.pixels[i][0]),
                          (int)(_img.pixels[i][1]),
                          (int)(_img.pixels[i][2]),
                          (int)(_img.pixels[i][3])
                         );*/
    }
    _img.updatePixels();
    return _img;
  }
  
  public void blend(FloatImage src, int sx, int sy, int sw, int sh, int dx, int dy, int dw, int dh, int mode){
    switch(mode){
      case BLEND:
        float invA[] = Mat.sum(Mat.multiply(Mat.column(pixels,3), 1), 1);//1.0 - pixels[i][3]
        float invAsrc[] = Mat.sum(Mat.multiply(Mat.column(src.pixels,3), 1), 1);//1.0 - src.pixels[i][3]
        float a[] = Mat.sum(Mat.column(pixels,3), Mat.multiply(Mat.column(src.pixels,3), invA)); // pixels[i][3] + src.pixels[i][3]*(1.0 - pixels[i][3]);
        
        //float 
        
        for(int i=0; i<src.pixels.length; i++){ //<>//
          // From https://en.wikipedia.org/wiki/Alpha_compositing#Alpha_blending
          //float a = pixels[i][3] + src.pixels[i][3]*(1.0 - pixels[i][3]); //<>//
          float r=0.0, g=0.0, b=0.0; //<>//
          if( a[i] > 0.0 ){ //<>//
            r = ( src.pixels[i][0]*src.pixels[i][3] + pixels[i][0]*pixels[i][3]*(invAsrc[i]) ) / a[i]; //<>//
            g = ( src.pixels[i][1]*src.pixels[i][3] + pixels[i][1]*pixels[i][3]*(invAsrc[i]) ) / a[i]; //<>//
            b = ( src.pixels[i][2]*src.pixels[i][3] + pixels[i][2]*pixels[i][3]*(invAsrc[i]) ) / a[i]; //<>//
          }
          pixels[i][0] = r;
          pixels[i][1] = g;
          pixels[i][2] = b;
          pixels[i][3] = a[i];
        }
        break;
      default:
        println("Sorry, " + mode + " mode is not handled yet");
        break;
    }
  }
  
  public void fade(float by){
    for( int i=0; i<pixels.length; i++ ){
      pixels[i][3] *= by;
    }
  }
}