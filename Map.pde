       //************************************//
       //               MAP                  //
       // This object contains the data and  //
       // methods for the maps.              //
       // Some collisions are also handled.  //
       // within this object.                //
//***************************************************//
//                       DATA                        //
//                                                   //
// block -> 2D array of Block objects that make up   //
//            the components of the map.             //
// stairBlock -> ArrayList of Block objects that     //
//               contain the stair blocks.           //
//                                                   //
// xSize -> width of map (in Blocks)                 //
// ySize -> height of map (in Blocks)                //
//                                                   //
//************************************************************//
//                          METHODS                           //
//                                                            //
// Map( String blockMap, int mapXsize, int index)             //
//                                                            //
// void assignBlocksByString( String blockMap, int index )    //
// void addStair( int x, int y, int dist, boolean goesRight ) //
//                                                            //
// void drawMap()                                             //
// boolean hitTop( Player p )                                 //
// boolean hitBottom( Player p )                              //
// boolean hitLeft( Player p )                                //
// boolean hitRight( Player p )                               //
//                                                            //
// boolean hitLeft( Enemy e )                                 //
// boolean hitRight( Enemy e )                                //
//                                                            //
// void checkTraps()                                          //
//                                                            //
// boolean skipPlatform( Block b )                            //
//                                                            //
//************************************************************//

//****************************//
//Maps are drawn at the bottom//
//                            //
// void createMaps()          //
//****************************//

class Map
{
  Block [][] block;
  ArrayList<Block> stairBlock = new ArrayList<Block>();
  int xSize, ySize;
  
  public Map( String blockMap, int mapXsize, int index)
  {
    xSize = mapXsize;
    ySize = blockMap.length()/mapXsize;
    block = new Block[xSize][ySize];
    assignBlocksByString(blockMap,index);
  }
  
  private void assignBlocksByString( String blockMap, int index )
  {
    //Sets each block based on its associated char in the string
    for( int i = 0; i < ySize; i++ )
      for( int j = 0; j < xSize; j++ )
      {
        block[j][i] = new Block( blockMap.charAt((i*xSize)+j), j*blockSize, i*blockSize ); // <- i/j swap occurs here
        
        if( isPickup( blockMap.charAt((i*xSize)+j) ) ) // <- adds pickups to the list
          pickup.add( new Pickup( blockMap.charAt((i*xSize)+j), j*blockSize+blockSize/2, i*blockSize+blockSize/2, index) );
          
        if( isEnemy( blockMap.charAt((i*xSize)+j) ) ) // <- adds enemies to the list
          enemy.add( new Enemy( blockMap.charAt((i*xSize)+j), j*blockSize+blockSize/2, i*blockSize+blockSize/2, index) );
          
        if( hasLock( blockMap.charAt((i*xSize)+j) ) ) // <- adds doors to lock list
          lockList.add( block[j][i] ); //Adds reference to the Block object, not a copy of it
      }
  }
  
  //Adds stairs starting from the x,y position, moving up in the indicated direction for a distance of dist (in blocks)
  public void addStair( int x, int y, int dist, boolean goesRight )
  {
    x*=blockSize;
    y*=blockSize;
    
    //Creates an extra block to keep the player from "tripping" on the top step
    if( goesRight )
      stairBlock.add( new Block( '>', x+dist*blockSize+blockSize/5, y-dist*blockSize ) );
    else
      stairBlock.add( new Block( '>', x-dist*blockSize+blockSize/5, y-dist*blockSize ) );
    
    //Adds the stairs to the ArrayList
    for(int i = int(dist*blockSize); i > 0; i-= blockSize/10 ) // <- backward so that lower blocks draw after the block above them
    {
      if( goesRight )
        stairBlock.add( new Block( '>', x+i, y-i ) );
      else
        stairBlock.add( new Block( '<', x-i+blockSize, y-i ) );
        
      if( i == 0 )
        stairBlock.remove( stairBlock.size()-1 );
    }

  }
  
  public void drawMap()
  {
    //Background
    for( int i = 0; i < xSize; i++ )
      for( int j = 0; j < ySize; j++ )
        if( block[i][j].background )
          block[i][j].drawBlock();
          
    //Stairs
    for( Block b: stairBlock )
      b.drawBlock();
    //Stair Rails
    for( Block b: stairBlock )
      b.drawRail();
      
    //Normal blocks
    for(int i = 0; i < xSize; i++)
      for(int j = 0; j < ySize; j++)
        if( !block[i][j].background )
          block[i][j].drawBlock();
  }
  
