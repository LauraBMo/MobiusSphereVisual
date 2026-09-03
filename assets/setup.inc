// ============================================================
//  setup.inc — parameters, palette, masks
//  (include math.inc BEFORE this file)
//
//  Every scalar/colour/vector below is #ifndef-guarded, so each one is a
//  SETTABLE GLOBAL: #declare it before this file is included and the value
//  here yields to yours. MobiusSphereVisual's Scene.jl emits that override
//  block from `set_scene!` / `render_scene` (keys mirror these POV names).
//  Anything left unset keeps the Arnold default.
// ============================================================
#ifndef(SETUP_INC)
#declare SETUP_INC = true;

// ---------- geometry / pattern ----------
#ifndef(A)       #declare A       = 1.7;   #end  // patch square half-size (smaller -> smaller cap + floor square)
#ifndef(GridSpc) #declare GridSpc = 0.5;   #end  // floor graph-paper spacing (world grid)
#ifndef(WireSpc) #declare WireSpc = GridSpc * A / 2.0; #end  // rainbow black-grid spacing (derives from GridSpc, A)
#ifndef(WireW)   #declare WireW   = 0.04;  #end  // sphere wire half-width (grid units); boxcar Line -> solid black
#ifndef(UCircW)  #declare UCircW  = 0.03;  #end  // unit-circle ring half-width, in floor/SU units (grid line ≈ 0.017)
#ifndef(FadeR)   #declare FadeR   = 20.0;  #end  // floor fade radius

// ---------- camera + placement ----------
#ifndef(SphC0)    #declare SphC0    = <0, 1.0, 0>;    #end  // rest sphere centre (radius 1, sits on the floor)
#ifndef(CamLoc)   #declare CamLoc   = <8.5, 3.5, 4.5>; #end  // camera location (axis labels read it, so they face you)
#ifndef(CamLook)  #declare CamLook  = <0, 0.7, 0>;    #end  // camera look_at target
#ifndef(CamAngle) #declare CamAngle = 42;             #end  // camera field-of-view angle
#ifndef(AxisLen)  #declare AxisLen  = 2.0;            #end  // CoordAxes horizontal half-length
#ifndef(AxisVtop) #declare AxisVtop = 2.3;            #end  // CoordAxes vertical height

// ---------- assembly toggles (set a flag false to drop that built-in object) ----------
#ifndef(ShowFloor) #declare ShowFloor = true; #end
#ifndef(ShowAxes)  #declare ShowAxes  = true; #end
#ifndef(ShowGlass) #declare ShowGlass = true; #end
#ifndef(ShowShell) #declare ShowShell = true; #end
#ifndef(ShowGlow)  #declare ShowGlow  = true; #end

// ---------- palette ----------
#ifndef(C_SkyHorizon) #declare C_SkyHorizon = rgb <0.05, 0.055, 0.060>; #end
#ifndef(C_Floor)      #declare C_Floor      = rgb <0.44, 0.44, 0.45>;   #end  // darker -> renders to Arnold's ~144/255
#ifndef(C_GridLine)   #declare C_GridLine   = rgb <0.45, 0.45, 0.48>;   #end
#ifndef(C_AxisLine)   #declare C_AxisLine   = rgb <0.30, 0.30, 0.32>;   #end
#ifndef(C_Pin)        #declare C_Pin        = rgb <0.15, 0.15, 0.16>;   #end
#ifndef(C_Wire)       #declare C_Wire       = rgb <0.0, 0.0, 0.0>;      #end
#ifndef(C_Glass)      #declare C_Glass      = rgb <1.0, 1.0, 1.0>;      #end  // clean bright glass
#ifndef(C_Glow)       #declare C_Glow       = rgb <0.25, 0.45, 1.0>;    #end
#ifndef(C_Projector)  #declare C_Projector  = rgb <1.8, 1.77, 1.68>;    #end  // dimmed key
#ifndef(C_Axis)       #declare C_Axis       = rgb <0.92, 0.73, 0.16>;   #end  // yellowish-gold labelled axes

// rainbow stops — PURE saturated hues (Arnold measured S=0.99); brightness
// comes from the (dimmed) key light + medium-gray floor, not from the pigment.
#ifndef(R0) #declare R0 = rgb <1.00, 0.00, 1.00>; #end  // magenta
#ifndef(R1) #declare R1 = rgb <0.10, 0.10, 1.00>; #end  // blue
#ifndef(R2) #declare R2 = rgb <0.00, 1.00, 1.00>; #end  // cyan
#ifndef(R3) #declare R3 = rgb <0.00, 1.00, 0.00>; #end  // green
#ifndef(R4) #declare R4 = rgb <1.00, 1.00, 0.00>; #end  // yellow
#ifndef(R5) #declare R5 = rgb <1.00, 0.00, 0.00>; #end  // red

// ---------- material tuning ----------
#ifndef(FilterAmt)   #declare FilterAmt   = 0.85; #end  // CAUSTIC cap filter — tuned so the floor matches Arnold
#ifndef(FilterView)  #declare FilterView  = 0.35; #end  // VISIBLE cap TRANSMIT — non-colouring transparency
#ifndef(GlassFilter) #declare GlassFilter = 0.72; #end  // glass transparency (lower -> whiter/milkier dome)
#ifndef(GlassDiff)   #declare GlassDiff   = 0.30; #end  // glass milkiness
#ifndef(AmbFloor)    #declare AmbFloor    = 0.008; #end
#ifndef(AmbGlass)    #declare AmbGlass    = 0.10;  #end
#ifndef(AmbPatch)    #declare AmbPatch    = 0.08;  #end
#ifndef(AmbWire)     #declare AmbWire     = 0.02;  #end
#ifndef(AmbPin)      #declare AmbPin      = 0.05;  #end
#ifndef(FillA)       #declare FillA       = 0.015; #end  // shadowless fills nearly off
#ifndef(FillB)       #declare FillB       = 0.010; #end

// ---------- masks (derived from the geometry params above; not directly overridable) ----------
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
