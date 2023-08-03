//Metroidvania Game Test

//Map Data
Map [] world; //holds the different maps for the game (size will change as game grows in scope)
float blockSnapHeight = 0; //for irregular blocks
int currentMap = 0; //Map the player is currently on
PImage tileImage[] = new PImage[20]; //holds the images used for blocks (size will change as images are added)
Block trippedTrap = null; //holds the "index" of a trapped door that has been tripped by stepping on an adjacent trigger
color wallTint = color(220); //re-colors the walls
color bannerTint = color(200,0,0); //re-colors the banners
float blockSize = 50;
int drawnBlocks = 0; //FOR TESTING

//Player Data
Player player;

//Door Data
ArrayList<Portal> door = new ArrayList<Portal>(); //holds the portals for all maps
ArrayList<Block> lockList = new ArrayList<Block>(); //tracks when door Blocks are unlocked (for saving/loading)
char [] lockedSymbol = {'∏'};
boolean usingDoor = false;
boolean fadingOut = false;
int doorFadeTimer = 25; //For transition to black
int overlayTrans = 0;   //For transition to black
int destMap, destX, destY; //For when the tranition to black ends

//Enemy Data
ArrayList<Enemy> enemy = new ArrayList<Enemy>();
char [] enemySymbol = {'0','1','2','3','4','5','6','7','8','9',};
PImage enemyImage[] = new PImage[10]; //holds the images used for enemies (size will change as images are added)
float enemySnapHeight = 0;

//Enemy Shot Data
ArrayList<EnemyShot> shots = new ArrayList<EnemyShot>();

//Pickup Data
ArrayList<Pickup> pickup = new ArrayList<Pickup>();
char [] pickupSymbol = {'$','k','G','R','B'};  //coin, key, green gem, red gem, blue gem
PImage pickupImage[] = new PImage[10]; //holds the images used for pickups (size will change as images are added)

//Scrolling Data
int scrollXDist = 200; //default distances
int scrollYDist = 200; //changes based on window size in setup()
float xOffset = 0;
float yOffset = 0;

//Effects data
PImage effectImage[] = new PImage[10]; //holds the images used for effects (size will change as effects are added)
ArrayList<PlayerShot> magic = new ArrayList<PlayerShot>();
ArrayList<Block> iceBlocks = new ArrayList<Block>();
ArrayList<Debris> debris = new ArrayList<Debris>();

//HUD data
PImage iconImage[] = new PImage[10]; //holds the images used for icons (size will change as effects are added)

void setup()
{
  //size(600,600);
  fullScreen();
  
  //Set the frame rate
  frameRate(60);
  
  //Set distance from edges until screen begins to "scroll"
  scrollXDist = width/3;
  scrollYDist = height/3;
  
  //Loads the external image data
  loadImages();
  
  //Creates the maps
  createMaps();
  
  //Place player
  player = new Player(75,75);
  
  //Attempts to load data from file
  loadGame();
}

void draw()
{
  //Clear screen
  background(0);
  
  //Handle elements of the game
  handleMaps();
  handlePickups();
  handleDoorTransitions();
  handleEnemies();
  handleEnemyShots();
  handleIce();
  handlePlayer();
  handlePlayerShots();
  handleCollisions();
  handleDebris();
  handleOverlay();
  handleHUD();
  
  drawnBlocks = 0;
}

void handleMaps()
{
  imageMode(CORNER);
  world[currentMap].drawMap();
}

void handlePickups()
{
  imageMode(CENTER);
  for( Pickup p: pickup )
    if( p.map == currentMap )
    {
      p.drawPickup();
      p.checkForGrab();
    }
}

void handleDoorTransitions() //This is for the fade in / fade out when using doors
{                            //Better than a smash cut
  if( usingDoor )
  {
    player.xSpd = player.ySpd = 0;
    if( fadingOut )
    {
      doorFadeTimer--;
      overlayTrans += 13;
      if( doorFadeTimer == 0 )
      {
        player.moveTo( destMap, destX, destY );
        fadingOut = false;
      }
    }
    else
    {
      doorFadeTimer++;
      overlayTrans -= 13;
    }
    
    if( !fadingOut && doorFadeTimer == 25 )
      usingDoor = false;
  }
}

void handleEnemies()
{
  imageMode(CENTER);
  for(Enemy e: enemy)
    if( e.map == currentMap )
    {
      e.moveEnemy();
      e.drawEnemy();
    }
}

void handleEnemyShots()
{
  for( int i = 0; i < shots.size(); i++ )
    if( shots.get(i).moveAndDraw() )
    {
      shots.remove(i);
      i--;
    }
}

