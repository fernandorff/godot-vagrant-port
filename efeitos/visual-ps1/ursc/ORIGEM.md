# Origem: Ultimate Retro Shader Collection (Zorochase)

- Repositório oficial: https://github.com/Zorochase/ultimate-retro-shader-collection (licença MIT, lida na API do GitHub e no LICENSE.md, 20/11/2026). Página: https://zorochase.itch.io/ultimate-retro-shader-collection-for-godot
- Zips em `baixados\ultimate-retro-shader-collection\` (conferidos em 20/11/2026: rebaixados dos releases do GitHub, sha256 idêntico):
  - `ursc_1.5.zip` = https://github.com/Zorochase/ultimate-retro-shader-collection/releases/download/1.5/ursc_1.5.zip (30/08/2026), sha256 `0f51d10e9846e815bd35e4dd67664c7f7e8ebf307950f3936de4907be14c3a8f`. **Usado.**
  - `ursc_1.4.0.zip` = .../releases/download/1.4.0/ursc_1.4.0.zip (10/03/2025), sha256 `9c37964df6380075486817eb804471c9e26ecf5175dc507c67128fecf0863da6`. Não usado: a 1.5 é a mais nova e, nos arquivos usados, difere só por reorganização e pela correção do `#define TEXTURE_REPEAT` no shader transparente (diff dos zips, 20/11/2026).
- Copiados (de `addons/ursc/`): `LICENSE.md`, `spatial/common.gdshaderinc`, `spatial/utilities.gdshaderinc` (incluído pelo `common`), `spatial/standard/standard_opaque_repeating.gdshader`, `spatial/standard/standard_transparent_repeating.gdshader`, `canvas_item/dithering.gdshader`.
- Alterações: `#include "../common.gdshaderinc"` virou `#include "common.gdshaderinc"`; no `dithering.gdshader`, a imagem lida passou de `TEXTURE`/`UV` para uma `hint_screen_texture`/`SCREEN_UV` (o original é para SubViewportContainer, que o contrato não permite).
- Arquivos do lab: `lab_opaco_duplo.gdshader` e `lab_transp_duplo.gdshader` (só `#define` do próprio pacote, com `CULL_MODE cull_disabled`, para as faces de dois lados da sala). A textura de padrão do pontilhado (o pacote não traz) é uma matriz de Bayer 4x4 gerada em `comum/troca.gd`.
- Não copiado: `setup.gd` (grava `ProjectSettings`). Os uniformes globais são criados em tempo de execução com os valores dele, menos `cull_distance` = 0 (o padrão 64 corta a sala ao longe).
