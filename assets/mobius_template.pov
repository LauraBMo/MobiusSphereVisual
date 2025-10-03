#version 3.7;
#include "colors.inc"
#include "textures.inc"
#include "glass.inc"
#include "transforms.inc"

// Local files
#include "macros.inc"

global_settings { assumed_gamma 1.0 }

camera {
  location <0, 3, -8>
  look_at <0, 1, 0>
  angle 35
}

background { color rgb <0.02, 0.02, 0.08> }

light_source { <10, 20, -5>, rgb 1 }

// Complex plane with grid pattern
plane {
  y, -1
  texture {
    pigment {
      checker
      color rgbf <0.8, 0.8, 0.8, 0.5>
      color rgbf <0.6, 0.6, 0.6, 0.5>
      scale 0.4
    }
    finish {
      ambient 0.3
      diffuse 0.7
      reflection 0.1
    }
  }
}

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

#declare RainbowPolar = pigment {
  onion
  warp { spherical }
  color_map {
    [0.00 color rgbf <0.3,0.3,1,0.5>]   // indigo
    // [0.15 color rgbf <0.0,0.7,1,0.5>]   // cyan
    [0.30 color rgbf <0.0,1,0.5,0.5>]   // green
    // [0.45 color rgbf <0.7,1,0.0,0.5>]   // yellow-green
    [0.60 color rgbf <1,0.7,0.0,0.5>]   // orange
    // [0.75 color rgbf <1,0.0,0.3,0.5>]   // magenta-red
    [0.90 color rgbf <0.6,0.0,1,0.5>]   // violet
    [1.00 color rgbf <0.3,0.3,1,0.5>]   // wrap back to indigo
  }
  scale 0.25
}

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

// Emissive light at current north pole
light_source { CurrentNorthPole, rgb <1.8, 1.8, 1.2> * 0.35 }

// small visible marker for the light source
sphere {
  CurrentNorthPole, 0.02
  texture { pigment { color rgb <1,0.9,0.6> } finish { emission 1 } }
  no_shadow
}

// Union of glass sphere and clipped textured overlay
// #declare SphereGrid =
//   union {
//     // 1. Full transparent glass sphere
//     sphere { 0, 1
//       texture { Glass }
//     }

//     // 2. Textured cap (corresponds to unit disk)
//     sphere { 0, 1
//       texture {
//         pigment { RainbowPolar }
//         finish { ambient 0 diffuse 0.7 specular 0.2 }
//       }
//       clipped_by { plane { y,  1} }  // keeps y <= 0.4
//     }
//   };

#declare MySphereGrid =
  union {
    // 1. Full transparent glass sphere
    // sphere { 0, 1
    //   texture {
    //     Glass
    //     finish { ambient 0 diffuse 0.7 specular 0.2 }
    //   }
    //   hollow on
    //   interior { ior 1.0 } // keep light transmission simple
    // }
    SphereGrid()
    // sphere { 0.001, 1
    //   texture {
    //     pigment {
    //       // rainbow stripes in longitude (phi)
    //       gradient y
    //       color_map {
    //         [0.0  color rgbf <1,0,0,0.4>]   // red, translucent
    //         [0.17 color rgbf <1,0.5,0,0.4>] // orange
    //         [0.33 color rgbf <1,1,0,0.4>]   // yellow
    //         [0.4 color rgbf <0,1,0,0.4>]   // green
    //         [0.4 color rgbf <1,1,1,0>]
    //         [1.0  color rgbf <1,1,1,0>]
    //       }
    //       warp { spherical }
    //     }
    //     // finish { ambient 0 diffuse 0.7 specular 0.6 }
    //   }
    //   clipped_by { plane { y,  0.4} }  // keeps y <= 0.4
    // }
  };

object {
  MySphereGrid
  // Apply common transform: first move to admissible position, then animate
  transform { CurrentTransform }
}
