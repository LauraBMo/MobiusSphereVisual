// ============================================================
//  objects.inc — macros assembling objects from textures
// ============================================================
#ifndef(OBJECTS_INC)
#declare OBJECTS_INC = true;

#macro FloorPlane()
  plane {
    y, 0
    texture { T_FloorBase }
    texture { T_FloorGrid }
    texture { T_FloorAxes }
    texture { T_FloorFade }
  }
#end

#macro AxisPin(Height)
  cylinder { <0, 0, 0>, <0, Height, 0>, 0.02
    texture { T_Pin }
    no_shadow
  }
#end

#macro GlassBall(Pos, Radius)
  sphere { <0,0,0>, Radius
    texture { T_Glass }
    no_shadow
    translate Pos
  }
#end

#macro ProjectionShell(Pos, Radius)
  // visible opaque colour cap — casts NO shadow (appearance only)
  sphere { <0,0,0>, Radius
    texture { T_PatchView }
    texture { T_Wire }
    no_shadow
    translate Pos
  }
  // caustic caster — invisible to the camera, projects the coloured shadow/caustic
  sphere { <0,0,0>, Radius
    texture { T_PatchCaustic }
    texture { T_Wire }
    no_image
    translate Pos
  }
#end

#macro GlowDot(Pos, Radius)
  sphere { 0, Radius
    texture { T_Glow }
    no_shadow
    translate Pos
  }
#end

#end
