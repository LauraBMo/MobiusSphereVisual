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

// plane { y, 0
  //   pigment{
    //     checker White Black
    //     scale 0.5
    //   }
  // }

// #declare RainbowPolar = pigment {
  //   uv_mapping
  //   gradient u
  //   color_map {
    //     [0.00 rgb <1,0,0>]
    //     [0.16 rgb <1,1,0>]
    //     [0.33 rgb <0,1,0>]
    //     [0.50 rgb <0,1,1>]
    //     [0.66 rgb <0,0,1>]
    //     [0.83 rgb <1,0,1>]
    //     [1.00 rgb <1,0,0>]
    //   }
  //   quick_color rgb <1,0.5,0>
  // }



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

// Emissive light at current north pole (using updated position)
light_source { CurrentNorthPole, rgb <2.1, 2.1, 1.4> * 0.55 }

// small visible marker for the light source
sphere {
  CurrentNorthPole, 0.02
  texture { pigment { color rgb <1,0.9,0.6> } finish { emission 1 } }
  no_shadow
}

// The Möbius ball - a blurry unit ball with rainbow-colored gird covering the bottom half up to 0.8 in height
#declare MoebiusBall =
  union {
    // Glass shell for the blurry effect
    SphereGlassShell()
    
    // Rainbow-colored gird covering the bottom half up to 0.8 in height
    SphereArgumentCap(pi/8, pi/8, 0.02)
    
    // Highlight sheen
    SphereHighlightSheen()
  };

object {
  MoebiusBall
  // Apply common transform: first move to admissible position, then animate
  transform { CurrentTransform }
}
