       //************************************//
       //               PICKUP               //
       // This object contains the data and  //
       // methods for the gems and keys and  //
       // anything else the player might     //
       // collect. Once collected, the items //
       // will mark themselves as inactive   //
       // and no longer display.             //
//***************************************************//
//                       DATA                        //
//                                                   //
// type -> the pickup's type, which controls its     //
//    appearance and what the player gains by        //
//              collecting it.                       //
//                                                   //
// xPos -> item's X location in the drawing window   //
// yPos -> item's Y location in the drawing window   //
// map -> map on which the item appears              //
//                                                   //
// active -> tracks if the pickup is still on screen //
// hidden -> tracks if it has appeared yet           //
//                                                   //
// floatAwayCount -> counter that controls how high  //
//    the pickup floats when collected, and how      //
//        transparent it is at is goes away.         //
// coinType -> determines how the coin will display  //
//                                                   //
//***************************************************//
//            METHODS            //
//                               //
// Pickup( char, float, float )  //
//                               //
// PickupType setType()          //
// void drawPickup()             //
//                               //
// void checkForGrab()           //
//                               //
//*******************************//

class Pickup
{
  PickupType type;
  float xPos, yPos;
  int map;
  
  boolean active; //Is still on the map
  boolean hidden; //Has not appeared yet
  
  int floatAwayCount;
  int coinType; //For determining how the coin will display

  public Pickup( char t, float x, float y, int m )
  {
    xPos = x;
    yPos = y;
    map = m;
    
    active = true;
    hidden = false;
    floatAwayCount = 10;
    coinType = int(random(5));
    
    type = setType(t);
  }
  
  public PickupType setType( char t )
  {
    switch(t)
    {
      case 'R': return PickupType.GEM_RED;
      case 'G': return PickupType.GEM_GREEN;
      case 'B': return PickupType.GEM_BLUE;
      case 'k': return PickupType.KEY;
      case '$': return PickupType.COIN;
    }
    
    return PickupType.NONE;
  }
  
  public void drawPickup()
  {
    if( !active && floatAwayCount > 0 )
    {
      floatAwayCount--;
      yPos -= 3;
    }
    
    push(); tint( 255, floatAwayCount * 25 ); //fade as they are collected
    switch( type )
    {
      case KEY:
        image( pickupImage[0], xPos+xOffset, yPos+yOffset );
        break;
      case GEM_RED:
        image( pickupImage[1], xPos+xOffset, yPos+yOffset );
        break;
      case GEM_BLUE:
        image( pickupImage[2], xPos+xOffset, yPos+yOffset );
        break;
      case GEM_GREEN:
        image( pickupImage[3], xPos+xOffset, yPos+yOffset );
        break;
      case COIN:
        image( pickupImage[4+coinType], xPos+xOffset, yPos+yOffset );
    }
    pop();
  }
  
  //Checks to see if the player and pickup occupied the same space, and thus it was collected
  public void checkForGrab()
  {
    if( active && dist( player.xPos, player.yPos, xPos, yPos ) < player.size )
    {
      active = false;
      switch( type )
      {
        case KEY:
          player.keys++;
          break;
        case COIN:
          player.coins++;
          break;
        case GEM_RED:
          player.power = Power.FIRE;
          break;
        case GEM_GREEN:
          player.power = Power.WIND;
          player.fireCharge = 0;
          break;
        case GEM_BLUE:
          player.power = Power.ICE;
          player.fireCharge = 0;
          break;
      }
    }
  }
}

public enum PickupType
{
  NONE, GEM_RED, GEM_GREEN, GEM_BLUE, COIN, KEY
}
