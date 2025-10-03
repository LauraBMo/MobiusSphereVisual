// ===============================================
// Macros for Möbius Sphere Visualizer
// ===============================================

// Rainbow pigment (argument coloring)
#macro RainbowPigment()
  pigment {
    function { atan2(z,x) } // longitude angle
    color_map {
      [0.0 rgb <1,0,0>]
      [0.16 rgb <1,1,0>]
      [0.33 rgb <0,1,0>]
      [0.50 rgb <0,1,1>]
      [0.66 rgb <0,0,1>]
      [0.83 rgb <1,0,1>]
      [1.0 rgb <1,0,0>]
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

// Riemann sphere (southern hemisphere only)
#macro SphereGrid()
  sphere { <0,0,0>, 1
    texture {
      RainbowPigment()
      finish { ambient 0.2 diffuse 0.7 reflection 0.05 }
    }
    texture {
      GridPigment(pi/8, pi/8, 0.02)
      finish { ambient 0.3 diffuse 0.4 }
    }
    interior { ior 1.5 }
    clipped_by { plane { y, 0 } } // stereographic disk only
  }
#end
