// ============================================================
//  mobius_template.pov — new-look texture scene, clock-driven Möbius motion.
//
//  The coloured floor square is the stereographic-projection TEXTURE on the
//  shell's lower cap (see mobius/ setup), NOT a photon caustic — so no photons.
//  Emit.jl fills @V_*@/@THETA@/@T_*@ with the Julia (v,θ,t) already swapped to
//  POV y-up (axes 2↔3) and θ in degrees.
// ============================================================
#version 3.7;

#include "transforms.inc"      // Axis_Rotate_Trans (POV-Ray standard include)
#include "math.inc"
#include "setup.inc"
#include "textures.inc"
#include "objects.inc"

global_settings { assumed_gamma 1.0 }

// ---------- Möbius rigid-motion parameters (POV y-up; already swapped, θ in degrees) ----------
#declare Vax = <@V_X@, @V_Y@, @V_Z@>;
#declare Th  = @THETA@;
#declare Tv  = <@T_X@, @T_Y@, @T_Z@>;

#declare SphC0    = <0, 1.0, 0>;      // rest sphere centre (radius 1, sits on the floor)
#declare PoleBase = SphC0 + <0, 1, 0>;

// ---------- clock-driven motion: phase 1 rotates about the centre, phase 2 translates ----------
#if (clock <= 0.5)
  #declare Ang = clock * 2 * Th;
  #declare Motion = transform {
    translate -SphC0
    Axis_Rotate_Trans(Vax, Ang)
    translate  SphC0
  }
  #declare PoleNow = vaxis_rotate(PoleBase - SphC0, Vax, Ang) + SphC0;
#else
  #declare Motion = transform {
    translate -SphC0
    Axis_Rotate_Trans(Vax, Th)
    translate  SphC0
    translate  Tv * (clock - 0.5) * 2
  }
  #declare PoleNow = vaxis_rotate(PoleBase - SphC0, Vax, Th) + SphC0 + Tv * (clock - 0.5) * 2;
#end

// ---------- camera ----------
camera {
  location <4.5, 3.4, -8.0>
  look_at  <0, 0.9, 0>
  right x * image_width/image_height
  angle 42
}

// ---------- lights (projector follows the moving north pole) ----------
light_source { PoleNow + <0, 0.0001, 0> color C_Projector }
light_source { <-8, 6, -4> color rgb FillA shadowless }
light_source { <6, 5, -9>  color rgb FillB shadowless }

// ---------- sky ----------
sky_sphere {
  pigment {
    gradient y
    color_map { [0.00 color C_SkyHorizon] [0.30 color rgb 0] [1.00 color rgb 0] }
  }
}

// ---------- assembly ----------
FloorPlane()
AxisPin(2.45)                                   // static world reference axis
union { GlassBall(SphC0, 1)           transform { Motion } }
union { ProjectionShell(SphC0, 1.001) transform { Motion } }
GlowDot(PoleNow, 0.045)
