       //************************************//
       //               BLOCK                //
       // This object contains the data and  //
       // methods for the blocks that make   //
       // up the maps. Most blocks will be   //
       // stored in a 2D array, but some     //
       // like stairs will exist elsewhere.  //
       //          WORK IN PROGRESS          //
//***************************************************//
//                      DATA                         //
//                                                   //
// type -> the block's type, which controls many     //
//    aspects such as its behavior and appearance.   //
//                                                   //
// xPos -> block's X location in the drawing window  //
// yPos -> block's Y location in the drawing window  //
//                                                   //
// fallSpeed -> how fast a falling block is falling  //
//                                                   //
// originY -> block's original Y position            //
// timer -> time left before block resets            //
//                                                   //
// pathable -> tracks if a block is solid            //
// falling -> tracks if a block is falling           //
// background -> tracks if a block should be drawn   //
//                      before other blocks          //
// thin -> tracks if a block is "thin", meaning it   //
//       only blocks pathing from the top and the    //
//          player can hop down through it.          //
// locked -> tracks if a door is locked              //
// triggered -> triggers if the player steps in      //
//                              that square          //
// slow -> tracks if block causes slow movement for  //
//              player when inside it (water)        //
// broken -> tracks if block has been destroyed      //
//                                                   //
// message -> this message is displayed when the     //
//                player is inside this block        //
//                                                   //
// frozenEnemy -> tracks what enemy was frozen in    //
//                              the ice block        //
//***************************************************//
//               METHODS                 //
//                                       //
// Block( char, float, float, float )    //
//                                       //
// BlockType setType()                   //
// void drawBlock()                      //
// void drawRail()                       //
//                                       //
// boolean closeTo( Player p, int dist ) //
// boolean onScreen()                    //
//                                       //
// boolean blocksFire( int bigFire )     //
//                                       //
// float top()                           //
// float bottom()                        //
// float left()                          //
// float right()                         //
// float xMiddle()                       //
// float yMiddle()                       //
//***************************************//

class Block
{
  BlockType type;
  
  float xPos, yPos; //CORNER
  float fallSpeed;
  
  float originY;
  float timer;
  
  boolean pathable;
  boolean falling;
  boolean background;
  boolean thin;
  boolean locked;
  boolean triggered;
  boolean slow;
  boolean broken;
  
  String message;
  
  Enemy frozenEnemy; //only for ice blocks
  
  public Block( char t, float x, float y )
  {
    pathable   = true; //must default to true or pickups won't be pathable
    falling    = false;
    background = false;
    thin       = false;
    locked     = false;
    triggered  = false;
    slow       = false;
    broken     = false;
    
    message = "";
    
    xPos = x;
    yPos = y;
    type = setType(t);
    
    fallSpeed = 0;
    originY = yPos;
  }
  
  //Uses the character passed to Block() to determine its type, as well as some other factors
  private BlockType setType( char t )
  {
    switch(t)
    {
       case ' ': pathable = true;  background = true; return BlockType.NONE;
       case 's': pathable = true;  background = true; return BlockType.STAIR_MARKER; // <- for showing stairs on map and blocking shots
       case '#': pathable = false; return BlockType.WALL;
       case 'w': pathable = true;  background = true; slow = true; return BlockType.WATER;
       case '*': pathable = true;  return BlockType.SECRET;
       case '.': pathable = false; return BlockType.SECRET_DARK;
       case '@': pathable = true;  return BlockType.DOOR;
       case '∏': pathable = true;  locked = true; return BlockType.BIG_DOOR;    //alt+shift+p
       case '[': pathable = true;  return BlockType.TRAP_DOOR;
       case '!': pathable = true;  return BlockType.TRIGGER;
       case '>': pathable = false; return BlockType.STAIR_R;
       case '<': pathable = false; return BlockType.STAIR_L;
       case 'V': pathable = false; return BlockType.FALLING;
       case '}': pathable = false; return BlockType.CRACK;
       case '-': pathable = false; background = true; thin = true; return BlockType.THIN;
       case 'S': pathable = true;  return BlockType.SAVE;
       case 'U': pathable = true;  background = true; return BlockType.BANNER;
       case 'T': pathable = true;  background = true; return BlockType.SIGN;
       case 'I': pathable = true;  background = true; return BlockType.COLUMN;
       case '=': pathable = false; return BlockType.BOUNCE;
       case '3': pathable = true; background = true; slow = true; return BlockType.WATER; //for squids
       case 'i': pathable = false; timer = 1255; xPos -= blockSize/2; yPos -= blockSize/2; return BlockType.ICE;
       
       default:  pathable = true;  background = true; return BlockType.NONE; // <- for pickups
    }
  }
  
