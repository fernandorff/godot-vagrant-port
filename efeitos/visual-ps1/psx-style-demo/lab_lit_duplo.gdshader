shader_type spatial;
// lab: psx_lit.gdshader do pacote com CULL trocado por cull_disabled (faces de dois lados da sala)
#define LIT diffuse_lambert, vertex_lighting
#define CULL cull_disabled
#define DEPTH depth_draw_opaque
#define BLEND blend_mix

#include "psx_base.gdshaderinc"
