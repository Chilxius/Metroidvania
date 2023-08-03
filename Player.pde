       //************************************//
       //               PLAYER               //
       // This object contains the data and  //
       // methods for the player character.  //
//***************************************************//
//                      DATA                         //
//                                                   //
// xPos -> player's X location in the drawing window //
// yPos -> player's Y location in the drawing window //
// xSpd -> player's rate of horizontal movement      //
// ySpd -> player's rate of vertical movement        //
// accel -> player's rate of horizontal acceleration //
// bSpeed -> speed bonus from holding the "b" button //
//                                                   //
// size -> size of the player                        //
//        (assumed to be less than size of blocks)   //
//                                                   //
// maxFallSpeed -> speed cap for falling             //
// maxSideSpeed -> speed cap for movement            //
// maxRunSpeed  -> speed cap for running             //
//                                                   //
// lf / rt / dn -> tracks if LEFT/RIGHT/DOWN are     //
//              pressed. Also applies to A / D / S   //
//                                                   //
// jp -> tracks if jump button is pressed            //
// landed -> tracks if player is on the ground       //
// facingLeft -> tracks if the player is facing left //
//                                                   //
// hopX / hopY -> tracks location of where player    //
//     was when they hopped down through a platform. //
// bounceDirection -> tracks which direction the     //
//     player was bounced by a bounce block          //
//                                                   //
// coins -> tracks the number of coins collected     //
// keys -> tracks the number of keys collected       //
//                                                   //
// Power power -> tracks which power the player      //
//           currently has (including NONE)          //
//                                                   //
// windPowerTimer -> tracks timer for wind cooldown  //
// icePowerTimer -> tracks time for ice cooldown     //
// fireCharge -> tracks charge for fire attack       //
// fireFullCharge -> value of full fire charge       //
// canUseWind -> tracks if wind can be used          //
// chargingFire -> tracks if fire is being charged   //
// inAFireball -> tracks if player is in a fireball  //
// fireball -> tracks the fireball the player is in  //
//                                                   //
// hurtFrames -> tracks invulnerability frames       //
//                                                   //
// Block blankBlock -> used for when the player is   //
//            out of bounds to avoid errors          //
//                                                   //
// WORK IN PROGRESS                                  //
//***************************************************//
//             METHODS               //
//                                   //
// Player( int, int )                //
//                                   //
// void drawPlayer()                 //
// void movePlayer()                 //
//                                   //
// void getHurt( float x )           //
// void dealWithDamage()             //
//                                   //
// void usePower()                   //
// void trackPower                   //
//                                   //
// void jump()                       //
//                                   //
// void moveTo( int, float, float )  //
//                                   //
// void snapToTop()                  //
// void snapToBottom()               //
// void snapToLeft()                 //
// void snapToRight()                //
//                                   //
// float top()                       //
// float bottom()                    //
// float left()                      //
// float right()                     //
//                                   //
// void bounce()                     //
//                                   //
// float top()                       //
// float bottom()                    //
// float left()                      //
// float right()                     //
//                                   //
// Block currentBlock()              //
//                                   //
// void checkForScroll()             //
//                                   //
//***********************************//

class Player
{
  float xPos, yPos;
  float xSpd, ySpd;
  float accel, bSpeed;
  float size;
  float maxFallSpeed;
  float maxSideSpeed;
  float maxRunSpeed;
  
  boolean lf, rt, dn; //moving in a direciton
  boolean jp, landed = true; //trying to jump / landed and ready to re-jump
  boolean facingLeft; //tracks the direction the player is facing
  
  int hopX, hopY;  //For hopping down through thin platforms - values are index of platform being hopped through
  int bounceDirection; //For when the player hits a bounce pad (0-NONE, 1-UP, 2-RIGHT, 3-DOWN, 4-LEFT)
  
  int coins, keys;  //Pickups
  
  Power power = Power.NONE;
  int windPowerTimer; //For tracking the tornado effect
  int icePowerTimer;  //For tracking ice attack
  int fireCharge; //For charging fire attack
  int fireFullCharge; //Value of max charge
  boolean canUseWind = true; //One burst per jump
  boolean chargingFire = false;
  boolean inAFireball = false;
  PlayerShot fireball = null; //tracks the fireball the player is in
  
  int hurtFrames; //invulnerability frames
  
  Block blankBlock = new Block(' ',-100,-100); //for avoiding out-of-bounds issues
  
