# Origem: porte próprio de fumaca.js

- Não é de terceiros. `fumaca.gdshader` porta a função `densidade()` de
  `D:\Projetos\dungeon-tactics-labs\web\public\content\vagrant\fumaca.js` (projeto do próprio dono): camada rasteira,
  pluma por fogo aceso e erosão por ruído, com os mesmos números.
- Diferenças do original: ruído de valor por hash (o original lê uma textura 256x256 de números aleatórios); a luz das
  tochas não é somada no shader, quem soma é a névoa volumétrica do Godot (anisotropia 0,35 = o g do Henyey-Greenstein
  do original); vale para as 14 luzes, não só 6; plumas para todos os fogos acesos (14), não só 6.
- Caixa: x -2 a 46, y 0 a 11, z -2 a 92 (parte da sala perto da câmera).
