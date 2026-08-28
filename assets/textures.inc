// ============================================================
//  textures.inc — reusable textures
// ============================================================
#ifndef(TEXTURES_INC)
#declare TEXTURES_INC = true;

// ---------- floor ----------
#declare T_FloorBase = texture {
  pigment { color C_Floor }
  finish { ambient rgb AmbFloor diffuse 0.75 reflection 0.08 }
};

#declare T_FloorGrid = texture {
  pigment {
    function { max(Line(x/GridSpc, 0.04), Line(z/GridSpc, 0.04)) }
    color_map { [0 rgbt <0,0,0,1>] [1 color C_GridLine] }
  }
  finish { ambient rgb AmbFloor diffuse 0.75 }
};

#declare T_FloorAxes = texture {
  pigment {
    function { max(Line(z, 0.015), Line(x, 0.015)) }
    color_map { [0 rgbt <0,0,0,1>] [1 color C_AxisLine] }
  }
  finish { ambient rgb AmbFloor diffuse 0.75 }
};

#declare T_FloorFade = texture {
  pigment {
    function { min(max(sqrt(x*x + z*z)/FadeR, 0), 1) }
    color_map {
      [0.00 rgbt <0,0,0,1>]
      [0.50 rgbt <0,0,0,1>]
      [1.00 rgb 0]
    }
  }
  finish { ambient rgb 1 diffuse 0 }
};

// ---------- sphere: glass ----------
#declare T_Glass = texture {
  pigment { color C_Glass filter GlassFilter }
  finish { ambient rgb AmbGlass diffuse GlassDiff
           specular 0.25 phong 0.3 phong_size 25 }
};

// ---------- sphere: rainbow patch ----------
#declare T_Patch = texture {
  pigment {
    function { PatchVal(x, y, z) }
    color_map {
      [0.00 color R0 filter FilterAmt]
      [0.17 color R1 filter FilterAmt]
      [0.34 color R2 filter FilterAmt]
      [0.51 color R3 filter FilterAmt]
      [0.68 color R4 filter FilterAmt]
      [0.85 color R5 filter FilterAmt]
      [0.86 rgbt <0,0,0,1>]
      [1.00 rgbt <0,0,0,1>]
    }
  }
  finish { ambient rgb AmbPatch diffuse 0.90 }
};

// ---------- sphere: black grid ----------
#declare T_Wire = texture {
  pigment {
    function { WireMask(x, y, z) }
    color_map { [0 rgbt <0,0,0,1>] [1 color C_Wire] }
  }
  finish { ambient rgb AmbWire diffuse 0.60 }
};

// ---------- misc ----------
#declare T_Pin = texture {
  pigment { color C_Pin }
  finish { ambient rgb AmbPin diffuse 0.65 }
};

#declare T_Glow = texture {
  pigment { color C_Glow }
  finish { ambient rgb <0.8, 1.4, 4.0> diffuse 0 }
};

#end