  public Player( float x, float y )
  {
    xPos = x;
    yPos = y;
    
    accel = 0.5;
    bSpeed = 1;
    
    size = 40;
    
    maxFallSpeed = 15;
    maxSideSpeed = 15;
    maxRunSpeed = 2.5;
    
    hopX = 0;
    hopY = 0;
    
    fireFullCharge = 100;
  }
  
  public void drawPlayer()
  { 
    //Currently draws a blue circle - eventually will be animated image
    switch( power )
    {
      case FIRE: fill(200,0,0); break;
      case WIND: fill(0,200,0); break;
      case ICE:  fill(0,0,200); break;
      default:   fill(200);     break;
    }
    if( hurtFrames%6 < 3 ) //flicker when hurt
    {
      circle(xPos+xOffset,yPos+yOffset,size);
      fill(255);
      if(facingLeft) circle( xPos+xOffset-size/4, yPos+yOffset-size/4, size/3 );
      else           circle( xPos+xOffset+size/4, yPos+yOffset-size/4, size/3 );
    }
    
    //Fireball charge animation
    push(); noStroke(); fill( 200, fireCharge ,0, (fireCharge-10)*2.5 );
    circle( xPos+xOffset, yPos+yOffset, fireCharge/2 );
    pop();
    
    //Show tornado
    if( windPowerTimer > 10 )
      if( windPowerTimer%6<3 )
        { push(); imageMode(CENTER); image( effectImage[0], xPos+xOffset, yPos+yOffset ); pop(); }
      else
        { push(); imageMode(CENTER); image( effectImage[1], xPos+xOffset, yPos+yOffset ); pop(); }
    
    //Reports player's position - for testing
    //fill(255);
    //text(int(xPos/blockSize)+", "+int(yPos/blockSize) + "    " + doorFadeTimer,20,20);
    //text( landed + "    Debris: "+ debris.size(), 20, 40);
  }
  
  public void movePlayer()
  {
    //Fireball movement data
    if( inAFireball )
    {
      xPos = fireball.xPos;
      yPos = fireball.yPos;
      checkForScroll();
      return;
    }
    else if( power == Power.FIRE && chargingFire && fireCharge < fireFullCharge ) //Charge up fireball
    {
      fireCharge ++;
    }
    
    //If left is pressed
    if( lf && !usingDoor )
    {
      if(xSpd > -(maxRunSpeed+bSpeed) )
        xSpd -= accel;
      facingLeft = true;
    }
    xSpd = max( -maxSideSpeed, xSpd ); //speed cap
    
    //If right is pressed
    if( rt && !usingDoor )
    {
      if(xSpd < maxRunSpeed+bSpeed)
        xSpd += accel;
      facingLeft = false;
    }
    xSpd = min( maxSideSpeed, xSpd ); //speed cap
    
    //Move player
    if( currentBlock().type == BlockType.WATER )
    {
      xPos += xSpd/2;
      yPos += ySpd/2;
    }
    else
    {
      xPos+=xSpd;
      yPos+=ySpd;
    }
    
    //*********************//
    // Determining offset  //
    //from screen scrolling//
    //*********************//
    checkForScroll();
    //*********************//
    
    //Friction
    xSpd*=0.95; //Always
    if(landed && !lf && !rt)
      xSpd*=0.85; //Extra on ground
    
    //Hit block while falling (or walked up a stair)
    if( ySpd >= 0 && world[currentMap].hitTop(this) )
      snapToTop();
    else
    {
      if( currentBlock().type == BlockType.WATER )
        ySpd += 0.2;
      else
        ySpd += 0.7; //add gravity
      if( ySpd > 1 )
        landed = false;
      ySpd = min( maxFallSpeed, ySpd ); //cap fall speed
    }
    
    //Hit block while moving left/right/up
    if( world[currentMap].hitLeft(this) )
      snapToLeft();
    if( world[currentMap].hitRight(this) )
      snapToRight();
    if( world[currentMap].hitBottom(this) )
      snapToBottom();
    
    //Check for trap doors
    world[currentMap].checkTraps();
    
    //Try to jump if space is being pressed
    if( jp && !usingDoor )
      jump();
  }
  
  //Take damage and cue hurt frames
  public void getHurt( float x ) //position of enemy/shot that hurt the player
  {
    hurtFrames = 50;
    if( x < xPos )
      xSpd += 5;
    else
      xSpd -= 5;
  }
  
  public void dealWithDamage()
  {
    if( hurtFrames > 0 )
      hurtFrames--;
  }
  
