		private function handleSpiderMovement():void {
			if (uninterruptibleAnimation && finished) {
 uninterruptibleAnimation = false;
}

if (uninterruptibleAnimation) {
 // don't check for arrow keys or jump
}else{
 if (state==FALLING){     handleFallingAndGrabbing();
 }else{
   //we're attached and OK to check movement.
   if (pressed "JUMP"){
     // Jump off whatever our floor was.
     if (ground == FLOOR ){
       acceleration.y = spiderJumpAccel
     }else if (ground == CEILING ){
       acceleration.y = spiderCeilingJumpAccel
     }else{ // Wall
       acceleration.x = spiderHorizontalJumpAccel * ( ground == LEFT
? 1 : -1 );
       if (pressed "UP") {
         acceleration.y = spiderWallJumpUpwardsAccel
       }
     }
     setSpiderOrientation( UPRIGHT );
     state = FALLING;
   }else{
     // not jumping.
     if ( isPressed ( spiderWalkDirection1 )
 xor isPressed ( spiderWalkDirection2 ) ) {
       walkDelta = getSpiderPressedWalkableDeltas();
       w0 = areTilesPassableAt
( 0, 0 ) // returns BLOCK if height 1 or 2 present, WALKABLE if 1-2
absent 0 present, or GAP if 0-2 all absent.
       w1 = areTilesPassableAt
( walkDelta.x, walkDelta.y )
       wm1 = areTilesPassableAt
( -1*walkDelta.x, -1*walkDelta.y )
       w2 = areTilesPassableAt
( 2*walkDelta.x, 2*walkDelta.y )
       w3 = areTilesPassableAt
( 3*walkDelta.x, 3*walkDelta.y )
       w4 = areTilesPassableAt
( 4*walkDelta.x, 4*walkDelta.y )
       if w0 == BLOCK || w1 == BLOCK || wm1 == BLOCK {
         // not sure how this happened.
         // no movement.
       } else if w0 == GAP && w1 == GAP && wm1 == GAP {
         state = FALLING;
         // nothing beneath our feet.
         handleFallingAndGrabbing();
       } else { // We're supported
         if w2 == BLOCK // Up against a wall {
           if ( pressed spiderAwayFromFloor ) {
             // investigate chance of concave crawl
             // if pressing a walkable direction (known already) &&
touching an obstruction in that direction (known already) && pressing
direction key away from current ground (known already) && there's
enough room: then set ground to the desired direction.
             // "enough room" to crawl around a corner defined as
room for a spider in that direction, and 3 steps of solid floor in
that direction: use solid3vacant6
             if ( spiderGround == FLOOR || spiderGround == CEILING ) {
               baseX = tileX + ( walkDelta.x * 2 ); // 2 squares left or right
               baseY = tileY + ( spiderGround == FLOOR ? -1 : 1 ); //
y-coord 1 square from current ground
             } else {
               baseX = tileX + ( spiderGround == LEFT ? 1 : -1 ); //
x-coord 1 square from current ground
               baseY = tileY + ( walkDelta.y * 2 ); // 2 squares up or down
             }
             floorDX = walkDelta.x;
             floorDY = walkDelta.y;
             if solid3vacant6 ( baseX, baseY, floorDX, floorDY ) {
               // Invoke concave crawl.
             spiderRoundCorner(CONCAVE, orientationFromDelta(walkDelta));
             }
           } else {
             // blocked. No movement.
           }
         } else if w2 == GAP && w3 == GAP && isPressed(spiderTowardsFloor) {
           // investigate chance of convex crawl
           // if walking (known already) && pressing a walkable
direction (known already) && pressing current ground direction (known
already) && reached edge of wall/ceiling in walking direction (known
already) && space of spider height in current walking direction (known
already) && space of spider size in gap beyond && wall of spider width
in direction of current ground: then play animation of climbing round
corner and transition to ground = opposite of walking direction.
           // need solid3vacant6 at a tile 2 "below" spider's front
foot square, i.e. 1 below the ground spider's front foot is on.
           if ( spiderGround == FLOOR || spiderGround == CEILING ) {
             baseX = tileX + ( walkDelta.x  ); // 1 square left or right
             baseY = tileY + ( spiderGround == FLOOR ? +2 : -2 ); //
y-coord 2 squares from current foot-level
           } else {
             baseX = tileX + ( spiderGround == LEFT ? -2 : 2 ); //
x-coord 2 squares from current foot-level
             baseY = tileY + ( walkDelta.y  ); // 1 square up or down
           }
           floorDX = walkDelta.x;
           floorDY = walkDelta.y;
           if solid3vacant6 ( baseX, baseY, floorDX, floorDY ) {
             // Invoke concave crawl.
             spiderRoundCorner(CONCAVE, orientationFromDelta(walkDelta));
           }
         } else if w2 == GAP && w3 == GAP && w4 == GAP {
           // At an edge. Only allow walking off if on floor.
           if ground == FLOOR {
             spiderWalkInPressedDir();
           }
         } else if (w2 == WALKABLE || ( w2 == GAP && w3 == WALKABLE)
||  ( w2 == GAP && w3 == GAP && w4 == WALKABLE)) {
           // walk forward.
           spiderWalkInPressedDir();
         }
     }else{
       // not walking. Nothing to do?
     }
   }
 }
}
		}
		
		
