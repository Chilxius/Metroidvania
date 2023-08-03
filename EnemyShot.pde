      //************************************//
      //              ENEMYSHOT             //
      // This object contains the location  //
      // and data for the enemies' shots.   //
//*************************************************//
//                      DATA                       //
//                                                 //
// xPos -> shot's X location in the drawing window //
// yPos -> shot's Y location in the drawing window //
// xSpd -> shot's rate of horizontal movement      //
// ySpd -> shot's rate of vertical movement        //
//                                                 //
// speed -> speed of the projectile                //
//*************************************************//

class EnemyShot
{
  float xPos, yPos;
  float xSpd, ySpd;
  float speed;
  
  public EnemyShot( Enemy e, Player p, float s )
  {
    speed = s;
    
    //Set origin of shot
    xPos = e.xPos;
    yPos = e.yPos;
    
    //Determine speed based on vector subtraction
    xSpd = p.xPos-xPos;
    ySpd = p.yPos-yPos;
    
    //Divide speeds based on speed variable
    xSpd /= dist(e.xPos,e.yPos,p.xPos,p.yPos)/speed;
    ySpd /= dist(e.xPos,e.yPos,p.xPos,p.yPos)/speed;
  }
  
  public boolean moveAndDraw() //Returns true if it is off screen
  {
    //Draw shot
    fill(200);
    circle(xPos+xOffset,yPos+yOffset,10);
    
    //Move shot
    xPos += xSpd;
    yPos += ySpd;
    
    //Check to see if the shot is off screen and remove it
    if( !onScreen() )
      return true;
      
    //Check to see if the shot has hit the player
    if( dist( xPos, yPos, player.xPos, player.yPos ) < 20 )
    {
      player.getHurt( xPos );
      return true;
    }
      
    //Check to see if the shot has hit a wall
    if( currentBlock().type == BlockType.WALL || currentBlock().type == BlockType.STAIR_MARKER )
      return true;
      
    return false;
  }
  
  //Reports which block the shot is in, unless they are off the map
  public Block currentBlock()
  {
    if( yPos < 0 || yPos > world[currentMap].ySize*blockSize )
      return world[currentMap].block[0][0];
    return world[currentMap].block[int(xPos/blockSize)][int(yPos/blockSize)];
  }
    
  private boolean onScreen()
  {
    if( xPos+xOffset > -blockSize && xPos+xOffset < width && yPos+yOffset > -blockSize && yPos+yOffset < height )
      return true;
    return false;
  }
}
