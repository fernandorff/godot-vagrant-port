shader_type spatial;
// lab: psx_lit_transparent.gdshader do pacote com CULL trocado por cull_disabled
#define LIT diffuse_lambert, vertex_lighting
#define CULL cull_disabled
#define DEPTH depth_draw_always
#define BLEND blend_mix
#define ALPHA_BLEND

#include "psx_base.gdshaderinc"
