// ===================================================
// Textures for Mobius Sphere Scene  (ASCII-only)
// ===================================================

// --------------------------------------------------
// Floor: dark checker, barely visible
// --------------------------------------------------
// Very low-contrast pair of near-blacks so the floor does not
// compete with the sphere for attention, while a gentle Fresnel
// reflection lets the sphere cast a soft mirror image below.
#declare GrayCheckerFloor =
  texture {
    pigment {
      checker
      color rgb <0.04, 0.04, 0.05>
      color rgb <0.08, 0.08, 0.10>
      scale 0.55
    }
    finish {
      ambient 0
      diffuse 0.6
      reflection { 0.12, 0.18 fresnel on }
      specular 0.05
      roughness 0.3
    }
  }
