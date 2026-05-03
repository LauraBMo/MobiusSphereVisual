// ===============================================
// Scene Configuration for Mobius Sphere
// ===============================================

// Camera: slightly elevated, looking down ~17 degrees with the ball centered
// and a little headroom above for the rim highlight.
#declare MobiusCamera =
  camera {
    location <0, 2.4, -7.5>
    look_at <0, 0.55, 0>
    angle 32
  }

// Background: near-black so the lit orb pops cinematically.
#declare BackgroundColor = color rgb <0.005, 0.006, 0.012>;

// Soft fill from camera-side, low intensity, no shadows. Gives the colored
// lower hemisphere a gentle wash without flattening the Fresnel rim.
light_source {
  <-2.5, 1.4, -6.5>,
  rgb <0.32, 0.34, 0.40>
  shadowless
}

// Cool back-rim light to lift the silhouette against the dark background.
light_source {
  <2.0, 0.6, 4.0>,
  rgb <0.18, 0.22, 0.30>
  shadowless
}

// Floor plane with checker texture
#declare FloorPlane =
  plane {
    y, -1
    texture { GrayCheckerFloor }
  }
