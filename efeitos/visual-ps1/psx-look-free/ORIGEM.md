# Origem: PSX Look Free (heyheythere)

- Asset Library do Godot: https://godotengine.org/asset-library/asset/5493 (v1.0.1, licença CC-BY-4.0, Godot 4.3, atualizado 29/09/2026). Loja: https://store.godotengine.org/asset/heyheythere/psx-look-free/
- Repositório: https://github.com/Spyridon-Pikoulas/godot-psx-look-free (1 estrela, último push 30/09/2026).
- Baixado em 20/11/2026 do endereço que a Asset Library indica: https://github.com/Spyridon-Pikoulas/godot-psx-look-free/archive/d876526a2dea54ea057d300d80629f7492e194d1.zip, sha256 `f8f326566c599b5815320816033e56715bd6c4ca4ddaa912ce15f72240b1f47a` (cópia no scratchpad da sessão, não em `baixados`).
- Licença CC BY 4.0: pede crédito ao autor (linha de crédito no LICENSE.txt). A busca relata que a página diz que o pacote foi feito com ajuda de IA [documentação: Asset Library/loja].
- Copiados (de `addons/psx_look/`): `LICENSE.txt`, `shaders/psx.gdshaderinc`, `shaders/psx_lit.gdshader`.
- Alteração: `#include "res://addons/psx_look/shaders/psx.gdshaderinc"` virou `#include "psx.gdshaderinc"`.
- Arquivos do lab: `lab_lit_duplo.gdshader` (cull_disabled) e `lab_lit_transp.gdshader` (`#define PSX_TRANSPARENT`, que o include dele já aceita; a versão grátis só traz o `lit`).
- A versão grátis não traz o shader de tela (`psx_screen.gdshader`): o `PSXScreen` dela só reduz a resolução por SubViewport, que o contrato não permite. Sem efeito de tela neste candidato.
