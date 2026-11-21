# Origem: Godot PSX Style Demo (MenacingMecha)

- Repositório oficial: https://github.com/MenacingMecha/godot-psx-style-demo (licença MIT, 20/11/2026). Página: https://menacingmecha.itch.io/godot-psx-style-demo
- Zip `baixados\godot-psx-style-demo\godot-psx-style-demo-master.zip` = https://github.com/MenacingMecha/godot-psx-style-demo/archive/refs/heads/master.zip (ramo master, último commit 91bd249 de 14/09/2023), sha256 `ef46f825839dd6b5d2ada931465cb4db9655108644ad964d0409e5a988d6b94d` (rebaixado em 20/11/2026, idêntico).
- Copiados: `LICENSE`, `shaders/psx_base.gdshaderinc`, `psx_lit.gdshader`, `psx_lit_transparent.gdshader`, `pp_band-dither.gdshader`, `psxdither.png`.
- Alteração: `pp_band-dither.gdshader` lê a tela por `hint_screen_texture` em vez de `TEXTURE` (o demo usa uma pilha de SubViewport de 320x240, que o contrato não permite: aqui o pontilhado roda na resolução cheia).
- Arquivos do lab: `lab_lit_duplo.gdshader` e `lab_lit_transp_duplo.gdshader` (os mesmos `#define` do pacote com `CULL cull_disabled`).
- O PNG é lido sem o importador (`Image.load_from_file`), para não rodar `--import` na pasta comum.
