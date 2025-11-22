// ===============================================
// Textures for Möbius Sphere Scene
// ===============================================

// Gray checker floor texture
#declare GrayCheckerFloor = 
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

// Rainbow pigment (argument coloring) for the Möbius ball
#declare RainbowPolar = pigment {
  onion
  warp { spherical }
  color_map {
    [0.00 color rgbf <0.3,0.3,1,0.5>]   // indigo
    [0.30 color rgbf <0.0,1,0.5,0.5>]   // green
    [0.60 color rgbf <1,0.7,0.0,0.5>]   // orange
    [0.90 color rgbf <0.6,0.0,1,0.5>]   // violet
    [1.00 color rgbf <0.3,0.3,1,0.5>]   // wrap back to indigo
  }
  scale 0.25
}