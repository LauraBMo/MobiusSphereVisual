#version 3.7;
#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "transforms.inc"

// Local scene files
#include "mobius_macros.inc"
#include "mobius_textures.inc"
#include "mobius_scene.inc"

global_settings {
  assumed_gamma 1.0@GLOBAL_SETTINGS_EXTRA@
}

camera { MobiusCamera }

background { BackgroundColor }

object { FloorPlane }

// Static fill light (does not follow the sphere)
object { FillLight }

// --------------------------------------------------
// Animation transform based on clock in [0, 1]
// --------------------------------------------------
// First half [0, 0.5]: rotate around axis v by angle theta
// Second half [0.5, 1]: hold rotation, translate by t
#if (clock <= 0.5)
  #declare CurrentTransform = transform {
    #local rot_ang = clock * 2 * @THETA@;
    Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, rot_ang)
  };
#else
  #declare CurrentTransform = transform {
    Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, @THETA@)
    translate <@T_X@, @T_Y@, @T_Z@>*(clock-0.5)*2
  };
#end

// --------------------------------------------------
// Key light: tracks the sphere's north pole
// --------------------------------------------------
// Base position is 1.5 units above sphere surface so the light
// spreads across the whole sphere rather than from a point on skin.
#declare BaseNorthPole = <0, 2.5, 0>;
#declare CurrentNorthPole = vtransform(BaseNorthPole, CurrentTransform);

light_source { CurrentNorthPole, rgb <1.5, 1.4, 1.2> }

// --------------------------------------------------
// Sphere assembly
// --------------------------------------------------
#declare MoebiusBall =
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.015)
    SphereHighlightSheen()
  };

object {
  MoebiusBall
  transform { CurrentTransform }
}
