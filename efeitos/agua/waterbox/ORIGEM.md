# Origem: godot-waterbox

- Repositório oficial: https://github.com/Adisoreq/godot-waterbox (autor Adisoreq), licença MIT (`LICENSE` ao lado).
- Arquivo baixado: `baixados/godot-waterbox/godot-waterbox-main.zip`, 27.018 bytes, sha256 `a5bdd4c21441f6170471e130f7ce3f0888b831aee914bc056df78ce664ba4015`.
- Conferência (20/11/2026): baixei de novo `https://github.com/Adisoreq/godot-waterbox/archive/refs/heads/main.zip`, mesmo sha256 [medido].
- Popularidade (API do GitHub, lida em 20/11/2026): 6 estrelas, último push 11/07/2026.
- Copiado: `addons/waterbox/assets/shaders/water.gdshader` -> `water.gdshader` (sha256 `912069479a094417fc9554533396ad0dc0a8ad5eefb7ec46fb64c08b25777eb9`, sem alteração), `LICENSE`.
- Não copiado: `plugin.cfg`, `water_box.gd`, `buoyancy_component.gd`, prefabs. O addon é empuxo e arrasto de `RigidBody3D` dentro de uma `Area3D` (lido em `water_box.gd`); os bonecos da sala são esqueletos animados, não corpos rígidos, então essa parte não se aplica.
