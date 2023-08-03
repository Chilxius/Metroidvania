      //************************************//
      //              PLAYERSHOT            //
      // This object contains the location  //
      // and data for the player's shots.   //
//*************************************************//
//                      DATA                       //
//                                                 //
// xPos -> shot's X location in the drawing window //
// yPos -> shot's Y location in the drawing window //
// xSpd -> shot's rate of horizontal movement      //
// ySpd -> shot's rate of vertical movement        //
//                                                 //
// duration -> how much longer the shot persists   //
// bigFire -> tracks if magic is a big fireball    //
// size -> size of the projectile                  //
//*************************************************//
//             METHODS               //
//                                   //
// PlayerShot( Player p )            //
//                                   //
// void drawShot()                   //
// boolean moveShot()                //
//                                   //
// Block currentBlock()              //
//***********************************//

class PlayerShot
{
  float xPos, yPos;
  float xSpd, ySpd;
  int duration;
  int bigFire;
  
  float size = 40;
  
  Power type;
  
  public PlayerShot( Player p )
  {
    xPos = p.xPos;
    yPos = p.yPos;
    
    if( p.facingLeft ) xPos -= p.size/2;
    else               xPos += p.size/2;
    
    type = p.power;
    
    if( type == Power.ICE )
    {
      xSpd = p.maxRunSpeed+1;
      if( p.facingLeft ) xSpd = -xSpd;
      ySpd = 0; //horizontal shot
      duration = 100;
    }
    
    if( type == Power.FIRE )
    {
      if( p.fireCharge < 30 ) //not charged enough to fire
      {
        duration = 0;
        type = Power.NONE;
        return;
      }
      
      xSpd = p.fireCharge/4;
      if( p.facingLeft ) xSpd = -xSpd;
      ySpd = 0; //horizontal shot
      duration = (p.fireFullCharge+25) - p.fireCharge;
      if( p.fireCharge == p.fireFullCharge ) //Fully charged
        bigFire = 2;
    }
  }
  
  //Draws the shot based on its type
  public void drawShot()
  {
    switch( type )
    {
      case ICE:
        push(); translate(xPos+xOffset, yPos+yOffset); noStroke(); fill(170,170,255,100); circle(0,0,size); rotate(duration/10.0); image( effectImage[2], 0,0); pop();
        break;
      case FIRE:
        if( xSpd > 0 ) image( effectImage[3+bigFire], xPos+xOffset, yPos+yOffset ); //Going right
        else           image( effectImage[4+bigFire], xPos+xOffset, yPos+yOffset ); //Going left
        break;
    }
  }
  
  //Moves the shot and returns TRUE if it hits an enemy or obstacle
  public boolean moveShot()
  {
    switch( type )
    {
      case ICE:
        xPos += xSpd;
        duration--;
        if( duration <= 0 )
          return true;
      break;
      
      case FIRE:
        xPos += xSpd;
        duration--;
        if( duration <= 0 || currentBlock().blocksFire( bigFire ) )
        {
          if( player.fireball == this )
          {
            player.inAFireball = false;
            player.ySpd = -5;
          }
          return true;
        }
      break;
      
      case NONE: //non-powers
        return true;
    }
    
    return false;
  }
  
  //Reports which block the shot is in, unless they are off the map
  public Block currentBlock()
  {
    if( yPos < 0 || yPos > world[currentMap].ySize*blockSize )
      return world[currentMap].block[0][0];
    return world[currentMap].block[int(xPos/blockSize)][int(yPos/blockSize)];
  }
}
