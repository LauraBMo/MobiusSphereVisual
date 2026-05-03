#version 3.7;
#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "transforms.inc"

// Local files
#include "mobius_macros.inc"
#include "mobius_textures.inc"
#include "mobius_scene.inc"

global_settings {
  assumed_gamma 1.0@GLOBAL_SETTINGS_EXTRA@
}

// Use the configured camera
camera { MobiusCamera }

// Use the configured background
background { BackgroundColor }

// Use the configured floor
object { FloorPlane }

// Compute current transform based on clock
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

// Compute current north pole for light
#declare BaseNorthPole = <0, 1.001, 0>;
#declare CurrentNorthPole = vtransform(BaseNorthPole, CurrentTransform);

// Tracked key light at the current north pole. Warm and bright so the cap
// reads as illuminated from inside the orb, with a small fade so it does not
// overwhelm the static fills.
light_source {
  CurrentNorthPole,
  rgb <2.4, 2.2, 1.5> * 0.7
  fade_distance 3
  fade_power 2
}

// Small visible marker so the audience can locate the point light.
sphere {
  CurrentNorthPole, 0.02
  texture { pigment { color rgb <1, 0.9, 0.6> } finish { emission 1.0 } }
  no_shadow
}

// Mobius ball: outer Fresnel glass shell, opaque rainbow argument cap on the
// lower hemisphere (slightly inside the shell to avoid coplanar surfaces),
// and a thin sheen on the upper hemisphere for the rim highlight.
#declare MoebiusBall =
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.02)
    SphereHighlightSheen()
  };

object {
  MoebiusBall
  // Apply common transform: first move to admissible position, then animate
  transform { CurrentTransform }
}
