       //************************************//
       //               ENEMY                //
       // This object contains the data and  //
       // methods for the enemies.           //
//***************************************************//
//                      DATA                         //
//                                                   //
// xPos -> enemy's X location in the drawing window  //
// yPos -> enemy's Y location in the drawing window  //
// originalX -> enemy's original X location          //
// originalY -> enemy's original Y location          //
// map -> map on which the enemy exists              //
//                                                   //
// size -> size of the enemy (for collision)         //
//                                                   //
// speed -> speed at which enemy is moving           //
// accel -> rate of speed increase                   //
// spdCap -> enemy's maximum speed                   //
//                                                   //
// climbStage -> current climbing state              //
// climbCounter -> tracks when climbStage changes    //
// climbHeight -> distance above lowHeight           //
// lowHeight -> farthest distance down               //
//                                                   //
// flying -> tracks if enemy cares about pits        //
// movingLeft -> tracks direction enemy is moving    //
// seekTime -> time enemy shots seek player          //
// shotSpeed -> how fast shots move                  //
//                                                   //
// defeated -> tracks if enemy is defeated           //
// frozen -> tracks if enemy is frozen in place      //
// leaveX, leaveY -> speeds at which the enemy       //
//                leaves the screen when defeated    //
// timer -> tracks time until enemy respawns         //
//                                                   //
// type -> stores the enemy's type                   //
//***************************************************//
//                 METHODS                  //
//                                          //
// Enemy( char t, float x, float y, int m ) //
//                                          //
// EnemyType setType( char t )              //
//                                          //
// void drawEnemy()                         //
// void moveEnemy()                         //
//                                          //
// float top()                              //
// float bottom()                           //
// float left()                             //
// float right()                            //
//                                          //
// void handleWalkerMovement()              //
// void handleFlierMovement()               //
// void handleSwimmerMovement()             //
// void handleShooterMovement()             //
//                                          //
// void defeat( Power p, float x )          //
//                                          //
// boolean onScreen()                       //
// boolean canRespawn()                     //
//******************************************//

class Enemy
{
  //Location data
  float xPos, yPos;
  float originalX, originalY;
  int map;
  
  //Drawing data
  float size;
  
  //Horizontal data
  float speed; //How fast it is moving
  float accel; //How fast it speeds up
  float spdCap; //How fast it can move
  
  //Vertical data
  int climbStage; // 0-paused at bottom, 1-climbing, 2-paused at top, 3-descending
  int climbCounter; //point at which climbStage advances
  float climbHeight; //distance above lowHeight (in blocks)
  float lowHeight; //farthest distance down
  
  //Misc. data
  boolean flying; //Does enemy fear walking off pits or not
  boolean movingLeft; //Which direction it is accelerating
  int seekTime; //How long does enemy's shot seek the player
  float shotSpeed; //How fast shooting enemies shoot
  
  //Defeated data
  boolean defeated; //is enemy defeated
  boolean frozen; //is enemy frozen in place
  float leaveX, leaveY; //speed at which enemy leaves the screen
  int timer; //time until enemy respawns
  
  EnemyType type;
  
  public Enemy( char t, float x, float y, int m )
  {
    xPos = x;
    yPos = y;
    originalX = x;
    originalY = y;
    map = m;
    movingLeft = true;
    
    type = setType( t );
  }
  
  EnemyType setType( char t )
  {
    switch( t )
    {
      //Walking wolves
      case '0': accel = 0.1; spdCap = 1; size = 50; flying = false; return EnemyType.WALKER;
      //Flying wasps
      case '1': accel = 0.1; spdCap = 3; size = 40; flying = true;  return EnemyType.FLIER_PATROL;
      //Shooter spiders
      case '2': speed = 0.5; climbStage = 0; climbHeight = 2; lowHeight = yPos; climbCounter = 2000; size = 50; shotSpeed = 2; return EnemyType.SHOOTER;
      //Swimming squids
      case '3': accel = 0.1; spdCap = 1; size = 50; flying = true;  return EnemyType.SWIMMER;
      
      //None
      default: return EnemyType.NONE;
    }
  }
  
  public void drawEnemy()
  {
    if( !onScreen() ) //don't draw enemies that aren't on screen
      return;
    
    pushMatrix();
    float adjustedX = xPos+xOffset;
    if(!movingLeft)  //this will handle "flipping" images
    {
      scale(-1.0,1.0);
      adjustedX = -adjustedX;
    }
    
    switch( type )
    {
      case WALKER:
        image( enemyImage[0], adjustedX, yPos+yOffset );
        break;
      case JUMPER:
        break;
      case FLIER:
      case FLIER_SHOOT:
      case FLIER_PATROL:
        image( enemyImage[1], adjustedX, yPos+yOffset );
        break;
      case SHOOTER:
      case SHOOTER_SEEKER:
        if( !defeated ) { push(); stroke(255,150); strokeWeight(2); line(adjustedX, yPos+yOffset, adjustedX, (lowHeight+yOffset-climbHeight*blockSize-blockSize/2)); pop(); }
        push(); tint(200,0,0); image( enemyImage[2], adjustedX, yPos+yOffset ); pop();
        break;
      case SWIMMER:
        image( enemyImage[3], adjustedX, yPos+yOffset);
        break;
    }
    popMatrix();
  }
  
