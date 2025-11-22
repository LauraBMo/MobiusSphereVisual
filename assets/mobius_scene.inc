// ===============================================
// Scene Configuration for Möbius Sphere
// ===============================================

// Camera setup
#declare MobiusCamera = 
  camera {
    location <0, 3, -8>
    look_at <0, 1, 0>
    angle 35
  }

// Background color
#declare BackgroundColor = color rgb <0.02, 0.02, 0.08>

// Light source at the north pole of the Möbius ball
#declare NorthPoleLight = 
  light_source { 
    <0, 1.001, 0>, 
    rgb <2.1, 2.1, 1.4> * 0.55 
  }

// Light source position marker
#declare LightMarker = 
  sphere {
    <0, 1.001, 0>, 0.02
    texture { pigment { color rgb <1,0.9,0.6> } finish { emission 1 } }
    no_shadow
  }

// Floor plane with checker texture
#declare FloorPlane = 
  plane {
    y, -1
    texture { GrayCheckerFloor }
  }