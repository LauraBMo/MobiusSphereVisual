// ===============================================
// Macros for Möbius Sphere Visualizer
// ===============================================

// Rainbow pigment (argument coloring)
#macro RainbowPigment()
  pigment {
    function { atan2(z,x) } // longitude angle
    color_map {
      // rgbf entries keep ~30% filter so transmitted light inherits the tint,
      // letting the argument cap cast the prismatic shadow seen in the film.
      [0.0 rgbf <1,0,0,0.3>]
      [0.16 rgbf <1,1,0,0.3>]
      [0.33 rgbf <0,1,0,0.3>]
      [0.50 rgbf <0,1,1,0.3>]
      [0.66 rgbf <0,0,1,0.3>]
      [0.83 rgbf <1,0,1,0.3>]
      [1.0 rgbf <1,0,0,0.3>]
    }
  }
#end

// Spherical lat/long grid pigment
#declare Fn_long = function(x,y,z) { atan2(z,x) }
#declare Fn_lat  = function(x,y,z) { acos(y/sqrt(x*x+y*y+z*z)) }

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

// Glass shell inspired by the luminous sphere in "Möbius Transformations Revealed":
// - Fresnel reflection keeps the rim highlights bright while preserving transparency.
// - IOR 1.52 approximates the dense glass used in the film's reference model.
#macro SphereGlassShell()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 0.85
        roughness 0.002
        reflection { 0.02, 0.25 fresnel on }
        conserve_energy
      }
    }
    interior {
      ior 1.52
      // Long fade settings mimic the subtle absorption in the cinematography plates.
      fade_power 1001
      fade_distance 5
    }
    hollow on
  }
#end

// Argument-colored cap matches the saturated stereographic disk from the film:
// - Rainbow pigment reproduces the argument ramp.
// - Grid overlay echoes the lat/long guide used to explain mappings.
#macro SphereArgumentCap(delta_lat, delta_lon, eps)
  sphere { <0,0,0>, 1
    texture {
      RainbowPigment()
      finish {
        ambient 0
        diffuse 0.12
        specular 0.45
        roughness 0.005
        reflection 0.05
        conserve_energy
      }
    }
    texture {
      GridPigment(delta_lat, delta_lon, eps)
      finish {
        ambient 0.1
        diffuse 0.25
        specular 0.1
        roughness 0.015
      }
    }
    interior {
      ior 1.36
      fade_color rgb <0.8, 0.9, 1.2>
      fade_distance 6
      fade_power 2
    }
    hollow on
    clipped_by { plane { y, 0 } }
  }
#end

// Thin sheen layer adds the soft bloom present in the cinematography plates.
#macro SphereHighlightSheen()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 0.4
        roughness 0.015
        metallic 0.1
      }
    }
    clipped_by { plane { y, 0 } }
  }
#end

#macro SphereGrid()
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.02)
    SphereHighlightSheen()
  }
#end
