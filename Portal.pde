  //**************************************//
  //                PORTAL                //
  // This object contains the origin and  //
  // destination for doors or other types //
  // of portals.                          //
//******************************************//
//                   DATA                   //
//                                          //
// originMap -> entry point's map index     //
// originX -> entry point's block index     //
// originY -> entry point's block index     //
//                                          //
// destinationMap -> exit point's map index //
// destinationX -> exit point's block index //
// destinationY -> exit point's block index //
//******************************************//

class Portal
{
  int originMap;
  int originX, originY;
  
  int destinationMap;
  int destinationX, destinationY;
  
  public Portal( int om, int ox, int oy, int dm, int dx, int dy )
  {
    originMap = om;
    originX = ox;
    originY = oy;
    
    destinationMap = dm;
    destinationX = dx;
    destinationY = dy;
  }
}
