# Shader de personagem (luz que abraça e boneco que some) — resultado

Agente C, 20/11/2026. Contrato: `CONTRATO-MODULOS.md` versão 1. Grupo `personagem`, exclusivos entre si.
Referência: shader dos bonecos da `sala-fechada.html` (modo padrão "Some fora da luz" + "Luz que abraça", linhas 1030-1105 e 1262-1273), só leitura.

## Resumo

- **Recomendado: `abraca-proprio` (shader próprio, porte direto do Three).** É o mais parecido com a página nas duas vistas: bonecos acinzentados como no Three (não alaranjados como na base), os longe da tocha somem com o mesmo pontilhado fino, os perto ficam inteiros [medido: olhando os prints clareados 8x lado a lado].
- Falta nele o que o Three faz com sombra: no Three um boneco atrás de uma coluna em relação à tocha também some; aqui não, porque a luz é somada no próprio shader, sem ler o mapa de sombra do Godot [dedução pelo código; não houve caso assim nas vistas testadas].
- `abraca-sombra` resolve isso pela metade (a cor usa as luzes e sombras do Godot), mas fica com o tom laranja forte da base, longe do Three.
- Pronto da web: não achei shader publicado que junte meia luz de Lambert e sumiço por luz [medido: buscas em godotshaders.com e na web, 20/11/2026]. O mais próximo é o "Transparency Dither" (CC0), que só faz o pontilhado; com ele montei o modo "Boneco inteiro" do Three.
- O recurso nativo (Lambert Wrap) não some e quase não muda a imagem.

## Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade | Funciona no 4.7.2? | fps e custo vs base (vista bonecos, mediana de 3) | Semelhança 0-5 | Usar? Por quê |
|---|---|---|---|---|---|---|---|---|
| Personagem | base (etapa 1, sem efeito) | — | — | — | sim | 788,2 fps; 1,27 ms (rodadas de 787 a 828 fps) [medido] | 2 | referência |
| Personagem | abraca-proprio (shader próprio, porte do Three) | `abraca-proprio/` + `comum/abraca.gdshaderinc` | do projeto | — | sim, 0 erro [medido] | 775,0 fps; 1,29 ms; +0,02 ms [medido] | 4 | **Sim, como padrão.** Tom acinzentado e sumiço com pontilhado como no Three; não lê as sombras do Godot [medido: imagem; dedução pelo código para a sombra]. |
| Personagem | abraca-sombra (próprio, luz pelo `light()` do Godot) | `abraca-sombra/` | do projeto | — | sim, 0 erro [medido] | 782,6 fps; 1,28 ms; +0,01 ms [medido] | 3 | Não por ora. Some igual, mas a cor fica laranja e contrastada como a base [medido: imagem]. |
| Personagem | Lambert Wrap nativo do Godot | https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#enum-basematerial3d-diffusemode | MIT (o próprio Godot) | recurso da engine | sim, 0 erro [medido] | 804,5 fps; 1,24 ms; −0,03 ms [medido] | 2 | Não. Quase igual à base e nada some [medido: imagem]. |
| Personagem | Transparency Dither (jacob, godotshaders.com) | https://godotshaders.com/shader/transparency-dither/ (página salva, sha256 `5e3ebc3b…`, completo no `ORIGEM.md`) | CC0 [documentação: a página] | página do godotshaders, sem contagem pública confiável [medido: página] | sim, 0 erro [medido] | 797,8 fps; 1,25 ms; −0,02 ms [medido] | 3 | Só como modo alternativo ("Boneco inteiro" do Three): some o boneco todo de uma vez, cor da base [medido: imagem]. |

- Custo = ms mediano do candidato menos o da base na mesma execução (`medicao-bonecos.json`, 20/11/2026 22:32). Placa em 5% ou menos antes de todas as 15 rodadas, 0 erro no log. Os quatro ficam entre −0,03 e +0,02 ms: custo que não se distingue da base (a própria base variou de 787 a 828 fps entre rodadas, cerca de 0,06 ms) [medido]. Uma medição anterior, com a placa ocupada por outro programa, foi descartada.
- Método: `medir.mjs` do integrador, vista `bonecos`, 1280x720 fora da tela, vsync desligado, 3 rodadas intercaladas com a base, lock tomado pela ferramenta.

