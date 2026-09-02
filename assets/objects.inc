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
    texture { T_UnitCircle }
    no_shadow
    translate Pos
  }
  // caustic caster — invisible to the camera, projects the coloured shadow/caustic
  sphere { <0,0,0>, Radius
    texture { T_PatchCaustic }
    texture { T_Wire }
    texture { T_UnitCircle }
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

// Labelled coordinate axes, gold. Real axis along POV x, imaginary along POV z
// (matching how the floor pattern / root discs are placed: real -> x, imag -> z),
// vertical along POV y. `L` = horizontal half-length, `Vtop` = height of the vertical.
// A label that FACES the camera: POV text reads from its -z side, so we turn the
// text's +z to point away from `CamPos` (azimuth of the camera-to-label direction
// + 180). Camera-driven, so it stays legible from any viewpoint.
#macro AxisLabel(Str, Pos, CamPos)
  #local Az = degrees(atan2(CamPos.x - Pos.x, CamPos.z - Pos.z));
  text { ttf "cyrvetic.ttf" Str 0.12, 0
    texture { T_Axis }
    scale 0.5
    rotate <0, Az + 180, 0>
    translate Pos
    no_shadow
  }
#end

#macro CoordAxes(L, Vtop, CamPos)
  #local Rr = 0.022;   // rod radius
  #local Hr = 0.06;    // arrowhead base radius
  #local Hl = 0.16;    // arrowhead length
  #local Yr = 0.03;    // lift of the floor-lying rods so they sit on the floor
  // real axis (+x) + arrowhead + "Re"
  cylinder { <-L, Yr, 0>, <L, Yr, 0>, Rr texture { T_Axis } no_shadow }
  cone { <L, Yr, 0>, Hr, <L + Hl, Yr, 0>, 0 texture { T_Axis } no_shadow }
  AxisLabel("Re", <L + Hl + 0.18, 0.06, 0.0>, CamPos)
  // imaginary axis (+z) + arrowhead + "Im"
  cylinder { <0, Yr, -L>, <0, Yr, L>, Rr texture { T_Axis } no_shadow }
  cone { <0, Yr, L>, Hr, <0, Yr, L + Hl>, 0 texture { T_Axis } no_shadow }
  AxisLabel("Im", <0.0, 0.06, L + Hl + 0.18>, CamPos)
  // vertical axis (+y) + arrowhead (unlabelled: the pole/projection axis, no complex name)
  cylinder { <0, 0, 0>, <0, Vtop, 0>, Rr texture { T_Axis } no_shadow }
  cone { <0, Vtop, 0>, Hr, <0, Vtop + Hl, 0>, 0 texture { T_Axis } no_shadow }
#end

#end
