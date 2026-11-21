# Visual PS1 na sala do Vagrant (Godot 4.7.2) — resultado

Agente C, 20/11/2026. Contrato: `CONTRATO-MODULOS.md` versão 1. Grupo `visual-ps1`, exclusivos entre si (um por vez no menu).

## Resumo

- **Os 5 pacotes funcionam no 4.7.2**: zero linha de erro no log das 15 rodadas de medição dos candidatos e dos 15 prints finais, e ligam, desligam e ligam de novo limpos [medido: `errosNoLog` em `medicao-padrao.json`; teste de ciclo com 183 superfícies da sala trocadas e devolvidas, 2 voltas por pacote].
- **Custo: pequeno.** De 0,01 a 0,10 ms por quadro a mais que a base (1,27 ms), da mesma ordem da variação de uma rodada para outra do mesmo candidato (até 0,1 ms) [medido: 18 rodadas, todas com a placa em 5% ou menos].
- **Nenhum deixa a cena mais parecida com a página Three, e a base continua a mais parecida.** A página não tem nenhum traço PS1: nada de vértice preso à grade nem textura afim no `sala-fechada.html` [medido: busca por `snap|affine` só acha uma palavra num comentário sem relação]. O que a sala do Three tem de "antigo" é a luz por vértice (`MeshLambertMaterial` do three r117) com cor de vértice (`vertexColors: true`, linha 471). Os pacotes trazem isso, mas junto vêm a textura que entorta no chão, os pixels grandes ou a cor lavada, que a página não tem.
- **Veredito: não usar nenhum como padrão.** Como opção estética no menu, o mais limpo é o **PSX Look Free** (mantém a sombra do sol e a névoa da cena; o chão perto da câmera entorta). A licença dele (CC BY 4.0) pede crédito ao autor.

## Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade (lida em 20/11/2026) | Funciona no 4.7.2? | fps e custo vs base (mediana de 3) | Semelhança 0-5 | Usar? Por quê |
|---|---|---|---|---|---|---|---|---|
| Visual PS1 | base (etapa 1, sem efeito) | — | — | — | sim | 789,7 fps; 1,27 ms (rodadas de 784 a 800 fps) [medido] | 3 | referência |
| Visual PS1 | PSX Visuals GD4 2.1.3 | https://github.com/scolastico/psx_visuals_gd4 | MIT | 17 estrelas, 1 fork, último commit 13/04/2026 [medido: API do GitHub] | sim, 0 erro [medido] | 760,3 fps; 1,32 ms; +0,05 ms [medido] | 1 | Não, o pior dos cinco. Na luz clara a sala fica lavada e amarelada: o shader lê a textura sem `source_color`, então a cor sai mais clara do que é [medido: imagem; causa por leitura do código, dedução]. Na vista rio o chão estoura em branco. |
| Visual PS1 | Ultimate Retro Shader Collection 1.5 | https://github.com/Zorochase/ultimate-retro-shader-collection | MIT | 344 estrelas, 14 forks, release 1.5 em 30/08/2026 com 96 downloads; a 1.4.0 tem 3.719 [medido: API do GitHub] | sim, 0 erro [medido] | 732,8 fps; 1,36 ms; +0,09 ms [medido] | 2 | Não. Chão perto da câmera entorta em faixas diagonais (textura afim em quadrados grandes); a poça de luz da tocha vira uma mancha quadrada (luz por vértice no chão de quadrados grandes) [medido: imagem]. |
| Visual PS1 | Godot PSX Style Demo | https://github.com/MenacingMecha/godot-psx-style-demo | MIT | 744 estrelas, 40 forks, último commit 14/09/2023 [medido: API do GitHub] | sim, 0 erro [medido] | 731,0 fps; 1,37 ms; +0,10 ms [medido] | 2 | Não. Mesmo chão entortado e poça quadrada do URSC; pontilhado de 15 níveis fino demais na resolução cheia (foi feito para 320x240) [medido: imagem; documentação: README do demo]. |
| Visual PS1 | PSX Look Free 1.0.1 | https://godotengine.org/asset-library/asset/5493 | CC BY 4.0 (pede crédito) | 1 estrela no GitHub, avaliação 0 na Asset Library, atualizado 29/09/2026 [medido: API] | sim, 0 erro [medido] | 781,0 fps; 1,28 ms; +0,01 ms [medido] | 2 | Só como opção estética. Escuro igual à base e mantém a sombra do sol no rio; o chão perto da câmera entorta. A versão grátis não tem efeito de tela [medido: imagem]. |
| Visual PS1 | PSX Godot Shader 1.0.0 (fcidade) | https://store.godotengine.org/asset/fcidade/psx-godot-shader/ | CC0 | 1 avaliação positiva na loja, sem contagem de downloads, sem repositório; o autor marca a versão como instável [medido: página da loja] | sim, 0 erro [medido] | 773,3 fps; 1,29 ms; +0,02 ms [medido] | 2 | Não. O mais "PS1" de todos (pixels de 3x3, 15 bits com pontilhado visível, textura afim com limite, então o chão quase não entorta), mas granulado e longe da página nítida [medido: imagem]. |

- Custo = ms mediano do candidato menos o ms mediano da base da mesma execução [medido: `medicao-padrao.json`, 20/11/2026 22:27].
- Método: `medir.mjs` do integrador, vista padrão, 1280x720 fora da tela, vsync desligado, 2 s + 10 s, 3 rodadas intercaladas com a base. Placa em 5% ou menos antes de todas as 18 rodadas (0 `foraDoMetodo`), 0 erro no log, já com a névoa de fábrica de cada pacote (a configuração final dos módulos) [medido]. Uma medição anterior, com a placa ocupada por outro programa, foi descartada.
- Semelhança: comparada com `godot-vagrant\print-three.png` (escuro) e `godot-vagrant\diag-claro-three-padrao.png` (luz clara), na mesma câmera. Esta régua julga a sala inteira; a base leva 3 [dedução, olhando as imagens].