Semelhança: 0 = nada a ver, 5 = igual ao print do Three na mesma câmera (`imagens/three-bonecos.png`, feito com `ref-three.mjs`, e `godot-vagrant\print-three.png` na vista padrão). Esta régua julga só os bonecos, por isso a base leva 2 aqui e 3 no relatório da sala (`visual-ps1\RESULTADO.md`): a sala da base já é parecida, os bonecos não (laranja, sem sumiço) [dedução, olhando as imagens]. Grades para conferir: `imagens/grade-clareada-8x-bonecos.png` e `imagens/grade-clareada-8x-padrao.png`.

## O que vi nas imagens [medido: PNG em `imagens/`, comparados clareados 8x]

- **Three** (`three-bonecos.png`): bonecos em tons de cinza e bege; o da esquerda quase sumido, com pontilhado na cabeça; o da direita claro e inteiro, lados e costas visíveis.
- **Base** (`base-bonecos.png`): bonecos alaranjados com contraste forte (luz só do lado da tocha), nenhum some; os dois do fundo da vista padrão aparecem como silhuetas escuras.
- **abraca-proprio**: tom, brilho e sumiço muito próximos do Three; o da esquerda some aos poucos com pontilhado, o da direita aparece inteiro e acinzentado. Na vista padrão, os dois bonecos da esquerda somem como no Three. Na luz clara, os quatro aparecem inteiros com a textura.
- **abraca-sombra**: sumiço igual ao anterior, mas a cor vem das luzes do Godot: laranja e contrastada como a base.
- **lambert-wrap-nativo**: praticamente a base, com o lado escuro um pouco mais aberto; nada some.
- **dither-godotshaders**: o boneco inteiro fica pontilhado conforme a luz que chega a pés, peito e cabeça; cor da base (laranja).

## Como foi feito

- Troca só as superfícies dos bonecos com textura (17: corpo, arma e escudo; as 8 sem textura ficam; pela cor lisa e transparência devem ser os discos do chão [dedução]), por `set_surface_override_material`; devolve no `desligar` [medido: teste de ciclo, 2 voltas, 17 trocadas e 0 depois].
- Porte do Three (`comum/abraca.gdshaderinc`): para cada luz de ponto, `0,2 + 0,4·(N·L + 1)` (meia luz de Lambert com piso 0,2), queda `j²·16/(d²+16)` com `j = 1 − (d/alcance)²`, cor = cor × intensidade do Three (não a energia calibrada 0,35 da sala); o pixel some quando `smoothstep(0; 0,05; luz) ≤ ruído`, com o mesmo ruído de gradiente intercalado (`fino`) do Three.
- Normal suave do arquivo (o `bonecos.glb` já tem normais suaves: vértices repetidos sempre com a mesma normal) [medido: inspeção do GLB], virada para a câmera como no Three.
- Cor: textura × cor de vértice (o `diffuseColor` do VSTools, `src/VSTOOLS.js` linhas 189-198), sem névoa (o shader do Three não tem), e a conta feita em valores crus e convertida no fim, porque o Three r117 escreve o número direto na tela [documentação: `VSTOOLS.js`; dedução para a conversão].
- Luz clara (`--claro=1`): soma luz 1 no corpo todo, os bonecos aparecem inteiros.
- `dither-godotshaders`: alfa por boneco (`instance uniform`) = função `visto()` do Three (linhas 1137-1145), calculada uma vez no `ligar` (as luzes do Godot não piscam).
- Nativo: `StandardMaterial3D` duplicado com `diffuse_mode = Lambert Wrap`, rugosidade 1 e cor de vértice. O "distance fade" com pontilhado do Godot some pela distância da câmera, não pela falta de luz, então não serve para este efeito [documentação: https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#enum-basematerial3d-distancefademode].

## Limites e dúvidas

- `abraca-proprio` ignora as sombras das tochas (ver resumo). Para ter as duas coisas seria preciso ler o mapa de sombra do Godot no shader, o que a API de shader não expõe fora do `light()`; e `light()` não pode descartar pixel [documentação: https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/spatial_shader.html].
- Sombra projetada pelos bonecos: o descarte por ruído também vale na passada de sombra, então onde o boneco some a sombra dele deve sair furada; no Three o boneco sumido ainda projeta sombra inteira [dedução pelo código; não conferido em print].
- As luzes que o boneco carrega na mão (tecla T no Three) não existem nesta cena; os vetores aceitam 16 luzes e a cena tem 14.
- Prints: `imagens/<candidato>-{bonecos,padrao}[-claro].png`; base e Three na mesma pasta.