function spiderRoundCorner(concaveOrConvex, newOrientation ) {
 var isConcave:Boolean = (concaveOrConvex == CONCAVE);
 var thisAnim:String = cornerAnimations[spiderGround +
2*newOrientation + (isConcave ? 4 : 0)]
 play ( thisAnim );
 uninterruptibleAnimation = true;
 setSpiderOrientation(newOrientation);
}

public static var cornerAnimations:Object = {FLOOR + 2*LEFT:
"convex_floor_to_left",
 FLOOR + 2*LEFT + 4: "concave_floor_to_left",
 FLOOR + 2*RIGHT: "convew_floor_to_right",
 FLOOR + 2*RIGHT + 4: "concave_floor_to_right",
 // etc
}

functional areTilesPassableAt ( dx, dy ) {
 baseX = tileX + dx;
 baseY = tileY + dy;
 t0 = tileIsSolid ( baseX + spiderFeetDX, baseY + spiderFeetDY)
 t1 = tileIsSolid ( baseX, baseY)
 t2 = tileIsSolid ( baseX - spiderFeetDX, baseY - spiderFeetDY)
 if ( t1 || t2 ) {
   return BLOCKED;
 } else if ( t0 ) {
   return WALKABLE;
 } else {
   return GAP;
 }
}

function stopMoving() {
  velocity = new FlxPoint (0,0);
  acceleration.y = 0;
}

function setSpiderOrientation ( newDir ){
 switch ( newDir ) {
   case UPRIGHT:
     spiderGround = FLOOR;
     spiderAwayFromFloor = "UP";
     spiderTowardsFloor = "DOWN";
     spiderWalkDirection1 = "LEFT";
     spiderWalkDirection2 = "RIGHT";
     spiderHeight = 2;
     spiderWidth = 3;
     spiderFeetDX = 0;
     spiderFeetDY = +1;
   break;
   case ONLEFTWALL:
     facing = RIGHT;
     // todo
   break;
   case ONRIGHTWALL:
     facing = LEFT;
     // todo
   break;
   case UPSIDEDOWN:
     // todo
   break;
 }
}

function getSpiderPressedWalkableDeltas():FlxPoint {
 if ( spiderGround == FLOOR || spiderGround == CEILING ) {
   return new FlxPoint ( isPressed ( "RIGHT" ) ? 1 :  isPressed (
"LEFT" ) ? -1 : 0 , 0 );
 } else {
   return new FlxPoint ( 0, isPressed ( "DOWN" ) ? 1 :  isPressed (
"UP" ) ? -1 : 0 , 0 );
 }
}

function orientationFromDelta:Number( walkDelta:FlxPoint) {
 if ( walkDelta.x == 0 ) {
   if ( walkDelta.y == +1 ) {
     return UPSIDEDOWN;
   } else {
     return UPRIGHT;
   }
 } else {
   if ( walkDelta.x == -1 ) {
     return ONRIGHTWALL;
   } else {
     return ONLEFTWALL;
   }
 }
}

