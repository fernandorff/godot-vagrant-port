# Origem: shader de névoa do demo oficial "Volumetric Fog" (godot-demo-projects)

- Download oficial: https://github.com/godotengine/godot-demo-projects/releases/download/4.2-31d1c0c/3d_volumetric_fog.zip
  (link da Asset Library, asset 2754: https://godotengine.org/asset-library/asset/2754)
- Arquivo usado: `baixados/volumetric-fog-demo/3d_volumetric_fog.zip`, 454.060 bytes,
  sha256 `6d1f7aad6fb52bf4e1aa1b45410e552d302adb9de3af581c1d93fd23c5c414df`.
  Conferido em 20/11/2026 baixando de novo do link oficial: mesmo tamanho e mesmo sha256 [medido].
- Licença: MIT (repositório godotengine/godot-demo-projects, `spdx_id` lido na API do GitHub em 20/11/2026).
  O ruído é de Inigo Quilez (MIT, cabeçalho mantido no shader); o shader é creditado a alghost no README do demo
  (https://godotshaders.com/shader/moving-gradient-noise-fog-mist-for-godot-4/).
- Popularidade: repositório com 9.818 estrelas, último push 08/10/2026 (API do GitHub, lida em 20/11/2026).
- Copiado: só o código do sub-recurso `Shader_1xpcs` de `volumetric_fog/volumetric_fog.tscn` -> `nevoa-ruido.gdshader`
  (lógica sem mudança). Nada mais do zip foi copiado.
- Parâmetros mudados no `modulo.gd` (não no shader): densidade 0,25, cor `#bfd1ff`, altura de corte 0,5 + 2,5, velocidades
  do ruído reduzidas para ~1/3.
