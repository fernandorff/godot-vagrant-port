# Origem: PS1 / PSX Visuals - GD4 Port (scolastico)

- Repositório oficial: https://github.com/scolastico/psx_visuals_gd4 (licença MIT, lida na API do GitHub e no LICENSE do pacote, 20/11/2026).
- Asset Library do Godot: https://godotengine.org/asset-library/asset/4687 (v2.1.3, aponta para o commit cfe115f).
- Zips em `baixados\psx_visuals_gd4\` (conferidos em 20/11/2026: rebaixados do GitHub, sha256 idêntico):
  - `psx_visuals_gd4-cfe115f.zip` = https://github.com/scolastico/psx_visuals_gd4/archive/cfe115fa419f2169fde1b720091a9231273efdea.zip, commit "release version 2.1.3" de 25/01/2026, sha256 `21edc1ff7223a02a42addb971f22e02866c5bcbef896540aa288d6e84270b87a`. **Usado.**
  - `psx_visuals_gd4-9668c20.zip` = archive do commit 9668c203f25f559ac36b6d0e468f4ed446ca4eee ("updated readme", 13/04/2026, o mais novo), sha256 `897597715958227f9efe41479712b38e0725032198d284e4ba79b2fc695e5652`. Os shaders são byte a byte iguais aos da 2.1.3; só o `plugin.cfg` muda (versão "IN-DEV") e faltam LICENSE e README dentro de `addons`. Por isso foi usada a 2.1.3, que traz a licença ao lado.
- Copiados (de `addons/psx_visuals_gd4/`): `LICENSE`, `shaders/psx.gdshaderinc`, `psx_opaque.gdshader`, `psx_opaque_double.gdshader`, `psx_transparent.gdshader`, `psx_transparent_double.gdshader`, `psx_postprocess.gdshader`.
- Alteração: só o `#include "res://addons/psx_visuals_gd4/shaders/psx.gdshaderinc"` virou `#include "psx.gdshaderinc"` (pasta achatada).
- Não copiados de propósito: `Plugin.gd`, `Psx.gd`, `AutoApply.gd`, `AutoLoad.gd` (gravam `ProjectSettings` e instalam autoload; o contrato proíbe). O `modulo.gd` faz o que o `AutoApply.gd` faz (textura e cor do StandardMaterial3D) e cria os uniformes globais em tempo de execução com os valores padrão do `Psx.gd`.