  //Attempts to jump or hop down
  public void jump()
  {
    if( ySpd == 0.0 && landed )
    {
      if( !dn ) //Jump
        ySpd = -12;     // <- 13 is just enough to jump two squares with gravity of 1
      else //Hop down                  // changed to match new gravity
      {
        hopX = int(xPos/blockSize);
        hopY = int(yPos/blockSize)+1; //Add one because platform is below the player
      }
      landed = false; //No longer on the ground
    }
  }
  
  //Uses a power-up ability
  public void usePower()
  {
    switch( power )
    {
      case NONE: return;
      
      case WIND:
        if( windPowerTimer > 0 || !canUseWind ) return; // Can't use yet
        if( !landed ) ySpd = -15; // Mid-air jump
        windPowerTimer = 30;
        canUseWind = false;
        return;
        
      case ICE:
        if( icePowerTimer > 0 )  return;
        magic.add( new PlayerShot( this ) );
        icePowerTimer = 150;
        return;
        
      case FIRE:
        magic.add( new PlayerShot(this) );   
        
        //Dash attack
        if( fireCharge == fireFullCharge )
        {
          //magic.get( magic.size()-1 ).bigFire = 2;
          inAFireball = true;
          fireball = magic.get( magic.size()-1 );
        }
        fireCharge = 0;
        return;
    }
  }
  
  //Tracks when powers can be used again
  public void trackPower()
  {
    if( windPowerTimer > 0 )  windPowerTimer--;
    if( icePowerTimer > 0 )   icePowerTimer--;
    //if( firePowerTimer > 0 )  firePowerTimer--;
  }
  
  //Moves the player to a specific point on a specific map (x and y are indecies)
  public void moveTo( int m, float x, float y )
  {
    currentMap = m;
    xPos = x*blockSize+blockSize/2;
    yPos = y*blockSize+blockSize/2;
  }
  
  //Snaps to the stated side of the block (snapToTop snaps the player's bottom to the top of the block)
  //Top works differently from the other three at the moment
  public void snapToTop()
  {
    ySpd = 0;                      //Stop moving up/down
    yPos = blockSnapHeight-size/2; //Change position to top of block
    landed = true;                 //Player is no longer jumping
    canUseWind = true;             //Player can use wind attack again
    hopX=hopY=0;                   //Player is no longer hopping
    bounce();                      //Bounce up if this is a bounce pad
  }
  public void snapToBottom()
  {
    ySpd = 0;                      //Stop moving up/down
    yPos = (int)yPos;              //set yPos to an integer value
    while( top()%blockSize != 0 )  //move by one until
      yPos++;                       //player is touching block
    bounce();                      //Bounce down if this is a bounce pad
  }
  public void snapToLeft()
  {
    xSpd = 0;
    xPos = int(xPos);
    while( right()%blockSize != 0 )
      xPos--;
    bounce();                      //Bounce left if this is a bounce pad
  }
  public void snapToRight()
  {
    xSpd = 0;
    xPos = int(xPos);
    while( left()%blockSize != 0 )
      xPos++;
    bounce();                      //Bounce right if this is a bounce pad
  }
  
  public void bounce()
  {
    if( bounceDirection == 0 )
      return;
    if( bounceDirection == 1 ) { ySpd = -20; landed = false; }
    if( bounceDirection == 2 )   xSpd = 20;
    if( bounceDirection == 3 )   ySpd = 20;
    if( bounceDirection == 4 )   xSpd = -20;
    
    bounceDirection = 0;
  }
  
  //Returns the sides of the player
  public float top()    { return yPos-size/2; }
  public float bottom() { return yPos+size/2; }
  public float left()   { return xPos-size/2; }
  public float right()  { return xPos+size/2; }
  
  //Reports which block the player is in, unless they are off the map
  public Block currentBlock()
  {
    if( yPos < 0 || yPos > world[currentMap].ySize*blockSize )
      return blankBlock;
    return world[currentMap].block[int(xPos/blockSize)][int(yPos/blockSize)];
  }
  
  //************************//
  // Will move the 'screen' //
  //  when the player gets  //
  //   close to an edge.    //
  //************************//
  public void checkForScroll()
  {
    if( yPos+yOffset < scrollYDist ) //screen up
      yOffset -= yPos+yOffset-scrollYDist;
    
    if( xPos+xOffset < scrollXDist ) //screen left
      xOffset -= xPos+xOffset -scrollXDist;
      
    if( yPos+yOffset > height-scrollYDist ) //screen down
      yOffset -= yPos+yOffset - (height-scrollYDist);
      
    if( xPos+xOffset > width-scrollXDist) //screen right
      xOffset -= xPos+xOffset - (width-scrollXDist);
  }
}

public enum Power
{
  NONE, WIND, FIRE, ICE
}
