// ===================================================
// Scene Configuration for Mobius Sphere  (ASCII-only)
// ===================================================

// --------------------------------------------------
// Camera
// --------------------------------------------------
// Positioned so the look-direction drops ~18 degrees below horizontal,
// giving a slight top-down view with headroom above the sphere.
// angle 38 widens the FOV just enough to frame the floor reflection.
#declare MobiusCamera =
  camera {
    location <0, 3, -8>
    look_at  <0, 0.2, 0>
    angle 38
  }

// --------------------------------------------------
// Background
// --------------------------------------------------
// Near-black with a faint blue tint matches the dark void in the film.
#declare BackgroundColor = color rgb <0.005, 0.005, 0.01>

// --------------------------------------------------
// Key light (north-pole tracker -- base position)
// --------------------------------------------------
// Declared here for reference; the template recomputes the animated
// position each frame by applying CurrentTransform.
#declare NorthPoleLightBase = <0, 2.5, 0>
#declare NorthPoleLightColor = rgb <1.5, 1.4, 1.2>

// Convenience object used when no animation transform is needed.
#declare NorthPoleLight =
  light_source {
    NorthPoleLightBase,
    NorthPoleLightColor
  }

// --------------------------------------------------
// Fill light (static -- does not follow the sphere)
// --------------------------------------------------
// Cool, dim fill from the front-left below horizon reduces pure-black
// shadow regions without washing out the dark background.
#declare FillLight =
  light_source {
    <-4, -0.5, -5>, rgb <0.08, 0.08, 0.16>
  }

// --------------------------------------------------
// Floor plane
// --------------------------------------------------
#declare FloorPlane =
  plane {
    y, -1
    texture { GrayCheckerFloor }
  }
