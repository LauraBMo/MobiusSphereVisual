// ===============================================
// Scene Configuration for Mobius Sphere
// ===============================================

#declare MobiusCamera =
  camera {
    location <0, 3, -8>
    look_at <0, 1, 0>
    angle 35
  };

#declare BackgroundColor = color rgb <0.02, 0.02, 0.08>;

#declare NorthPoleLight =
  light_source {
    <0, 1.001, 0>,
    rgb <2.1, 2.1, 1.4> * 0.55
  };

#declare LightMarker =
  sphere {
    <0, 1.001, 0>, 0.02
    texture { pigment { color rgb <1,0.9,0.6> } finish { emission 1 } }
    no_shadow
  };

#declare FloorPlane =
  plane {
    y, -1
    texture { GrayCheckerFloor }
  };