void handleIce()
{    
  //Ice
  imageMode(CORNER);
  for( int i = 0; i < iceBlocks.size(); i++ )
  {
    iceBlocks.get(i).drawBlock();
    iceBlocks.get(i).timer--;
    if( iceBlocks.get(i).timer <= 0 )
    {
      iceBlocks.get(i).frozenEnemy.frozen=false;
      iceBlocks.remove(i);
      i--;
    }
  }
}

void handlePlayer()
{
  imageMode(CENTER);
  player.movePlayer();
  player.drawPlayer();
  player.trackPower();
  player.dealWithDamage();
}

void handlePlayerShots()
{
  for( int i = 0; i < magic.size(); i++ )
  {
    magic.get(i).drawShot();
    if( magic.get(i).moveShot() )
    {
      magic.remove(i);
      i--;
    }
  }
}

void handleCollisions()
{
  for( Enemy e: enemy ) //Look at all enemies
  {
    if( e.map == currentMap && !e.defeated ) //Only check enemies on this map
    {
      //Hit by tornado
      if( player.windPowerTimer >= 10 && dist( e.xPos, e.yPos, player.xPos, player.yPos ) < (player.size+e.size)/2+10 ) //did enemy touch the tornado
      {
        e.defeat( Power.WIND, player.xPos );
      }
      
      //Player touched bad guy
      else if( player.hurtFrames < 10 && dist( e.xPos, e.yPos, player.xPos, player.yPos ) < (player.size+e.size)/2-5 ) //did enemy touch player (with 5 pixel grace room)
      {
        player.getHurt( e.xPos );
      }
      
      for( PlayerShot s: magic )
        if( dist(e.xPos,e.yPos,s.xPos,s.yPos) < (e.size+s.size)/2 )
        {
          e.defeat( s.type, s.xPos );
        }
    }
  }
  //Player touched enemy shot
    //handled in EnemyShot
}

void handleDebris()
{
  for( int i = 0; i < debris.size(); i++ )
    if( debris.get(i).moveAndDraw() )
    {
      debris.remove(i);
      i--;
    }
}

