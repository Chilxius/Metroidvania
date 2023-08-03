     //*******************************//
     //            DEBRIS             //
     // This object contains the data //
     // for falling debris animation. //
//*****************************************//
//                  DATA                   //
//                                         //
// x1, y1 -> top-left piece's location     //
// x2, y2 -> top-right piece's location    //
// x3, y3 -> bottom-left piece's location  //
// x4, y4 -> bottom-right piece's location //
//                                         //
// xSpd -> pieces' horizontal speed        //
// ySpd -> pieces' vertical speed          //
//                                         //
// rotation -> tracks rotation of pieces   //
//*****************************************//
//            METHODS           //
//                              //
// Debris( Block b )            //
//                              //
// boolean moveAndDraw()        //
//******************************//
class Debris
{
  float x1, y1;
  float x2, y2;
  float x3, y3;
  float x4, y4;
  
  float xSpd, ySpd;
  
  float rotation = 0;
  
  public Debris( Block b )
  {
    //Top left
    x1 = b.xPos+blockSize*0.25;
    y1 = b.yPos+blockSize*0.25;
    
    //Top right
    x2 = b.xPos+blockSize*0.75;
    y2 = b.yPos+blockSize*0.25;
    
    //Bottom left
    x3 = b.xPos+blockSize*0.25;
    y3 = b.yPos+blockSize*0.75;
    
    //Bottom right
    x4 = b.xPos+blockSize*0.75;
    y4 = b.yPos+blockSize*0.75;
    
    //Set Speeds
    xSpd = 3;
    ySpd = -7;
  }
  
  public boolean moveAndDraw()
  {
    //Move each piece and rotate
    rotation += 0.1;
    x1-=xSpd;     y1+=ySpd-0.5;
    x2+=xSpd;     y2+=ySpd-0.5;
    x3-=xSpd-0.5; y3+=ySpd;
    x4+=xSpd-0.5; y4+=ySpd;
    
    ySpd += 0.5;
    
    //Draw the four pieces
    push(); translate( x1+xOffset, y1+yOffset ); rotate( -rotation + PI ); image( effectImage[7], 0, 0 ); pop();
    push(); translate( x2+xOffset, y2+yOffset ); rotate( rotation*1.2 );      image( effectImage[7], 0, 0 ); pop();
    push(); translate( x3+xOffset, y3+yOffset ); rotate( -rotation*1.3 + PI ); image( effectImage[7], 0, 0 ); pop();
    push(); translate( x4+xOffset, y4+yOffset ); rotate( rotation*1.4 );      image( effectImage[7], 0, 0 ); pop();
    
    if( y1+yOffset > height ) //blocks off screen
      return true;
    return false;
  }
}
