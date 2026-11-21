shader_type spatial;
// lab: variante de dois lados montada com os #define do próprio pacote (common.gdshaderinc); o URSC não traz standard de dois lados
#define TEXTURE_REPEAT
#define CULL_MODE cull_disabled

#include "common.gdshaderinc"