  //************************************************//
  //Below here are methods for collision with player//
  //************************************************//
  
  //Did the player hit the top of a block
  public boolean hitTop( Player p )
  {
    boolean returnValue = false; //for if multiple blocks need to be checked (falling block moving through floor)
    
    //ONLY FOR STAIRS
    for( int i = 0; i < stairBlock.size(); i++)
    {
      if( p.bottom() >= stairBlock.get(i).top()     //Check sides of block
       && p.bottom() <= stairBlock.get(i).yMiddle() //against player position  (changed bottom() to yMiddle())
       && p.xPos > stairBlock.get(i).left()
       && p.xPos < stairBlock.get(i).right() )
       {
         blockSnapHeight = stairBlock.get(i).top();
         return true;
       }
    }
    
    //FOR ICE
    for( int i = 0; i < iceBlocks.size(); i++ )
    {
      if( p.bottom() >= iceBlocks.get(i).top()     //Check sides of block
       && p.bottom() <= iceBlocks.get(i).yMiddle() //against player position  (changed bottom() to yMiddle())
       && p.xPos > iceBlocks.get(i).left()
       && p.xPos < iceBlocks.get(i).right() )
       {
         blockSnapHeight = iceBlocks.get(i).top();
         return true;
       }
    }
        
    //NORMAL BLOCKS
    for( int i = 0; i < xSize; i++)  //look through list of normal blocks
      for( int j = 0; j < ySize; j++ )
        if( !block[i][j].pathable )
        {
          if( p.yPos+p.size/2 >= block[i][j].top()     //Check sides of block
           && p.yPos+p.size/2 <= block[i][j].yMiddle() //against player position  (changed bottom() to yMiddle())
           && p.xPos >= block[i][j].left()//-5   //added the +- 5 to make block jumping
           && p.xPos <= block[i][j].right()//+5  //feel better, but made stair jitters worse
           && !skipPlatform(block[i][j]) )
          {
            blockSnapHeight = block[i][j].top();
            if( block[i][j].type == BlockType.BOUNCE ) //Bounce Blocks
              player.bounceDirection = 1;
              
            if( block[i][j].type == BlockType.FALLING ) //Falling Blocks
            {
              if( !block[i][j].falling ) //begin fall, which will last for 1255 draw cycles
              {
                block[i][j].falling = true;
                block[i][j].timer = -1000;
              }
              blockSnapHeight += block[i][j].fallSpeed; // <- player moves down equal to falling speed of block
              returnValue = true;
            }
            else
              return true;
          }
        }

    return returnValue;
  }
  public boolean hitBottom( Player p )
  {
    for( int i = 0; i < xSize; i++)
      for( int j = 0; j < ySize; j++ )
        if( !block[i][j].pathable && !block[i][j].falling && block[i][j].type!=BlockType.THIN )
        {
          if(  p.xPos >= block[i][j].left()
            && p.xPos <= block[i][j].right()
            && p.yPos-p.size/2 < block[i][j].bottom() 
            && p.yPos-p.size/2 > block[i][j].yMiddle() )
          {
            if( block[i][j].type == BlockType.BOUNCE ) //Bounce Blocks
              player.bounceDirection = 3;
            return true;
          }
        }
    return false;
  }
  public boolean hitLeft( Player p )
  {
    for( int i = 0; i < xSize; i++)
      for( int j = 0; j < ySize; j++ )
        if( !block[i][j].pathable && !block[i][j].falling && block[i][j].type!=BlockType.THIN )
        {
          if(  p.right() >= block[i][j].left()
            && p.right() <= block[i][j].xMiddle()
            && p.yPos >= block[i][j].top() 
            && p.yPos <= block[i][j].bottom() )
          {
            if( block[i][j].type == BlockType.BOUNCE ) //Bounce Blocks
              player.bounceDirection = 4;
            return true;
          }
        }
    return false;
  }
  public boolean hitRight( Player p )
  {
    for( int i = 0; i < xSize; i++)
      for( int j = 0; j < ySize; j++ )
        if( !block[i][j].pathable && !block[i][j].falling && block[i][j].type!=BlockType.THIN )
        {
          if(  p.left() <= block[i][j].right()
            && p.left() >= block[i][j].xMiddle() 
            && p.yPos >= block[i][j].top() 
            && p.yPos <= block[i][j].bottom() )
          {
            if( block[i][j].type == BlockType.BOUNCE ) //Bounce Blocks
              player.bounceDirection = 2;
            return true;
          }
        }
    return false;
  }
  
  
  //*************************************************//
  //Below here are methods for collision with enemies//
  //*************************************************//
  public boolean hitLeft( Enemy e )
  {
    for( int i = 0; i < xSize; i++)
      for( int j = 1; j < ySize; j++ )
      {
        if( !block[i][j].pathable && e.yPos >= block[i][j].top() && e.yPos <= block[i][j].bottom() && //Is enemy in line with a solid block
            e.xPos >= block[i][j].left()-blockSize && e.xPos <= block[i][j].xMiddle()-blockSize )   //detects one block away so it has time to turn around
          {
            return true;
          }
        if( !e.flying && block[i][j].pathable && e.yPos >= block[i][j-1].top() && e.yPos <= block[i][j-1].bottom() && //sees a pit ahead
            e.xPos >= block[i][j-1].left()-blockSize && e.xPos <= block[i][j-1].xMiddle()-blockSize )   //detects one block away so it has time to turn around
          {
            return true;
          }
      }
    return false;
  }
  public boolean hitRight( Enemy e )
  {
    for( int i = 0; i < xSize; i++)
      for( int j = 1; j < ySize; j++ )
      {
        if( !block[i][j].pathable && e.yPos >= block[i][j].top() && e.yPos <= block[i][j].bottom() && //Is enemy in line with a solid block
            e.xPos <= block[i][j].right()+blockSize && e.xPos >= block[i][j].xMiddle()+blockSize )   //detects one block away so it has time to turn around
          {
            return true;
          }
        if( !e.flying && block[i][j].pathable && e.yPos >= block[i][j-1].top() && e.yPos <= block[i][j-1].bottom() && //sees a pit ahead
            e.xPos <= block[i][j-1].right()+blockSize && e.xPos >= block[i][j-1].xMiddle()+blockSize )   //detects one block away so it has time to turn around
          {
            return true;
          }
      }
    return false;
  }
  