void handleOverlay()
{
  //Door blackout
  if( usingDoor )
  {
    fill( 0, overlayTrans/100*100 );
    rect(0,0,width,height);
  }
  
  //Messages
  if( player.currentBlock().type==BlockType.SAVE )
  { push(); textSize(40); fill(#1f99e2); textAlign(CENTER); text("PRESS UP TO SAVE", width/2, 50); pop(); }
  else
  { push(); textSize(40); fill(250); textAlign(CENTER); text( player.currentBlock().message, width/2, 50); pop(); }
}

void handleHUD()
{
  //Coins
  image( iconImage[0], width-100, 30 );
  push(); textSize(20); fill(255); text(": "+player.coins,width-88,35); pop();
  
  //Keys
  image( iconImage[1], width-100, 70 );
  push(); textSize(20); fill(255); text(": "+player.keys,width-88,75); pop();
  
  //Charge Bar
  push();
  float fillPercent;
  switch( player.power )
  {
    case FIRE:
      fillPercent = float(player.fireCharge)/player.fireFullCharge;
      noStroke(); fill( 155*fillPercent+100, 100*fillPercent, 0 );
      rect(50,25, 200*fillPercent, 20);
      noFill(); stroke(255); strokeWeight(2);
      rect(50,25,200,20);
      line(110,25,110,45);
      break;
      
    case ICE:
      fillPercent = (150-player.icePowerTimer)/150.0;
      noStroke(); fill( 150, 150, 150+100*fillPercent );
      rect(50,25, 200*(fillPercent), 20);
      noFill(); stroke(255); strokeWeight(2);
      rect(50,25,200,20);
      break;
      
    case WIND:
      fillPercent = (30-player.windPowerTimer)/30.0;
      noStroke(); fill( 150, 150+100*fillPercent, 150);
      rect(50,25, 200*(fillPercent), 20);
      noFill(); stroke(255); strokeWeight(2);
      rect(50,25,200,20);
      break;
  }
  pop();
  
  //TESTING DATA DISPLAY
  /*
  push();
  textSize(20);
  text("Debris: " + debris.size(),50,100);
  text("Enemies: " + enemy.size(),50,130);
  text("Bad Shots: " + shots.size(),50,160);
  text("Pickups: " + pickup.size(),50,190);
  text("Good Shots: " + magic.size(),50,220);
  text("Drawn Blocks: " + drawnBlocks,50,250);
  text( int(player.xPos/blockSize) + " " + int(player.yPos/blockSize), 50,280);
  pop();
  */
}

void useDoor( float x, float y )
{
  x = int(x/blockSize);
  y = int(y/blockSize);
  
  for( Portal d: door )
    if( d.originMap == currentMap && d.originX == x && d.originY == y )
    {
      if( world[currentMap].block[int(x)][int(y)].locked && player.keys > 0 )
      {
        player.keys--;
        world[currentMap].block[int(x)][int(y)].locked = false;
        doorFadeTimer+=20;  //Adds delay for the door opening
        overlayTrans-=260;  //and a poosible sound effect.
      }
        
      if( !world[currentMap].block[int(x)][int(y)].locked )
      {
        //Remove ice when changing levels
        if( destMap != d.destinationMap )
          for(int i = 0; i<iceBlocks.size(); i++)
            { iceBlocks.remove(i); i--; }
        destMap = d.destinationMap;
        destX = d.destinationX;
        destY = d.destinationY;
        usingDoor = fadingOut = true;
      }
      return;
    }
}

//Handles the loading of images from data
void loadImages()
{
  println("Loading IMAGE Data");
  //Tiles
  tileImage[0] = loadImage("wallBase.png");         tileImage[0].resize(0,50);
  tileImage[1] = loadImage("wallDark.png");         tileImage[1].resize(0,50);
  tileImage[2] = loadImage("doorDouble.png");       tileImage[2].resize(0,50);
  tileImage[3] = loadImage("plank.png");            tileImage[3].resize(0,50);
  tileImage[4] = loadImage("ice.png");              tileImage[4].resize(0,50);
  tileImage[5] = loadImage("rail_right_short.png"); tileImage[5].resize(100,50);
  tileImage[6] = loadImage("left_rail_short.png");  tileImage[6].resize(100,50);
  tileImage[7] = loadImage("portcullis.png");       tileImage[7].resize(0,50);
  tileImage[8] = loadImage("portcullisOpen.png");   tileImage[8].resize(0,50);
  tileImage[9] = loadImage("bars.png");             tileImage[9].resize(0,50);
  tileImage[10]= loadImage("save1.png");            tileImage[10].resize(0,50);
  tileImage[11]= loadImage("BannerBase.png");       tileImage[11].resize(50,0);
  tileImage[12]= loadImage("water1.png");           tileImage[12].resize(0,50);
  tileImage[13]= loadImage("bounce.png");           tileImage[13].resize(0,50);
  tileImage[14]= loadImage("wallBaseCrack.png");    tileImage[14].resize(0,50);
  tileImage[15]= loadImage("sign.png");             tileImage[15].resize(0,50);
  tileImage[16]= loadImage("column.png");           tileImage[16].resize(0,50);
  
  //Enemies
  enemyImage[0] = loadImage("BrownWerewolf.png"); enemyImage[0].resize(0,50);
  enemyImage[1] = loadImage("Wasp.png");          enemyImage[1].resize(0,40);
  enemyImage[2] = loadImage("spiderBase.png");    enemyImage[2].resize(0,50);
  enemyImage[3] = loadImage("GreenSquid.png");    enemyImage[3].resize(0,50);
  
  //Pickups
  pickupImage[0] = loadImage("key.png");           pickupImage[0].resize(0,35);
  pickupImage[1] = loadImage("Ruby.png");          pickupImage[1].resize(0,30);
  pickupImage[2] = loadImage("Sapphire.png");      pickupImage[2].resize(0,30);
  pickupImage[3] = loadImage("Jade.png");          pickupImage[3].resize(0,30);
  pickupImage[4] = loadImage("electrumPiece.png"); pickupImage[4].resize(0,20);
  pickupImage[5] = loadImage("copperPiece.png");   pickupImage[5].resize(0,20);
  pickupImage[6] = loadImage("silverPiece.png");   pickupImage[6].resize(0,20);
  pickupImage[7] = loadImage("goldPiece.png");     pickupImage[7].resize(0,20);
  pickupImage[8] = loadImage("platinumPiece.png"); pickupImage[8].resize(0,20);
  
  //Effects
  effectImage[0] = loadImage("wind.png");      effectImage[0].resize(0,60);
  effectImage[1] = loadImage("wind2.png");     effectImage[1].resize(0,60);
  effectImage[2] = loadImage("snowflake.png"); effectImage[2].resize(0,30);
  effectImage[3] = loadImage("fireball.png");  effectImage[3].resize(0,30);
  effectImage[4] = loadImage("fireball2.png"); effectImage[4].resize(0,30);
  effectImage[5] = loadImage("fireball.png");  effectImage[5].resize(0,50);
  effectImage[6] = loadImage("fireball2.png"); effectImage[6].resize(0,50);
  effectImage[7] = loadImage("debris.png");    effectImage[7].resize(0,50);
  
  //Icons
  iconImage[0] = loadImage("goldPiece.png"); iconImage[0].resize(0,20);
  iconImage[1] = loadImage("key.png");       iconImage[1].resize(0,30);
}
  
public boolean isPickup( char c ) //Catches "map" tiles that should be assigned as pickups
{
  for( char p: pickupSymbol )
    if( c == p )
      return true;
  return false;
}  

public boolean isEnemy( char c ) //Catches "map" tiles that should be assigned as pickups
{
  for( char e: enemySymbol )
    if( c == e )
      return true;
  return false;
}

public boolean hasLock( char c ) //Chatches map tiles that can be locked/unlocked
{
  for( char l: lockedSymbol )
    if( c == l )
      return true;
  return false;
}

void keyPressed()
{
  if( keyCode == LEFT || key == 'a' || key == 'A' )  //Left
    player.lf = true;
  if( keyCode == RIGHT || key == 'd' || key == 'D' ) //Right
    player.rt = true;
  if( key == ' ' || key == 'z' || key == 'Z' )  //Jump
    player.jp = true;
  if( keyCode == UP || key == 'w' || key == 'W' ) //Door or save
  {
    if( player.currentBlock().type == BlockType.SAVE )
      saveGame();
    else
      useDoor( player.xPos, player.yPos );
  }
  if( keyCode == DOWN || key == 's' || key == 'S' ) //Down (through platform)
    player.dn = true;
  if( key == 'x' || key == 'X' ) //Use powerup
  {
    if( player.power != Power.FIRE )
      player.usePower();
    else
      player.chargingFire = true;
  }
  if( keyCode == SHIFT ) //Run
    player.bSpeed = 3;
}

void keyReleased()
{
  if( keyCode == LEFT || key == 'a' || key == 'A' )
    player.lf = false;
  if( keyCode == RIGHT || key == 'd' || key == 'D' )
    player.rt = false;
  if( keyCode == DOWN || key == 's' || key == 'S' )
    player.dn = false;
  if( key == ' ' || key == 'z' || key == 'Z' )
    player.jp = false;
  if( key == 'x' || key == 'X' )
  {
    if( player.power == Power.FIRE && !player.inAFireball )
    {
      player.usePower();
      player.chargingFire = false;
    }
  }
  if( keyCode == SHIFT )
    player.bSpeed = 1;
}

void saveGame()
{
  try
  {
    //use a PrintWriter to send your information to a chosen file
    PrintWriter pw = createWriter( "saveFile.txt" );
    
    //This String will hold ALL the data you want to save
    String infoToSave = "";
    infoToSave += currentMap + "\n";
    infoToSave += player.xPos + "\n";
    infoToSave += player.yPos + "\n";
    infoToSave += player.coins + "\n";
    infoToSave += player.keys + "\n";
    
    for( Pickup p: pickup ) //This saves the state of all pickups
      if( p.active )        // with a 0 meaning it has been collected
        infoToSave += "1";
      else
        infoToSave += "0";
        
    infoToSave += "\n";
    
    for( Block b: lockList ) //This saves the state of all doors
      if( b.locked )         // with a 1 meaning it is still locked
        infoToSave += "1";
      else
        infoToSave += "0";
    
    pw.println( infoToSave );
    
    pw.flush(); //Writes the remaining data to the file
    pw.close(); //Finishes the file
  }
  catch(Exception e)
  {
    println("SOMETHING WENT WRONG");
  }
}

void loadGame()
{
  println("Loading SAVE Data");
  try
  {
    //use the loadStrings() method to pull the lines of your save file into a String array
    String [] infoFromFile = loadStrings("saveFile.txt");
    
    currentMap = int(infoFromFile[0]); //Load current map
    xOffset = player.xPos = int(infoFromFile[1]); //Load player's x position
    yOffset = player.yPos = int(infoFromFile[2]); //Load player's y position
    player.coins = int(infoFromFile[3]); //Load collected gems
    player.keys = int(infoFromFile[4]); //Load collected keys
    
    for(int i = 0; i < pickup.size(); i++)
      if( infoFromFile[5].charAt(i) == '0' )
        pickup.get(i).active = false;
        
    for(int i = 0; i < lockList.size(); i++)
      if( infoFromFile[6].charAt(i) == '0' )
        lockList.get(i).locked = false;
  }
  catch(Exception e)
  {
    println("ERROR LOADING FILE");
    
    //Loads default data
    currentMap = 3;
    player.xPos = 275;
    player.yPos = 275;
    player.coins = 0;
    player.keys = 0;
  }
}
