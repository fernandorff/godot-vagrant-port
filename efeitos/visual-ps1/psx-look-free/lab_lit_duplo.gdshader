shader_type spatial;
// lab: psx_lit.gdshader do pacote com cull_disabled (faces de dois lados da sala); a versão grátis só traz o lit
render_mode vertex_lighting, specular_disabled, cull_disabled;

#include "psx.gdshaderinc"
