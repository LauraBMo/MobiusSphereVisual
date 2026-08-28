// ============================================================
//  math.inc — pure math helpers (no scene parameters)
// ============================================================
#ifndef(MATH_INC)
#declare MATH_INC = true;

#declare Clamp01 = function(a)     { min(max(a, 0), 1) };
#declare Frac    = function(q)     { q - floor(q) };
#declare DistInt = function(q)     { min(Frac(q), 1 - Frac(q)) };
#declare Line    = function(q, hw) { 1 - Clamp01(DistInt(q)/hw) };

// inverse stereographic projection (unit sphere, pole = +y,
// tangent plane at the south pole)
#declare SU = function(xx, yy, zz) { 2*xx / max(1 - yy, 1e-4) };
#declare SV = function(xx, yy, zz) { 2*zz / max(1 - yy, 1e-4) };

#end
