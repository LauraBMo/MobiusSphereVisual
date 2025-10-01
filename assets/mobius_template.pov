#version 3.7;
#include "colors.inc"
#include "glass.inc"
#include "transforms.inc"

global_settings { assumed_gamma 1.0 }

camera {
  location <0, 3, -8>
  look_at <0, 1, 0>
  angle 35
}

background { color rgb <0.02, 0.02, 0.08> }

light_source { <10, 20, -5>, rgb 1 }

#declare RainbowPolar = pigment {
  uv_mapping
  gradient u
  color_map {
    [0.00 rgb <1,0,0>]
    [0.16 rgb <1,1,0>]
    [0.33 rgb <0,1,0>]
    [0.50 rgb <0,1,1>]
    [0.66 rgb <0,0,1>]
    [0.83 rgb <1,0,1>]
    [1.00 rgb <1,0,0>]
  }
  quick_color rgb <1,0.5,0>
}

// Compute current transform based on clock
// #declare CurrentTransform =
//   #if (clock <= 0.5)
//     #local rot_angle = clock * 2 * @THETA@;
//     transform { Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, rot_angle) }
//   #else
//     transform {
//       Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, @THETA@)
//       translate <@T_X@*(clock-0.5)*2, @T_Y@*(clock-0.5)*2, @T_Z@*(clock-0.5)*2>
//     }
//   #end
// ;

#if (clock <= 0.5)
  #declare CurrentTransform = transform {
    #local rot_ang = clock * 2 * @THETA@;
    Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, rot_ang)
  };
#else
  #declare CurrentTransform = transform {
    Axis_Rotate_Trans(<@V_X@, @V_Y@, @V_Z@>, @THETA@)
    translate <@T_X@*(clock-0.5)*2, @T_Y@*(clock-0.5)*2, @T_Z@*(clock-0.5)*2>
  };
#end

// Compute current north pole for light
#declare BaseNorthPole = <0, 2, 0>;
#declare CurrentNorthPole = vtransform(BaseNorthPole, CurrentTransform);

#declare AdmissibleGlass = texture {
  pigment { rgbt <0.92, 0.96, 1.0, 0.65> }  // transparent bluish-white
  finish {
    ambient 0.1
    diffuse 0.4
    specular 0.5
    roughness 0.001
    reflection { 0.15 metallic }
    ior 1.5
  }
};

// Union of glass sphere and clipped textured overlay
union {
  // 1. Full transparent glass sphere
  sphere { y, 1
    texture { AdmissibleGlass }
  }

  // 2. Textured cap (corresponds to unit disk)
  sphere { <0, 0, 0>, 1
    pigment { RainbowPolar }
    clipped_by { plane { y, 0.4 } }  // keeps y <= 0.4
  }

  // Apply common transform: first move to admissible position, then animate
  transform { CurrentTransform }
}

// Emissive light at current north pole
light_source { CurrentNorthPole, rgb <1.8, 1.8, 1.2> * 0.35 }
