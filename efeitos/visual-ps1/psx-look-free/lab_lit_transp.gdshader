shader_type spatial;
// lab: transparente pelo #define PSX_TRANSPARENT que o psx.gdshaderinc do pacote já aceita; a versão grátis não traz o arquivo
#define PSX_TRANSPARENT
render_mode vertex_lighting, specular_disabled, cull_disabled;

#include "psx.gdshaderinc"
