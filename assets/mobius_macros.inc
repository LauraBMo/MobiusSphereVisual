// ===============================================
// Macros for Mobius Sphere Scene
// ===============================================

// Function definitions for latitude and longitude
#declare Fn_long = function(x,y,z) { atan2(z,x) }
#declare Fn_lat  = function(x,y,z) { acos(y/sqrt(x*x+y*y+z*z)) }

// Rainbow pigment (argument coloring). Opaque saturated hues so the cap reads
// like the painted lower hemisphere from "Mobius Transformations Revealed":
// red -> yellow -> green -> cyan -> blue -> magenta -> red around the equator.
#macro RainbowPigment()
  pigment {
    function { (atan2(z,x) + pi) / (2*pi) }
    color_map {
      [0.000 rgb <1.00, 0.05, 0.05>]
      [0.167 rgb <1.00, 0.95, 0.05>]
      [0.333 rgb <0.05, 0.85, 0.20>]
      [0.500 rgb <0.05, 0.85, 0.95>]
      [0.667 rgb <0.10, 0.20, 1.00>]
      [0.833 rgb <0.95, 0.10, 0.85>]
      [1.000 rgb <1.00, 0.05, 0.05>]
    }
  }
#end

// Spherical lat/long grid pigment
#macro GridPigment(delta_lat, delta_lon, eps)
  pigment {
    function {
      (abs(mod(Fn_lat(x,y,z), delta_lat)) < eps) |
      (abs(mod(Fn_long(x,y,z), delta_lon)) < eps)
    }
    color_map {
      [0 rgbt <0,0,0,1>]
      [0.5 rgb <0,0,0>]
      [1 rgb <0,0,0>]
    }
  }
#end

// Glass shell inspired by the luminous sphere in "Mobius Transformations Revealed":
// crystal-orb feel with bright Fresnel rim and a small internal-glow tint.
#macro SphereGlassShell()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 1.0
        roughness 0.0015
        reflection { 0.04, 0.55 fresnel on }
        conserve_energy
      }
    }
    interior {
      ior 1.52
      // Subtle warm absorption so the orb glows from within under the key light.
      fade_power 1001
      fade_distance 4
      fade_color rgb <0.92, 0.95, 1.0>
    }
    hollow on
  }
#end

// Argument-colored cap matches the saturated stereographic disk from the film:
// - Opaque rainbow pigment reproduces the argument ramp.
// - Grid overlay echoes the lat/long guide used to explain mappings.
// Lower hemisphere only: clipped at y = 0 (the equator).
#macro SphereArgumentCap(delta_lat, delta_lon, eps)
  sphere { <0,0,0>, 0.998
    texture {
      RainbowPigment()
      finish {
        ambient 0.18
        emission 0.06
        diffuse 0.85
        specular 0.18
        roughness 0.06
      }
    }
    texture {
      GridPigment(delta_lat, delta_lon, eps)
      finish {
        ambient 0.0
        diffuse 0.0
        specular 0.0
      }
    }
    clipped_by { plane { y, 0 } }
  }
#end

// Thin sheen layer over the upper (uncolored) hemisphere: a soft warm rim
// that nudges the orb toward the Arnold-Rogness crystal-ball look without
// fighting the saturated argument cap below.
#macro SphereHighlightSheen()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 0.55
        roughness 0.01
        metallic 0.12
      }
    }
    clipped_by { plane { -y, 0 } }
  }
#end

// Complete sphere with glass shell, argument cap and highlight sheen
#macro SphereGrid()
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.02)
    SphereHighlightSheen()
  }
#end