  public void checkTraps()
  {
    if( player.currentBlock().type == BlockType.TRAP_DOOR )
    {
      player.currentBlock().triggered = true;
      trippedTrap = player.currentBlock();
    }
  }
}

//Checks to see if the player should hop down through the current platform
public boolean skipPlatform( Block b )
{
  if( !b.thin ) return false;
  
  if( int(b.yPos/blockSize) == player.hopY )
  {
    if( int(b.xPos/blockSize) == player.hopX-1 || int(b.xPos/blockSize) == player.hopX || int(b.xPos/blockSize) == player.hopX+1 ) //check for adjacent platforms
    {
      return true;
    }
  }
  
  return false;
}

public void createMaps()
{
  println("Building MAPS");
  world = new Map[5];
 
  String mapString;
  int mapWidth;
  int mapNum;
  
  //------------------------------------------//
  //Map 0 - Movement and Dungeon features
  mapNum = 0; // <- start with zero
  mapString = ""; // <- reset before each new map
  mapString += "##############################################################################################################"; mapWidth = mapString.length(); // <- this command needs to go here
  mapString += "#                               ###    ...      ##@    ###}#                        #    #######   Ik $I I$$ #";
  mapString += "#T                              }##    ..$       ##    #@T#                     T   #     #####    #####-#####";
  mapString += "##             $      $         ###    ..         ##  ###V#                 *--------      ###     #$$ I I$ $#";
  mapString += "###   U     U     U   # U     U *** U     U          ###  #     #U  #  U   s#              ###     #####-#####";
  mapString += "####           #    $           ###    ...      U   ####V##U   #     #    s #            U ### U   ##### ###}#";
  mapString += "#####  T #     #    #  T     T  ###  T ...     T   ##}##  I    *  T  #   s  #U     U  T    I∏I  T  [!T   #####";
  mapString += "########################################################################################################=#####";
  
  //Adds map to the list (must be done before other changes can be made)
  world[mapNum] = new Map( mapString, mapWidth, mapNum );
  
  //Add messages to specific blocks. Messages display when in that block.
  world[mapNum].block[1][2].message = "Move left/right with A/D or arrow keys.";
  world[mapNum].block[7][6].message = "Use (SPACE) to jump.";
  world[mapNum].block[23][6].message = "Collect coins for extra lives.";
  world[mapNum].block[29][6].message = "Some walls hold secret passages.";
  world[mapNum].block[37][6].message = "Some walls are invisible.";
  world[mapNum].block[47][6].message = "Use W or UP to use a door.";
  world[mapNum].block[57][2].message = "Watch our for crumbling floors.";
  world[mapNum].block[66][6].message = "Hold (SHIFT) to run.";
  world[mapNum].block[80][2].message = "Hold DOWN when jumping to hop down.";
  world[mapNum].block[86][6].message = "You need a key to open a portcullis.";
  world[mapNum].block[96][6].message = "Trapped gates will sometimes close behind you.";
  world[mapNum].block[101][6].message = "Bounce blocks help you jump higher.";
    
  //Add portals (doors that connect to other locations)
  //Each door should create its own Portal object. Portals are one-way. If the connecting door comes back, it requires another Portal.
  //Portals for enitre game are stored in a single ArrayList
  
  //Example Door
  door.add( new Portal( mapNum, 50, 1, mapNum, 56, 2) );
  //Exit Door
  door.add( new Portal( mapNum, 92, 6, mapNum+1, 1, 1) );
  
  //Adds stairs to the map (s symbols do not create the stairs, but do serve to show them on map and other collision purposes)
  //addStair( starting X, starting Y, length, does it travel up-right (true) or up-left (false)
  world[mapNum].addStair(72,7,4,true);
  
  //------------------------------------------//
  //Map 1 - Baddies
  mapNum++; // <- increase by one each time
  mapString = ""; // <- reset before each new map
  mapString += "#######################################"; mapWidth = mapString.length(); // <- this command needs to go here
  mapString += "#∏ T        ###############          ∏#";
  mapString += "#---        #}#####$#######        ---#";
  mapString += "#    T   2  #######$#######  2        #";
  mapString += "#------     #######*###}###     ------#";
  mapString += "#            ######*######            #";
  mapString += "##                                   ##";
  mapString += "#######     $             $     #VVVV##";
  mapString += "#  0  #  0  #  0  #=#  0  #  0  #  0 k#";
  mapString += "#################################=#####";
  
  //Adds map to the list (must be done before other changes can be made)
  world[mapNum] = new Map( mapString, mapWidth, mapNum );
  
  //Add messages
  world[mapNum].block[3][1].message = "This room is full of monsters.";
  world[mapNum].block[5][3].message = "Don't let them touch you.";
  
  //Exit Door
  door.add( new Portal( mapNum, 37, 1, mapNum+1, 3, 1) );
  
  //------------------------------------------//
  //Map 2 - Water
  mapNum++;
  mapString = ""; // <- reset before each new map
  mapString += "########################################"; mapWidth = mapString.length(); // <- this command needs to go here
  mapString += "## ∏ ################}#kI***          ∏#";
  mapString += "##---#######################-----------#";
  mapString += "##   ##}####################wwwwwwwwwww#";
  mapString += "##   #######################wwwwwwwwwww#";
  mapString += "##U U#######################wwwwwww#####";
  mapString += "##www#######################wwwwwwwwww##";
  mapString += "##www####################}##wwwwwwwwwww#";
  mapString += "##www###########################wwwwwww#";
  mapString += "##www###############$$$#####*wwwwwwwwww#";
  mapString += "##www###############$$$I****wwwwwwwwwww#";
  mapString += "##www#######w###############wwwwwww#####";
  mapString += "##www######www##w##w#######wwwwwwwwwww##";
  mapString += "##www####wwwwwwww#wwwwwww#wwwwwwwwwwwww#";
  mapString += "##www###wwwwwww3wwwwwwwwwwwwwwwwwwwwwww#";
  mapString += "##www##wwwwww#wwwwww#wwwwwwww#wwwwwwwww#";
  mapString += "##www#wwwwwwwwwwwwwwwwwwwwwwwwww3wwwwww#";
  mapString += "##wwwwww#wwwwwwwwwwwww#wwwwwwwwwwwww#ww#";
  mapString += "###wwwww##wwww#wwwwwwwwwwww#wwwwwwwwww##";
  mapString += "####wwww###wwwwwww#wwwwwwwwwwwwwwwwww###";
  mapString += "#########}#######################=######";
  
  //Adds map to the list (must be done before other changes can be made)
  world[mapNum] = new Map( mapString, mapWidth, mapNum );
  
  //Exit Door
  door.add( new Portal( mapNum, 38, 1, mapNum+1, 20, 8) );
    
  //------------------------------------------//
  //Map 3 - Powers
  mapNum++;
  mapString = ""; // <- reset before each new map
  mapString += "##################################################################################"; mapWidth = mapString.length(); // <- this command needs to go here
  mapString += "######################################### #    }}}}}}}}}}}}}}}}}}}}}}}}          #";
  mapString += "######################################### #  ############################   k    #";
  mapString += "###                                   ### #    0     0     0     0      #   I    #";
  mapString += "###@                                 @### ############################  #  ###   #";
  mapString += "#####*                             *#####  R   0  $  }  $  }  $     $   # ##### @#";
  mapString += "###   s  U        U ∏ U        U  s   ############################################";
  mapString += "###    s         #-----#         s    ###                                        #";
  mapString += "###     s        #     #        s     ###---------------#---------------#        #";
  mapString += "###      s       #-----#       s      ###     1         #  1            #        #";
  mapString += "###       s      I  @  I      s       ###             1 #         1     #        #";
  mapString += "######################################### U      1    U # U   1       U #        #";
  mapString += "#########################################  1            #       1       #        #";
  mapString += "#########################################         1     #         1     #        #";
  mapString += "# #           0    ###          ##      #    1          # 1             #   k    #";
  mapString += "# #     $    ###   ###          ##   k  #         1               1     #   I    #";
  mapString += "# #   $ #######=   =##V    ###  ##   I @#####   #wwwwwwwwwwwwwwwwwwwwwww#  ###   #";
  mapString += "# #          ##= U =##  UV ##=  =#  #####    B ##wwwwwwwwwwwwwwwwwwwwwww# ##### @#";
  mapString += "# #  $       ##=   =##     ##=  =#    ############################################";
  mapString += "# #        2 ##=   =## V   ##=  =#     ###########################################";
  mapString += "#G# $  $     ##=   =##    V##=  =#      ##########################################";
  mapString += "# ###### $   ##=   =##V    ##=  =#  U   ###    $     ###   $ $    ###   $$$    ###";
  mapString += "#V#          ##=   =##     ##=  =#    U ###          ###          ###          ###";
  mapString += "# #       $  ###   ###   V ###  ##      ### @      ∏ ### @      ∏ ### @     U@U###";
  mapString += "# # 2        ###           ###          ##########################################";
  mapString += "#     0    $ ###       V   ###    0     ##########################################";
  mapString += "####################################===###########################################";
  
  //Adds map to the list (must be done before other changes can be made)
  world[mapNum] = new Map( mapString, mapWidth, mapNum );
  
  //Add messages
  world[mapNum].block[20][8].message = "Use B to activate magic.";
  
  //Stairs
  world[mapNum].addStair(10,11,6,false);
  world[mapNum].addStair(29,11,6,true);
  
  //Wind Door
  door.add( new Portal( mapNum, 3, 4,   mapNum, 1, 14 ) );
  door.add( new Portal( mapNum, 39, 16,   mapNum, 20, 8 ) );
  //Ice Door
  door.add( new Portal( mapNum, 20, 10, mapNum, 41, 17 ) );
  door.add( new Portal( mapNum, 80, 17,   mapNum, 20, 8 ) );
  //Fire Door
  door.add( new Portal( mapNum, 37, 4,  mapNum, 41, 1 ) );
  door.add( new Portal( mapNum, 80, 5,   mapNum, 20, 8 ) );
  //Exit Door 1
  door.add( new Portal( mapNum, 20, 6, mapNum, 44, 23) );
  door.add( new Portal( mapNum, 44, 23, mapNum, 20, 6) );
  //Exit Door 2
  door.add( new Portal( mapNum, 51, 23, mapNum, 57, 23) );
  door.add( new Portal( mapNum, 57, 23, mapNum, 51, 23) );
  //Exit Door 3
  door.add( new Portal( mapNum, 64, 23, mapNum, 70, 23) );
  door.add( new Portal( mapNum, 70, 23, mapNum, 64, 23) );
  //Final Exit
  door.add( new Portal( mapNum, 77, 23, 0, 1, 1) );
}