## O que vi nas imagens [medido: PNG em `imagens/`]

Grades para conferir: `imagens/grade-clareada-8x-padrao.png` (escuro, clareado 8x), `imagens/grade-padrao-claro.png` (luz clara), `imagens/grade-clareada-4x-rio.png` (vista rio, clareada 4x).

- **Three, escuro**: só a poça de luz da tocha no chão à direita e os dois bonecos de costas; o resto preto. **Three, claro**: paredes e chão com sombreado suave por vértice (cantos escuros), fumaça azulada no chão.
- **Base**: escuro igual ao Three; claro sem o sombreado de vértice, textura mais dura.
- **PSX Visuals GD4**: escuro perto da base, poça de luz mais forte e amarela. Claro: tudo lavado e amarelado. Rio: chão estourado em branco, sem sombra do sol.
- **URSC 1.5** e **PSX Style Demo**: escuro com a poça de luz em mancha quadrada e o chão em faixas diagonais (textura afim). Claro: chão perto da câmera muito entortado, paredes boas. Rio: sem sombra do sol (os shaders têm `shadows_disabled`).
- **PSX Look Free**: escuro perto da base com o chão em faixas; claro com o mesmo chão entortado; rio com a sombra do sol, o único dos cinco.
- **fcidade**: pixels grandes e pontilhado por toda a tela, chão quase sem entortar; rio sem sombra do sol.

## Como cada um foi ligado (o que o `modulo.gd` faz)

- Troca só as superfícies da sala com luz (`cena.sala`), por `set_surface_override_material`, nunca o recurso importado; superfície já trocada por outro módulo (a água, por exemplo) fica como está; os bonecos ficam para o grupo `personagem`. Código comum: `comum/troca.gd`.
- Escolhe a variante por superfície lendo o material original: opaca, opaca de dois lados, transparente, transparente de dois lados [medido: 193 superfícies; 73 opacas de dois lados e 30 transparentes; 10 sem luz ficam como estão].
- **Cor de vértice ligada em todos**: 119 das 193 superfícies têm cor de vértice e o Three usa; a base da etapa 1 não usa [medido: inspeção do `sala.glb`; documentação: `sala-fechada.html` linha 471].
- Uniformes globais (PSX Visuals, URSC, demo) criados em tempo de execução por `RenderingServer.global_shader_parameter_add` antes de carregar o shader e removidos no `desligar`, sem tocar no `project.godot` [medido: teste de ciclo sem erro]. Não usa `global_shader_parameter_get_list()`, que é só do editor e dá erro em jogo [medido: a primeira versão deu esse erro no log].
- Valores nos padrões de cada pacote, com névoa de fábrica (desligada nos três que têm névoa própria; Look Free e demo usam a da cena). Exceção: `cull_distance` = 0 no URSC (o padrão 64 corta a sala ao longe).
- Pós-processo de tela: `ColorRect` numa `CanvasLayer` de camada 0 (o menu fica por cima, na 1) [medido: aparece no PNG]. URSC e demo liam `TEXTURE` de um SubViewportContainer; troquei por `hint_screen_texture` (anotado no `ORIGEM.md`). O URSC não traz a textura do pontilhado: uso uma matriz de Bayer 4x4 gerada no código.

## Limites e dúvidas

- PSX Visuals, URSC e fcidade têm `fog_disabled`: com eles a sala fica sem névoa nenhuma. Na vista rio isso não chegou a aparecer, mas numa vista mais longa deve aparecer [documentação: `render_mode` de cada shader; dedução para a vista longa].
- PSX Visuals, URSC, demo e fcidade têm `shadows_disabled`: a sala perde todas as sombras (sol e tochas). O PSX Look Free não desliga sombra, e no print do rio a sombra do sol aparece; se as sombras das tochas também aparecem com a luz por vértice não conferi [documentação: `render_mode` de cada shader; medido: `psx-look-free-rio.png`].
- **URSC 1.4.0 x 1.5**: comparei os zips arquivo a arquivo. No que o lab usa, a 1.5 só reorganiza o código (funções movidas para `utilities.gdshaderinc`, `convert_vertex_colors` renomeado para `srgb_vertex_colors`, formatação) e corrige um defeito: na 1.4.0 o `standard_transparent_repeating` não tinha `#define TEXTURE_REPEAT`, então a textura transparente não se repetia. Por isso testei só a 1.5; a 1.4.0 daria a mesma imagem, menos nas superfícies transparentes [medido: diff dos zips oficiais; dedução para a imagem].
- **PSX Visuals 2.1.3 é a mais nova**: o commit mais recente do repositório (9668c20, 13/04/2026) tem os shaders idênticos aos da 2.1.3 (cfe115f, 25/01/2026), que é a versão que a Asset Library aponta e que traz a licença [medido: diff dos dois zips em `baixados\psx_visuals_gd4\`].
- O demo e o PSX Look Free foram feitos para rodar numa imagem pequena (320x240) ampliada; o contrato não deixa trocar a resolução, então aqui rodam na resolução cheia [documentação: README de cada um].
- Ajuste fino (força da textura afim, encaixe de vértice, bits de cor) poderia aproximar, mas não tiraria a textura afim e o tremor, que a página não tem [dedução].
- Os zips do PSX Look Free e do fcidade não estão em `baixados\` (fora da minha pasta): ficaram no scratchpad da sessão; URL e sha256 em cada `ORIGEM.md`.