function solid3vacant6 ( baseX, baseY, floorDX, floorDY ) {
 orthoDX = floorDY;
 orthoDY = floorDX;
 // b - o - fl    base - floor   b + o - fl
 // base - ortho    base    base + ortho
 // b - o + fl   base + floor   b + o + fl
 // Correct if:
 // s(b+f) && s(b-o+f) && s(b+o+f) && not s(b) && not s(b-o) && not
s(b+o) && not s(b-f) && not s(b-o-f) && not s(b+o-f)
 return  tileIsSolid (baseX + floorDX, baseY + floorDY) &&
tileIsSolid (baseX - orthoDX + floorDX, baseY - orthoDY + floorDY) &&
tileIsSolid (baseX + orthoDX + floorDX, baseY + orthoDY + floorDY) &&
!tileIsSolid (baseX, baseY) && !tileIsSolid (baseX - orthoDX, baseY -
orthoDY) && !tileIsSolid (baseX + orthoDX, baseY + orthoDY) &&
!tileIsSolid (baseX - floorDX, baseY - floorDY) && !tileIsSolid (baseX
- orthoDX - floorDY, baseY - orthoDY - floorDY) && !tileIsSolid (baseX
+ orthoDX - floorDY, baseY + orthoDY - floorDY)
}

function spiderWalkInPressedDir () {
 var delta:FlxPoint = getSpiderPressedWalkableDeltas();
 if (spiderGround == LEFT || spiderGround == RIGHT) {
   if (delta.y<0 ) {
     velocity.y = -speed;
     play ( "spider_" + (spiderGround == LEFT ? "left" : "right") +
"_walk_up" );
   } else {
     velocity.y = speed;
     play ( "spider_" + (spiderGround == LEFT ? "left" : "right") +
"_walk_down" );
   }
 } else {
   if (delta.x<0 ) {
     facing = LEFT;
     velocity.x = -speed;
     play ( "spider_" + (spiderGround == FLOOR ? "floor" : "ceiling")
+ "_walk_left" );
   } else {
     facing = RIGHT;
     velocity.x = speed;
     play ( "spider_" + (spiderGround == FLOOR ? "floor" : "ceiling")
+ "_walk_right" );
   }
 }
}

function handleFallingAndGrabbing() {
 // handle falling; also grabbing onto walls
 if pressing UP {
   canGrabUp = false;
   if (isTouching(CEILING)) {
     baseX = tileX + (offset.x / 16);
     baseY = tileY - spiderHeight + (offset.y / 16) + 1;
     if solid3vacant6 ( baseX, baseY, 0, -1 ) {
       canGrabUp = true;
     }
   }
 }
 if pressing LEFT {
   canGrabLeft = false;
   if (isTouching(LEFT)) {
     baseX = tileX - (offset.x / 16) - 1;
     baseY = tileY - spiderHeight + (offset.y / 16);
     if solid3vacant6 ( baseX, baseY, -1, 0 ) {
       canGrabLeft = true;
     }
   }
 }
 if pressing RIGHT {
   canGrabRight = false;
   if (isTouching(RIGHT)) {
     baseX = tileX + (offset.x / 16)  + 1;
     baseY = tileY - spiderHeight + (offset.y / 16);
     if solid3vacant6 ( baseX, baseY, +1, 0 ) {
       canGrabRight = true;
     }
   }
 }
 if ( pressing UP && canGrabUp ) {
   // Grabbed onto a ceiling
   setSpiderOrientation ( UPSIDEDOWN);
   stopMoving();
   state = WALKING;
 } else if ( pressing LEFT && canGrabLeft )  {
   // Grabbed onto a left wall
   setSpiderOrientation ( LEFT );
   stopMoving();
   state = WALKING;
 } else if ( pressing RIGHT && canGrabRight ) {
   // Grabbed onto a right wall
   setSpiderOrientation ( RIGHT );
   stopMoving();
   state = WALKING;
 } else {
   // We're falling
   state = FALLING;
   setSpiderOrientation( UPRIGHT );
   acceleration.y = GRAVITY;
   todo - handle x/y air braking as current
 }
}