  public void drawBlock()
  {
    if( falling )          //Falling blocks drop for 1255 draw cycles
    {                      //At that point, they phase back in to where they started
      //Draw block fading back in
      push(); tint( wallTint, min(timer/2,127) ); image( tileImage[0], xPos+xOffset, originY+yOffset ); pop(); //for block to fade back in
      
      //Make block fall
      yPos += fallSpeed;
      fallSpeed += 0.03;
      timer += 1;
      
      //Reset block
      if( timer >= 255 )
      {
        falling = false;
        yPos = originY;
        fallSpeed = 0;
        timer = 0;
      }
    }
    
    if( broken )
    {
      push(); tint( wallTint, min(timer/2,127) ); image( tileImage[14], xPos+xOffset, originY+yOffset ); pop(); //for block to fade back in
      timer += 1;
      
      if( timer >= 255 )
      {
        broken = false;
        pathable = false;
        timer = 0;
      }
    }
    
    if( !onScreen() )
      return;
    else
      drawnBlocks++;
    
    if( player.currentBlock() == this && type == BlockType.TRIGGER && trippedTrap != null ) //Shut trapped doors once the player leaves the space
    {
      trippedTrap.locked = true;
      trippedTrap.pathable = false;
      trippedTrap.triggered = false;
      trippedTrap = null;
      type = BlockType.NONE;
    }
    
    switch( type ) //Draw based on type
    {
      case NONE:
      case STAIR_MARKER:
        push(); tint( wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop();
        break;
      case WALL:
      case SECRET:
      case FALLING:
        push(); tint( wallTint ); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop();
        break;
      case CRACK:
        if( !broken )
        { push(); tint( wallTint ); image( tileImage[14], xPos+xOffset, yPos+yOffset ); pop(); }
        break;
      case WATER:
        push(); image( tileImage[12], xPos+xOffset, yPos+yOffset ); pop();
        break;
      case SECRET_DARK:
        push(); tint( wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop();
        break;
      case DOOR:
        image( tileImage[2], xPos+xOffset, yPos+yOffset );
        break;
      case BIG_DOOR:
        if(locked) image( tileImage[7], xPos+xOffset, yPos+yOffset );
        else       image( tileImage[8], xPos+xOffset, yPos+yOffset );
        break;
      case TRAP_DOOR:
        push(); tint( wallTint, 50 ); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop();
        if(locked) image( tileImage[9], xPos+xOffset, yPos+yOffset );
        break;
      case TRIGGER:
        push(); tint( wallTint, 50 ); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop();
        break;
      case THIN:
        push(); tint(wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop(); //background
        image( tileImage[3], xPos+xOffset, yPos+yOffset );  //plank
        return;
      case SAVE:
        push(); tint(wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop(); //background
        image( tileImage[10], xPos+xOffset, yPos+yOffset );
        return;
      case BANNER:
        push(); tint(wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop(); //background
        push(); tint(bannerTint); image( tileImage[11], xPos+xOffset, yPos+yOffset-blockSize*3 ); pop();
        return;
      case SIGN:
        push(); tint(wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop(); //background
        push(); image( tileImage[15], xPos+xOffset, yPos+yOffset ); pop();
        return;
      case COLUMN:
        push(); tint(wallTint, 50); image( tileImage[0], xPos+xOffset, yPos+yOffset ); pop(); //background
        push(); tint(wallTint); image( tileImage[16], xPos+xOffset, yPos+yOffset ); pop();
        return;
      case ICE:
        push(); tint(255,min(75+timer/5,200)); image( tileImage[4], xPos+xOffset, yPos+yOffset ); pop();
        return;
      case BOUNCE:
        push(); image( tileImage[13], xPos+xOffset, yPos+yOffset ); pop();
        return;
    }
  }
  
  //Draws a rhombus of stone every 5th stair
  public void drawRail()
  {
    switch(type)
    {
      case STAIR_R:
        if( xPos%blockSize == 0 )
        { push(); tint(wallTint); image( tileImage[5], xPos+xOffset-blockSize, yPos+yOffset ); pop(); }
        break;
        
      case STAIR_L:
        if( xPos%blockSize == 0 )
        { push(); tint( wallTint); image( tileImage[6], xPos+xOffset, yPos+yOffset ); pop(); }
        break;
    }
  }
  
  //Mostly for testing purposes
  private boolean closeTo( Player p, int dist )
  {
    if( dist( p.xPos, p.yPos, xPos, yPos ) < dist )
      return true;
    return false;
  }
  
  private boolean onScreen()
  {
    if( xPos+xOffset > -blockSize && xPos+xOffset < width && yPos+yOffset > -blockSize && yPos+yOffset < height )
      return true;
    return false;
  }
  
  public boolean blocksFire( int bigFire )
  {
    if( type == BlockType.CRACK && !broken )
    {
      if( bigFire == 2 )
      {
        debris.add( new Debris(this) );
        broken = true;
        pathable = true;
        timer = -1000;
        return false;
      }
      return true;
    }
    if( type == BlockType.THIN )
      return false;
    if( type == BlockType.STAIR_MARKER )
      return true;
    if( pathable )
      return false;
    
    return true;
  }
  
  //Returns the locations of parts of the block
  public float top()     { return yPos; }
  public float bottom()  { return yPos+blockSize; }  
  public float left()    { return xPos; }
  public float right()   { return xPos+blockSize; }
  public float xMiddle() { return xPos+blockSize/2; }
  public float yMiddle() { return yPos+blockSize/2; }
}

//Block types
public enum BlockType
{
  NONE,
  WALL, CRACK, FALLING,
  WATER,
  DOOR, BIG_DOOR, TRAP_DOOR, TRIGGER,
  STAIR_R, STAIR_L, STAIR_MARKER,
  THIN,
  SECRET, SECRET_DARK,
  SAVE, BANNER, SIGN, COLUMN,
  ICE, BOUNCE;
}
