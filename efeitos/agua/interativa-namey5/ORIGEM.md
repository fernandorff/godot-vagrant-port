# Origem: godot-interactive-water (Namey5)

- Repositório oficial: https://github.com/Namey5/godot-interactive-water (autor Alex Threlfo), licença MIT (`LICENSE` ao lado). Feito para Godot 4.3.
- Baixado por mim em 20/11/2026: `https://github.com/Namey5/godot-interactive-water/archive/refs/heads/main.zip`, 11.249.701 bytes, sha256 `408b8685c964a4f2c229ddcd8c96e5ea6baf981bf5a4b2123ae3c34090ba7f16` (guardado só na pasta temporária da sessão, não em `baixados/`).
- Popularidade (API do GitHub, lida em 20/11/2026): 20 estrelas, último push 06/02/2025.
- Copiado: `shaders/water.gdshader` (original sha256 `157b55cf90f3052c7fc1ad16b90c9c06da38b7bfc810a1cccace1a763b102dd4`), `shaders/water_simulation.gdshader` (original sha256 `eef1d1091a6ecac02bb77269feba7a43ca972d81954855a91c38d743ccac9664`), `LICENSE`.
- **Alterados** (marcados com "ALTERADO" no arquivo): na simulação, 8 pés no lugar de um `mouse_pos`; na superfície, a grade de ondulação cobre um quadrado do mundo (a poça) em vez do UV da malha, a ondulação parte do zero (o original soma 0 a 1, com repouso em 0,5) e não se repete fora do quadrado.
- Não copiado: cena de teste, câmera, texturas de azulejo e o céu `.exr` (o mapa de ondas é ruído gerado em `modulo.gd`, como em `materials/water.tres`). Os dois SubViewports são montados em código.