  public void moveEnemy()
  { 
    if( timer > 0 ) //count down to respawn
      timer--;
    if( canRespawn() ) //respawn
    {
      defeated = false;
      xPos = originalX;
      yPos = originalY;
    } 
      
    if( !onScreen() ) //don't draw enemies that aren't on screen
      return;
      
    if( defeated ) //for if enemy is defeated
    {
      if(!frozen)
        leaveY += 0.8;
      xPos += leaveX;
      yPos += leaveY;
      return;
    }
    
    switch( type )
    {
      case WALKER:
        handleWalkerMovement();
        break;
      case JUMPER:
        break;
      case FLIER:
        break;
      case FLIER_SHOOT:
        break;
      case FLIER_PATROL:
        handleFlierMovement();
        break;
      case SHOOTER:
      case SHOOTER_SEEKER:
        handleShooterMovement();
        break;
      case SWIMMER:
        handleSwimmerMovement();
        break;
    }
  }
    
  //Returns the sides of the enemy
  public float top()    { return yPos-size/2; }
  public float bottom() { return yPos+size/2; }
  public float left()   { return xPos-size/2; }
  public float right()  { return xPos+size/2; }

  //Wolves
  public void handleWalkerMovement()
  {
    //Move based on direction and accel speed
    if(movingLeft)
      speed -= accel;
    else
      speed += accel;
      
    //This keeps faster enemies from going out of bounds - would be better to have slower enemies
    if( movingLeft && speed > 0 )
      speed -= spdCap/10;
    if( !movingLeft && speed < 0 )
      speed += spdCap/10;
    
    //Cap the monster's speed
    if( speed > spdCap ) speed = spdCap;
    if( speed < -spdCap ) speed =-spdCap;
    
    //Turn around if they see a wall
    if( world[map].hitLeft(this) )
      movingLeft = true;
    if( world[map].hitRight(this) )
      movingLeft = false;
      
    xPos += speed;
  }
  
  //Wasps
  public void handleFlierMovement()
  {
    //Move based on direction and accel speed
    if(movingLeft)
      speed -= accel;
    else
      speed += accel;
      
    //This keeps faster enemies from going out of bounds - would be better to have slower enemies
    if( movingLeft && speed > 0 )
      speed -= spdCap/10;
    if( !movingLeft && speed < 0 )
      speed += spdCap/10;
    
    //Cap the monster's speed
    if( speed > spdCap ) speed = spdCap;
    if( speed < -spdCap ) speed =-spdCap;
    
    //Turn around if they see a wall
    if( world[map].hitLeft(this) )
      movingLeft = true;
    if( world[map].hitRight(this) )
      movingLeft = false;
      
    xPos += speed;
  }
  
  //Squids
  public void handleSwimmerMovement()
  {
    //Move based on direction and accel speed
    if(movingLeft)
      speed -= accel;
    else
      speed += accel;
      
    //This keeps faster enemies from going out of bounds - would be better to have slower enemies
    if( movingLeft && speed > 0 )
      speed -= spdCap/10;
    if( !movingLeft && speed < 0 )
      speed += spdCap/10;
    
    //Cap the monster's speed
    if( speed > spdCap ) speed = spdCap;
    if( speed < -spdCap ) speed =-spdCap;
    
    //Turn around if they see a wall
    if( world[map].hitLeft(this) )
      movingLeft = true;
    if( world[map].hitRight(this) )
      movingLeft = false;
      
    xPos += speed;
  }

  //Shooter spiders
  public void handleShooterMovement()
  {
    if( ( climbStage == 0 || climbStage == 2 ) && millis() > climbCounter ) 
    {
      climbStage = climbStage+1;
      speed = -speed;
    }
    else if( climbStage == 1 || climbStage == 3 ) //going up / down
    {
      yPos+=speed;
      if( yPos < lowHeight-blockSize*climbHeight )
      {
        yPos = lowHeight-blockSize*climbHeight;
        climbStage = 2;
        climbCounter = millis()+int(random(1000,2000));
        shots.add( new EnemyShot( this, player, shotSpeed ) );
      }
      if( yPos > lowHeight )
      {
        yPos = lowHeight;
        climbStage = 0;
        climbCounter = millis()+int(random(1000,2000));
        shots.add( new EnemyShot( this, player, shotSpeed ) );
      }
    }
  }
  
  //Deactivate enemy and trigger defeat actions
  public void defeat( Power p, float x ) //power used to defeat enemy, player's position
  {
    defeated = true;
    timer = 1255; //time until respawn
    switch( p )
    {
      case WIND:      //enemy is knocked away from the player
        leaveY = -10;
        leaveX = 10;
        if( x > xPos ) //reverse direction based on player's position
          leaveX *= -1;
        break;
      case ICE:
        leaveY = 0;
        leaveX = 0;
        frozen = true;
        iceBlocks.add( new Block( 'i', xPos, yPos ) );
        iceBlocks.get(iceBlocks.size()-1).frozenEnemy = this;
    }
  }
  
  //tracks if enemy is currenly displayed
  private boolean onScreen()
  {
    if( xPos+xOffset > -blockSize && xPos+xOffset < width && yPos+yOffset > -blockSize && yPos+yOffset < height )
      return true;
    return false;
  }
  
  //tracks if enemy can respawn without player seeing it
  private boolean canRespawn()
  {
    if( defeated && timer <= 0 && ( originalX+xOffset < -blockSize || originalX+xOffset > width || originalY+yOffset < -blockSize || originalY+yOffset > height ) )
      return true;
    return false;
  }
}

public enum EnemyType //not all currently used
{
  NONE, WALKER,
  JUMPER,
  FLIER, FLIER_SHOOT, FLIER_PATROL,
  SWIMMER,
  SHOOTER, SHOOTER_SEEKER
}
