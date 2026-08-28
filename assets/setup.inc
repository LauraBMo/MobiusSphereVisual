// ============================================================
//  setup.inc — parameters, palette, masks
//  (include math.inc BEFORE this file)
// ============================================================
#ifndef(SETUP_INC)
#declare SETUP_INC = true;

// ---------- geometry / pattern ----------
#declare A       = 2.0;    // patch square half-size
#declare GridSpc = 0.5;    // grid spacing (floor AND sphere)
#declare WireW   = 0.06;   // sphere wire width (grid units)
#declare FadeR   = 20.0;   // floor fade radius

// ---------- palette ----------
#declare C_SkyHorizon = rgb <0.05, 0.055, 0.060>;
#declare C_Floor      = rgb <0.75, 0.76, 0.78>;
#declare C_GridLine   = rgb <0.45, 0.45, 0.48>;
#declare C_AxisLine   = rgb <0.30, 0.30, 0.32>;
#declare C_Pin        = rgb <0.15, 0.15, 0.16>;
#declare C_Wire       = rgb <0.02, 0.02, 0.02>;
#declare C_Glass      = rgb <0.96, 0.96, 0.96>;
#declare C_Glow       = rgb <0.25, 0.45, 1.0>;
#declare C_Projector  = rgb <2.8, 2.75, 2.6>;

// rainbow stops
#declare R0 = rgb <0.35, 0.05, 0.55>;
#declare R1 = rgb <0.10, 0.20, 0.85>;
#declare R2 = rgb <0.00, 0.75, 0.85>;
#declare R3 = rgb <0.15, 0.85, 0.25>;
#declare R4 = rgb <0.95, 0.90, 0.15>;
#declare R5 = rgb <0.95, 0.20, 0.10>;

// ---------- material tuning ----------
#declare FilterAmt   = 0.55;  // patch translucency for light
#declare GlassFilter = 0.80;  // glass transparency
#declare GlassDiff   = 0.30;  // glass milkiness
#declare AmbFloor    = 0.08;
#declare AmbGlass    = 0.03;
#declare AmbPatch    = 0.20;
#declare AmbWire     = 0.04;
#declare AmbPin      = 0.10;
#declare FillA       = 0.18;
#declare FillB       = 0.15;

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
  max(Line(SU(xx,yy,zz)/GridSpc, WireW),
      Line(SV(xx,yy,zz)/GridSpc, WireW))
};

#end
