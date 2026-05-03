// ===============================================
// Textures for Mobius Sphere Scene
// ===============================================

// Floor: very low-contrast dark checker with a touch of reflection so the
// colored underside of the sphere bleeds onto the floor without distracting.
#declare GrayCheckerFloor =
  texture {
    pigment {
      checker
      color rgb <0.07, 0.07, 0.085>
      color rgb <0.04, 0.04, 0.055>
      scale 0.6
    }
    finish {
      ambient 0.04
      diffuse 0.55
      specular 0.05
      roughness 0.05
      reflection { 0.04, 0.18 fresnel on }
      conserve_energy
    }
  }

// Rainbow pigment kept here for backward compatibility; the active argument
// pigment is RainbowPigment() in mobius_macros.inc.
#declare RainbowPolar = pigment {
  onion
  warp { spherical }
  color_map {
    [0.00 color rgb <0.3,0.3,1>]
    [0.30 color rgb <0.0,1.0,0.5>]
    [0.60 color rgb <1.0,0.7,0.0>]
    [0.90 color rgb <0.6,0.0,1.0>]
    [1.00 color rgb <0.3,0.3,1>]
  }
  scale 0.25
}
