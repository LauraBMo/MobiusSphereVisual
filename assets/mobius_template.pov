#version 3.7;
#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "transforms.inc"

// Local files (copied to temp dir by copy_assets)
#include "macros.inc"
#include "mobius_textures.inc"
#include "mobius_scene.inc"

global_settings {
  assumed_gamma 1.0@GLOBAL_SETTINGS_EXTRA@
}

// Camera and background come from mobius_scene.inc
camera { MobiusCamera }
background { BackgroundColor }
object { FloorPlane }

// Compute current transform based on clock:
//   first half  (clock in [0, 0.5]): pure rotation ramping up to THETA
//   second half (clock in [0.5, 1]): hold rotation at THETA, ramp in translation
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

// Animated north-pole light: tracks the top of the sphere through the transform
#declare BaseNorthPole    = <0, 1.001, 0>;
#declare CurrentNorthPole = vtransform(BaseNorthPole, CurrentTransform);

light_source { CurrentNorthPole, rgb <2.1, 2.1, 1.4> * 0.55 }
sphere {
  CurrentNorthPole, 0.02
  texture { pigment { color rgb <1,0.9,0.6> } finish { emission 1 } }
  no_shadow
}

// Mobius ball: glass shell + argument-coloured lower hemisphere + highlight sheen
#declare MoebiusBall =
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.02)
    SphereHighlightSheen()
  };

object {
  MoebiusBall
  transform { CurrentTransform }
}
