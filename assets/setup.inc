// ============================================================
//  setup.inc — parameters, palette, masks
//  (include math.inc BEFORE this file)
// ============================================================
#ifndef(SETUP_INC)
#declare SETUP_INC = true;

// ---------- geometry / pattern ----------
#declare A       = 1.7;    // patch square half-size (smaller -> smaller cap + floor square)
#declare GridSpc = 0.5;    // floor graph-paper spacing (world grid)
#declare WireSpc = 0.425;  // rainbow black-grid spacing (= GridSpc * A/2.0, scaled to the patch)
#declare WireW   = 0.04;   // sphere wire half-width (grid units); boxcar Line -> solid black
#declare UCircW  = 0.03;   // unit-circle ring half-width, in floor/SU units (grid line ≈ 0.017)
#declare FadeR   = 20.0;   // floor fade radius

// ---------- palette ----------
#declare C_SkyHorizon = rgb <0.05, 0.055, 0.060>;
#declare C_Floor      = rgb <0.44, 0.44, 0.45>;   // darker -> renders to Arnold's ~144/255
#declare C_GridLine   = rgb <0.45, 0.45, 0.48>;
#declare C_AxisLine   = rgb <0.30, 0.30, 0.32>;
#declare C_Pin        = rgb <0.15, 0.15, 0.16>;
#declare C_Wire       = rgb <0.0, 0.0, 0.0>;
#declare C_Glass      = rgb <1.0, 1.0, 1.0>;      // clean bright glass (slightly whiter than the old 0.96)
#declare C_Glow       = rgb <0.25, 0.45, 1.0>;
#declare C_Projector  = rgb <1.8, 1.77, 1.68>;   // dimmed key: caustic sits at floor level, no glow

// rainbow stops — PURE saturated hues (Arnold measured S=0.99); brightness
// comes from the (dimmed) key light + medium-gray floor, not from the pigment.
#declare R0 = rgb <1.00, 0.00, 1.00>;   // magenta
#declare R1 = rgb <0.10, 0.10, 1.00>;   // blue
#declare R2 = rgb <0.00, 1.00, 1.00>;   // cyan
#declare R3 = rgb <0.00, 1.00, 0.00>;   // green
#declare R4 = rgb <1.00, 1.00, 0.00>;   // yellow
#declare R5 = rgb <1.00, 0.00, 0.00>;   // red

// ---------- material tuning ----------
#declare FilterAmt   = 0.85;  // CAUSTIC cap filter — tuned so the floor matches Arnold
#declare FilterView  = 0.10;  // VISIBLE cap filter — low => opaque, solid colour (no_shadow shell)
#declare GlassFilter = 0.72;  // glass transparency (lower -> whiter/milkier dome)
#declare GlassDiff   = 0.30;  // glass milkiness
// ambient turned down further (was 0.08/0.03/0.20/0.04/0.10) to cut the white self-glow
#declare AmbFloor    = 0.008;
#declare AmbGlass    = 0.10;
#declare AmbPatch    = 0.08;
#declare AmbWire     = 0.02;
#declare AmbPin      = 0.05;
// shadowless fills nearly off (was 0.18/0.15) — they only desaturate the caustic
#declare FillA       = 0.015;
#declare FillB       = 0.010;

// ---------- masks ----------
#declare PatchVal = function(xx, yy, zz) {
  select(min(A - abs(SU(xx,yy,zz)), A - abs(SV(xx,yy,zz))),
         1.0,
         (SU(xx,yy,zz)/A + 1)/2 * 0.85)
};

#declare InPatch = function(xx, yy, zz) {
  select(min(A - abs(SU(xx,yy,zz)), A - abs(SV(xx,yy,zz))), 0, 1)
};

#declare WireMask = function(xx, yy, zz) {
  InPatch(xx,yy,zz) *
  max(Line(SU(xx,yy,zz)/WireSpc, WireW),
      Line(SV(xx,yy,zz)/WireSpc, WireW))
};

// Floor unit circle FUC = {x^2 + z^2 = 1 on the floor} = {SU^2 + SV^2 = 1}; its inverse-stereo
// image P_S0^-1(FUC) is the latitude circle at local y = -3/5 (below the equator). With the
// rigid motion from MobiusSphere.Mobius_to_rigid_sitting (the sphere sits on the floor), the
// caustic realises f faithfully, so FUC is the invariant unit circle carrying the roots of
// unity: f(FUC) = FUC, and the ring stays put while the points slide along it.
#declare UnitCircleMask = function(xx, yy, zz) {
  select(UCircW - abs(sqrt(SU(xx,yy,zz)*SU(xx,yy,zz) + SV(xx,yy,zz)*SV(xx,yy,zz)) - 1.0), 0, 1)
};

#end
