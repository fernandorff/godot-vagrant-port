# Origem: Procedural Torch & Candle Shader (Fire + Smoke + Sparks)

- Página oficial: https://godotshaders.com/shader/procedural-torch-candle-shader-fire-smoke-sparks/
- Autor: CaptainLaptop. Licença: "CC0 / MIT" (cabeçalho do shader e bloco de licença da página) [lido em 20/11/2026].
- Publicado em 19/10/2025, alterado em 06/11/2026 (datePublished/dateModified da página). Curtidas: 37 (contador da página, 20/11/2026).
- Tipo: `shader_type canvas_item` (2D), "Godot 4.x" (cabeçalho).
- Conferência da origem: a cópia que um agente anterior deixou em `baixados/godotshaders-tocha/tocha.gdshader` foi comparada com o
  código extraído da página baixada de novo hoje (curl, 20/11/2026 20:33): **idênticos**, sha256
  `585c8a6aa32cb747ad216bb997d233263155b0bf73edac10be4edbc74eaf2e27` (10.858 bytes) [medido].
- Página baixada hoje: sha256 `a2836709563008eb76b03f62418c663993fae367d3492fc4b27273d4e9ddcb05` (muda a cada acesso; só registro).
- Arquivo copiado para cá: `tocha.gdshader` (sem alteração).
- Uso no 3D: o shader é 2D, então o módulo desenha ele num `SubViewport` (128x256) e usa a imagem num quadrado virado para a câmera
  em cada fogo aceso. Um só SubViewport para todos os fogos (todas as chamas iguais e em fase).
