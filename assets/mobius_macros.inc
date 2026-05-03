// ===================================================
// Macros for Mobius Sphere Scene  (ASCII-only)
// ===================================================

// Longitude: raw atan2 in [-pi, pi], and normalized to [0, 2*pi).
#declare Fn_long     = function(x,y,z) { atan2(z,x) }
#declare Fn_long_01  = function(x,y,z) { mod(atan2(z,x) + 2*pi, 2*pi) }
// Latitude: acos gives [0, pi]; 0 at north pole, pi at south pole.
#declare Fn_lat      = function(x,y,z) { acos(y/sqrt(x*x+y*y+z*z)) }

// --------------------------------------------------
// Rainbow pigment: argument (longitude) as hue wheel
// --------------------------------------------------
// Formula normalizes atan2 in [-pi,pi] to [0,1] with red at angle=0
// (positive x-axis), matching the standard argument-coloring convention.
// Pure rgb with no filter keeps the colours saturated and opaque.
#macro RainbowPigment()
  pigment {
    function { mod(atan2(z,x) + 2*pi, 2*pi) / (2*pi) }
    color_map {
      [0.00 rgb <1,0,0>]
      [0.16 rgb <1,1,0>]
      [0.33 rgb <0,1,0>]
      [0.50 rgb <0,1,1>]
      [0.66 rgb <0,0,1>]
      [0.83 rgb <1,0,1>]
      [1.00 rgb <1,0,0>]
    }
  }
#end

// --------------------------------------------------
// Grid pigment: symmetric distance for uniform lines
// --------------------------------------------------
// Using min(mod, spacing - mod) gives equal-width lines on both sides
// of each grid angle instead of the one-sided artifact from mod alone.
// delta_lat / delta_lon in radians; eps controls line half-width.
#macro GridPigment(delta_lat, delta_lon, eps)
  pigment {
    function {
      (min(mod(Fn_lat(x,y,z), delta_lat),
           delta_lat - mod(Fn_lat(x,y,z), delta_lat)) < eps) |
      (min(mod(Fn_long_01(x,y,z), delta_lon),
           delta_lon - mod(Fn_long_01(x,y,z), delta_lon)) < eps)
    }
    color_map {
      [0.0 rgbt <0,0,0,1>]
      [0.5 rgb  <0,0,0>]
      [1.0 rgb  <0,0,0>]
    }
  }
#end

// --------------------------------------------------
// Glass shell: the outer transparent sphere
// --------------------------------------------------
// Strong Fresnel range (0.03 -> 0.95) keeps the rim bright while
// leaving the face mostly transparent so the coloured cap shows through.
// Tight roughness 0.001 gives the sharp specular spot in the Arnold film.
#macro SphereGlassShell()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 1.0
        roughness 0.001
        reflection { 0.03, 0.95 fresnel on }
        conserve_energy
      }
    }
    interior {
      ior 1.52
      fade_color rgb <0.92, 0.93, 1.0>
      fade_distance 3
      fade_power 2
    }
    hollow on
  }
#end

// --------------------------------------------------
// Argument-coloured lower hemisphere
// --------------------------------------------------
// Clipped at y<=0 (equator) to expose the saturated hue wheel on the
// south half while leaving the north half as clear glass.
// Grid layer overlaid on top via a second texture.
#macro SphereArgumentCap(delta_lat, delta_lon, eps)
  sphere { <0,0,0>, 1
    texture {
      RainbowPigment()
      finish {
        ambient 0.02
        diffuse 0.85
        specular 0.35
        roughness 0.008
        reflection 0.04
        conserve_energy
      }
    }
    texture {
      GridPigment(delta_lat, delta_lon, eps)
      finish {
        ambient 0
        diffuse 0.5
        specular 0.05
        roughness 0.05
      }
    }
    hollow on
    clipped_by { plane { y, 0 } }
  }
#end

// --------------------------------------------------
// Specular sheen over the coloured cap
// --------------------------------------------------
// A transparent layer with tight specular makes the lower hemisphere
// look glassy without hiding the rainbow colours underneath.
#macro SphereHighlightSheen()
  sphere { <0,0,0>, 1
    texture {
      pigment { color rgbt <1,1,1,1> }
      finish {
        ambient 0
        diffuse 0
        specular 0.6
        roughness 0.008
      }
    }
    clipped_by { plane { y, 0 } }
  }
#end

// Convenience macro: full sphere assembly used in the template.
#macro SphereGrid()
  union {
    SphereGlassShell()
    SphereArgumentCap(pi/8, pi/8, 0.015)
    SphereHighlightSheen()
  }
#end
