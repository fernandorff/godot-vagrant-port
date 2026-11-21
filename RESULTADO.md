# Port da sala-fechada para o Godot 4.7.2: diário por etapa

Projeto: esta pasta (cópia de `godot-vagrant`, etapa 1). Fonte só leitura: `dungeon-tactics-labs/web/public/content/vagrant/sala-fechada.html` (three r117).
Prints: `node print-three.mjs braseiro nome=query ...` no Three; Godot com `--rapido --png=arq.png --olhar=29,1,10` (mesma câmera). Medição: `medir-etapa2.sh` (trava de godot-candidatos, janela fora da tela por `esconder-janela.ps1`).

## Etapa 2: tochas, sombras e PCSS (20/11/2026)

O que entrou (vagrant.gd):
- Uma OmniLight3D por tocha acesa, tremor igual (sala-fechada.html:655), chama e halo aditivos (QuadMesh billboard, sem luz e sem névoa).
- Sombra só nas 2 tochas mais perto da Ashley, igual ao Three (conferido 20/11: as duas são (29; 2,95; 13) e (3; 5,4; 14,75) nos dois motores).
- Modos: sem, dura (atlas 1024 = casas de 128 px, filtro HARD), suave (atlas 4096 = 512 px, SOFT_HIGH), PCSS por `light_size` 0,4. Menu F1 troca na hora.
- Menu F1 também liga SSAO (etapa 3, calibração pendente).

Correções de fidelidade achadas nesta etapa (valem para todas as próximas):
- **Espaço de cor igual ao Three r117** (`cor_three`, padrão ligado; `--cor=godot` desliga): o r117 não converte sRGB (textura, cor e saída em valor bruto). No Godot: texturas recodificadas com `linear_to_srgb` na carga, cores com `Color.linear_to_srgb()`, e uma LUT de correção de cor que desfaz a codificação da saída. Prova (medida 20/11): o brilho passou a crescer linear com a energia (0,35 → 1,0 deu 18,1 → 51,9, razão 2,87 para 2,86), e o halo, que estava grande demais, ficou igual ao do Three.
- **Cor por vértice da sala ligada**: o Three usa `vertexColors: true` (sala-fechada.html:471; valores de 0,5 a 0,9) e o Godot ignorava (medido: `vertex_color_use_as_albedo=false` no import). Erro que vinha da etapa 1.
- **Queda da luz**: o r117 usa `(1-d/alcance)^2` e o Godot usa `d^-a` com janela. O ajuste numérico deu a = 0,35, e as imagens deram a = 0,9 com energia 1,15 (chão perto do braseiro 28,0 no Three e 28,0 no Godot; pilar 26,8 e 25,7; chão longe 2,3 e 3,8). A luz longe ainda sobra um pouco no Godot.
- Lambert em luz por vértice e sem brilho (como o r117). Não mudou nada que dê para medir, porque o chão já é muito dividido (4.400 triângulos).

Diferenças que ficam:
- No Three há uma faixa escura à direita do pé do braseiro; no Godot não. Causa não achada (o braseiro não projeta sombra em nenhum dos dois; Gouraud não explica).
- Sombra dura do Three escurece mais o chão inteiro (mapa de 128 com acne, dedução); no Godot a dura fica parecida com a suave.

Prints: `lado-4modos.png` (linhas: sem, dura, suave, PCSS; Three à esquerda), `zoom-suave.png`.

fps (medido 20/11, 1280x720, vista padrão, 3 rodadas, mediana; **fora do método**: GPU a 59% antes das rodadas, com os subagentes de plugins usando a placa, e oscilação de até 40% entre rodadas; refazer quando a placa estiver livre):

| Modo | Godot | Three (Chrome) |
|---|---|---|
| sem sombra | 569 | 477 |
| dura | 538 | 254 |
| suave | 557 | 227 |
| suave + PCSS | 533 | 224 (2 rodadas; a 3ª abortou por GPU ocupada) |

Dados: `medicoes/godot-*.json`, `medicoes/three-etapa2.json`. Com sombra, o Godot ficou cerca de 2,1 a 2,4 vezes o Three; sem sombra, 1,2 vez.

## Entradas dos subagentes de plugins (para as etapas seguintes)
- Fumaça (etapa 7): o melhor candidato é `godot-candidatos/efeitos/fumaca/fogvolume-ruido` (FogVolume com ruído, porte do fumaca.js), nota 3 de 5. Conferido no print de 20/11: vira uma névoa roxa no chão e não a coluna fina laranja do Three, então serve só como ponto de partida. LightmapGI não assa pelo terminal no 4.7.2 (não existe `bake()` no script) e a sala não tem UV2: para a etapa 4, o caminho é portar o `assa()` do Three (luz por vértice, CPU) em vez do LightmapGI.

## Etapa 3: SSAO (20/11/2026)
- SSAO nativo do Godot no lugar dos 2 passes da página (sala-fechada.html:774/793): raio 1,2 (o RAIO da página), `ssao_light_affect` 1 (a página multiplica a imagem pronta; com escuridão total só existe luz direta), força 16.
- Calibração pelo brilho médio da vista do braseiro: o Three escurece 4,9% e o Godot 5,1% com força 16 (com 1, 2, 4 e 8: 0,4%, 1,0%, 1,9% e 3,3%). Visualmente as duas versões escurecem o pé das colunas e das paredes (`lado-ssao.png`: Three em cima, Godot embaixo, sem e com).
- Não portado: o Three apaga o SSAO com a névoa e poupa pixels claros (chamas). No Godot as chamas são transparentes e o SSAO não as pega; o desbotamento com a distância não existe.

## Etapa 4: luz assada (20/11/2026)
- `luz_assada.gd`: porte do `assa()`/`lmCompoe()` (sala-fechada.html:812-889). São 13 raios de abertura e 4 raios de visão por fogo a menos de 16 tiles, com K 0,16 e cor do fogo (1; 0,62; 0,3), na escuridão total (sem o azul do ambiente).
- O resultado vai num atributo por vértice (CUSTOM0) e num shader que soma `EMISSION = ALBEDO * lm`, o mesmo efeito do indireto do Lambert. O shader só entra com a luz assada ligada; desligada, o material original volta.
- Diferença de método: o Three anda na grade da planta (arcos não tapam); aqui os raios batem na malha real (colisão temporária da sala).
- Medido: 10.123 pontos em 1.209 ms. No Three foram 11.515 pontos em cerca de 326 ms; a página dedup outro conjunto de malhas.
- **Comparação vértice a vértice (20/11):** os 46.536 vértices do Godot casaram por posição com os do Three (que tem 52.608).
  - Correlação 0,92. Média: Three 0,051, Godot 0,060 (+19%).
  - Onde o Three dá menos de 0,02 (cantos escuros), o Godot dá 1,87 vez mais; de 0,02 a 0,1, 1,24 vez; de 0,1 a 0,3, 1,06 vez.
  - Conclusão: a conta está certa onde há luz. O Godot tapa menos nos cantos, porque a página trata a rocha como volume sólido na grade e aqui o raio só bate em superfície. **Não está igual.** Correção possível: colisão também da rocha e do teto, ou portar a grade (`solido()`) com a planta exportada.
- Clareamento ao ligar (brilho médio): na vista do braseiro, Three +2,5% e Godot +10,6%; na vista padrão, Three +44,6% e Godot +22,8%. A ordem de grandeza bate, mas a distribuição difere, provavelmente pelo método de oclusão (dedução). Print: `lado-lm.png`.

## Etapa 5: bonecos (20/11/2026)
- `boneco.gdshader` nas peças texturizadas dos bonecos. Ele faz o modo padrão da página (`bonecos=some`, `some=abraca`; sala-fechada.html:1030-1105):
  - luz direta com piso de 0,2 e meia Lambert;
  - a mesma queda da página (j² × 16/(d²+16));
  - do Godot só a sombra (a ATTENUATION dividida pela queda que o Godot aplicaria; a tocha é achada pela direção da luz).
- Some no escuro: descarta o pixel quando a luz direta estimada fica abaixo de 0,05, com o mesmo ruído fino (`fino()`) da página. A estimativa para o descarte não conhece sombra, então um boneco atrás de uma coluna fica preto em vez de sumir (diferença).
- A mancha sob cada boneco some junto (opacidade 0,5 × min(1, luz/0,05), sala-fechada.html:1657).
- Menu F1: "Bonecos somem fora da luz". `--some=0` desliga.
- Não portado: normais suavizadas por osso (`normais()` da página); o Godot usa as normais do GLB.
- Print: `zoom-bonecos.png` (Three à esquerda). O brilho ficou parecido; a câmera padrão do Three ficou um pouco diferente da exportada.

## Etapa 6: chamas, halos, brasas e poeira (20/11/2026)
- Chamas e halos já vinham da etapa 2.
- Brasas: um CPUParticles3D por tocha acesa, com 10 brasas, vida de 0,8 a 2,4 s, subida de 0,7 a 1,5 e lateral ±0,2, cor (1; 0,45; 0,12) apagando até o preto, em modo aditivo (sala-fechada.html:981-989).
- Poeira: 350 grãos num MultiMesh, tingidos uma vez pelas tochas perto (k = Σ força × queda, até 1,2), com o mesmo balanço da página.
  - shortcut: sorteia vértices de chão e de 0,3 a 4,0 de altura, porque a planta (células e teto) não está no cena.json.
- O tamanho do ponto foi convertido de pixels para o mundo: ×0,466, que é tan(25°) com o fov 50.
- Menu F1: "Brasas e poeira". Print: `zoom-part.png`.
- A brasa carregada na mão (tecla T da página) fica para a etapa 9 (controles).

## Etapa 7: fumaça volumétrica (20/11/2026)
- `fumaca.gdshader`: porte linha a linha do `fumaca.js`, com caixa, ruído 3D de uma leitura, fbm de 3 oitavas, plumas sobre 6 fontes, erosão, 6 luzes com Henyey-Greenstein, 32 passos e ruído de tela fixo.
  - Os parâmetros foram lidos da página em execução (`export/fumaca.json`): caixa de (0,0,0) a (44,10,88), cor (0,75; 0,82; 1), densidade 1,2, altura 1, cobertura 0,8 e as 6 fontes com força × 3.
  - Desenho: um quadro de tela inteira, alfa pré-multiplicado, que para na profundidade da cena.
- Diferenças: resolução cheia sem o borrão 3x3 (a página borra para esconder o ruído); as 6 luzes são as 6 tochas mais perto da Ashley.
- Print `lado-fumaca.png` (Three à esquerda, vista do braseiro): a coluna sobre o braseiro e a névoa baixa ficaram praticamente iguais. No Godot a pluma está um pouco mais clara.
- Correção no `print-three.mjs`: a câmera agora é forçada em `updateMatrixWorld`. Antes, a fumaça do Three era calculada com a câmera padrão. **Os prints `three-*.png` da vista do braseiro feitos antes disso (etapas 2 a 6) têm a fumaça na posição errada.** A calibração de brilho daquelas etapas usou essas imagens; refazer a conferência no fim.

## Etapa 9, parte 1: câmera de órbita e paredes que somem (20/11/2026)
- Câmera: órbita da página em volta da Ashley (az 0, polar 1,3, distância 11,7). Arrastar com o botão esquerdo gira, a roda aproxima, com limites de 0,6 a 1,5 rad e de 6 a 44 tiles. A névoa se afasta com a distância e o alvo segue o herói com lerp ×6 (sala-fechada.html:1312-1333 e 1696).
- Paredes que somem: `exportar-paredes.mjs` grava `export/paredes.json`. São as 99 paredes da página com o nó do GLB, achado refazendo a mesma numeração do export; deu 220 nós, igual ao cena.json. O teste é o da página: câmera do lado de fora, ou parede cortando uma das 9 linhas do corpo até a câmera, com transição de 0,25 s. O apagar usa a transparência por instância do Godot, que vale com qualquer material, inclusive o da luz assada.
- **Conferido**: em 5 ângulos (az 0; 0,8; 1,5; 3,14; −1,5), o conjunto de paredes apagadas é idêntico ao do Three (26, 27, 36, 35 e 39 paredes; nenhuma diferença). Dados: `apagadas-three.json` e `apagadas-godot.txt`.
- `--orbita=az,dist,polar` põe a câmera numa órbita (como o `window.sala.gira`).
- Falta (etapa 9, parte 2): escolher e andar (caminho na grade), animações além do "parado" (o export só levou esse clipe), pulo (`pulo-vs.js`), tocha na mão (tecla T), degraus e o restante dos controles.

## Etapa 9, parte 2: escolher, andar, teclado e pulo (20/11/2026)
- `exportar-bonecos.mjs` reexporta `export/bonecos.glb` com todos os clipes dos gestos (parado, andar, correr, golpe, magia) e as 5 poses do pulo nas 3 saídas (parado, andando, correndo). Também grava `export/grade.json`: a planta de 92 x 44 casas, os passos permitidos com o custo de cada um, a altura `seco()` e o `bloqueia()` amostrados a cada 0,25 tile, e 4 rotas da própria página. A cópia anterior ficou em `export-antes-etapa9/`. Depois de reexportar, rodar `godot --headless --path . --import`.
- `grade.gd`: `caminho()` da página, com a mesma fila ordenada (custos iguais na ordem de chegada), `seco()`, `bloqueia()` e `livre()`. **Conferido: as 4 rotas saíram idênticas às da página.**
- `vagrant.gd` (sala-fechada.html:1184-1205, 1395-1403, 1476-1555, 1672-1690):
  - Um clique num boneco escolhe; um clique no chão leva o escolhido até a casa. Arrastar mais de 6 px gira a câmera.
  - Q e E trocam o escolhido. WASD e as setas andam em relação à câmera; Shift corre; Espaço pula.
  - Peso "pesado": aceleração em duas etapas, giro de até 270°/s, freio de 0,85 nas curvas fechadas e 0,25 da velocidade enquanto dura o pouso.
  - Gestos em fila: as duas metades do andar alternam; golpe e magia voltam ao que ele fazia. O tempo da mistura é o de `trocaDe()`.
  - O pulo tem agachar, impulso, topo, queda e pouso, com as misturas do jogo em quadros de 1/30 s. Quem sai de uma borda cai.
  - A câmera segue o escolhido.
- Conferências com a página (medido 20/11, Three com passo fixo de 1/60 s):

| Teste | Página | Godot |
|---|---|---|
| Rota de 34 casas, da Ashley até o esqueleto | 23,17 s, chega em (19; 0; 63) virada a 0 | 22,78 s, chega em (19; 0; 63) virada a 0 |
| Pulo parado | altura 1,239, fim do pouso em 1,62 s | altura 1,287, fim em 1,54 s, fases agacha → impulso → topo → queda → pouso → parado |
| Segurar S por 2 s e soltar | andou (−0,26; 4,07), parou em (18,74; 11,56) | andou (−0,29; 4,14), parou em (18,71; 11,67) |

- A diferença vem do passo de tempo: o Godot roda a cerca de 250 fps e chega mais perto da conta exata (1,3 de altura e 1,60 s).
- Print no meio do passo (`andando.png`) e parado perto do braseiro (`andar.png`, com `--some=0`): pose inteira, sem boneco desmontado.
- Atalhos marcados no código (`shortcut:`):
  - O Godot mistura as animações em linha reta; a página usa curva S.
  - A altura vem interpolada da amostra de 0,25 tile.
  - O clique em boneco usa um cilindro de raio 0,8 no lugar da caixa da página.
  - A água fica de fora (etapa 8).
- Testes pela linha de comando: `--andar=cx,cz`, `--png-andando=arq`, `--pular` e `--segurar=W,segundos`.
- Falta:
  - golpe (K), fogo (F) e raio (R), com os clarões;
  - tocha na mão (T);
  - tocha fixa e porta (E);
  - controle de videogame;
  - tecla P (peso);
  - integrar os módulos dos subagentes no menu.

## Etapa 9, parte 3: golpe, fogo, raio e tocha na mão (20/11/2026)
- Fontes de luz como na página: cada uma tem cor e alcance próprios, e a cada quadro as 2 que fazem sombra são a tocha na mão do escolhido e as tochas mais perto do alvo da câmera. O shader dos bonecos e a fumaça leem a mesma lista.
- K (golpe), F (fogo) e R (raio): o gesto mais o clarão (0,35 s e 0,9 s depois; queda ao quadrado; o raio pisca 3 vezes). Volta ao parado: golpe em 1,55 s (página 1,53) e magia em 3,86 s (página 3,77). As durações dos clipes agora vêm do Three, porque o glTF corta na última chave.
- T (tocha na mão): `segura.gd` é um modificador de esqueleto que gira o ombro até a mão apontar à frente do peito. A tocha (cabo e copo, sem sombra) fica em pé no punho, com chama, 6 brasas e luz de alcance 11; o escudo some enquanto ela está acesa. **Posição da chama nos 8 bonecos: até 0,05 tile da página.** Print lado a lado: `tocha/lado-tocha.png`; brilho médio 5,0 no Three e 6,2 no Godot.
- Diferenças:
  - a frente da Ashley sai mais escura no Godot;
  - com a tocha acesa o contador caiu para cerca de 55 fps (2 sombras de ponto móveis); falta medir pelo método.
- Testes: `--acao=golpe|fogo|raio` e `--tocha`.
- Falta: tocha fixa e porta (E), controle de videogame, tecla P, e integrar no menu os módulos dos subagentes.

## Arrumação pelo padrão das skills de Godot (20/11/2026)
- Bonecos, tochas e clarões deixaram de ser Dictionary soltos e viraram classes com tipo:
  - `Unidade` (`unidade.gd`): gestos, peso, rota, teclado e pulo;
  - `Fonte` (`fonte.gd`): tocha fixa, clarão e tocha na mão;
  - `Grade` (`grade.gd`);
  - `Segura` (`segura.gd`).
- Os números soltos viraram constantes com nome.
- O nó `Bonecos` (`bonecos.gd`) cuida da escolha, do clique, do teclado, do golpe e das magias. Ele pede os clarões à cena pelo sinal `clarao_pedido` (o sinal sobe, a chamada desce). Roda antes da câmera (`process_priority` −1), como o `quadro()` da página.
- O `vagrant.gd` caiu de 1.331 para 1.030 linhas; os testes da linha de comando estão em `_testes()`.
- **Conferido depois da mudança, com os mesmos números de antes:**
  - rotas 4 de 4 iguais;
  - andar 22,86 s;
  - segurar S: 4,16;
  - pulo: altura 1,285;
  - golpe 1,57 s e magia 3,84 s;
  - chama da tocha idêntica nos 8 bonecos;
  - print padrão com luz assada sem erro.
- Câmera, luzes e menu viraram nós próprios (20/11):
  - `CameraOrbita` (`camera_orbita.gd`): órbita, névoa que se afasta e paredes que somem;
  - `Luzes` (`luzes.gd`): tochas, sol, céu, clarões, tocha na mão, brasas, poeira e fumaça; a cena passa a configuração para baixo e o pedido de clarão dos bonecos chega por sinal;
  - `MenuOpcoes` (`menu_opcoes.gd`): avisa a cena pelo sinal `opcao_mudou`.
- O `vagrant.gd` ficou com 524 linhas (sala, ambiente, bonecos, luz assada, testes e medição).
- **Conferido depois da separação das luzes (medido 20/11):** menu com 21 trocas e 2 luzes com sombra; magia 3,86 s; segurar S 4,14; pulo 1,287; print com luz assada de brilho igual ao de antes (1,232 contra 1,234).

## Noite de 20 para 21/11/2026: módulos no menu, tocha fixa, porta, peso, controle e rio

Origem: **[medido]** = rodado nesta noite; **[dedução]** = não provado.

- **Módulos dos candidatos no menu F1** (`efeitos.gd`, pasta `efeitos/` copiada de `godot-candidatos`):
  - o nó `Efeitos` é a "cena" do contrato (`CONTRATO-MODULOS.md`, seção 3); cada grupo vira uma escolha no menu e os não exclusivos viram caixas;
  - `--efeitos-teste`: os 24 módulos ligam e desligam 2 vezes pelo menu, sem sobrar nó **[medido]**;
  - `--efeitos=a,b` liga na abertura; `--vista=braseiro|bonecos` usa as câmeras dos candidatos;
  - prints com a cor corrigida em `imagens-efeitos/` (base e recomendados: chamas nativas, PCSS, água nativa, personagem próprio).
  - Atenção: apagar os `.import` da pasta quebra a luz assada do `lightmapgi` (a textura dela é importada em camadas); eles foram mantidos.
- **Tocha fixa (E perto, a até 2 tiles):** as 18 tochas e braseiros nascem todos, acesos ou não; apagada = sem chama, halo, brasas, luz nem sombra. `--fixa`: apaga e acende **[medido]**.
  - shortcut: a poeira é tingida só na abertura, e a luz assada não refaz a parte de cada tocha.
- **Porta (E perto, a até 3,2 tiles)** (`portas.gd`): abre em 0,7 s; aberta de todo, o boneco sai na outra casa (fora em x 92, dentro em x 164), de costas para a porta, e a câmera vai junto.
  - Só um lugar aparece por vez; lá dentro, telhado e oitões somem e cada parede some quando a câmera está do lado de fora dela.
  - `--porta`: atravessa e volta **[medido]**.
  - O feixe de sol da janela voltou a ser aditivo (o glTF tinha perdido isso).
- **Tecla P (peso):** leve → médio → pesado, com aviso na tela. Segurar S por 2 s anda 5,88 (leve) e 4,15 (pesado) **[medido]**.
- **Controle de videogame** (mapa da página): analógico esquerdo anda; direito gira a câmera; direcional cima e baixo aproxima e afasta; A pula; X golpe; B fogo; LT raio; Y tocha; LB e RB trocam; RT segurado corre; RS apertado mexe na tocha fixa; Start abre o menu.
  - `--controle` (por eventos): o analógico anda 4,15, como o S; a câmera gira 1,1 rad em 0,5 s; A, X e RB funcionam **[medido]**.
  - Sem controle real conectado: falta testar com o controle de verdade.
  - 21/11, controle de Xbox virtual (ViGEmBus + `vgamepad`, script em Python) com `--controle-real`: o Godot viu "XInput Controller" e recebeu os 17 comandos (analógicos, RT, LT, A, X, B, Y, LB, RB, direcional cima e baixo, RS, Start duas vezes). No fim, o herói andou 4,54, a câmera girou −1,75 rad e o escolhido mudou de herói **[medido]**.
  - Falta o controle físico na mão: o virtual prova a leitura dos botões, não a sensação de jogo.
- **Rio (etapa 8)** (`rio.gd` + `rio.gdshader`): o shader do rio da página (cópia do módulo `agua/nativo`, com saída bruta).
  - Anéis nos pés dos 8 bonecos ao vivo; passo a 0,65 dentro d'água; o disco de sombra some na água.
  - `--rio`, 2 s com S dentro do rio: Godot 2,63 contra 2,65 na página **[medido]**; cor média da água igual (31,5/26,6/24,3 contra 33,4/27,5/25,4).
  - A planta mundo não tem poça nem fosso: o rio é a única água.
  - shortcut: sem as 160 gotas que saltam do pé.
- **Bonecos ao ar livre:** recebem sol (com a sombra real) e céu, como o `foraU` da página.
  - O quanto cada casa recebe vem de `export/letras.json` (`exportar-letras.mjs`).
  - Achado: passar `Color` para um uniform `vec3` converte a cor; agora vai como `Vector3`.
  - Corpo da Ashley no rio, cor média: Godot 52/31/20, página 64/40/29 **[medido]**.
    - Sem a sombra do sol, o Godot dá 69/41/25: a diferença está na sombra do sol sobre o corpo **[medido]**.
    - O viés da sombra (0,1 a 0,8) não muda nada. Só o corpo projetar, como na página, também não **[medido]**.
    - Causa (21/11): o Godot zera a sombra do sol nas faces de costas para o sol mesmo sem nada projetando (`--ver-sombra` com `--corpo-sem-sombra` deu o mesmo lado escuro); a página ali dá a meia luz. Correção em `boneco.gdshader`: de costas para o sol, a sombra do Godot é ignorada. Corpo agora 68,5/40,3/24,9 contra 66,7/41,2/29,5 da página, no mesmo recorte **[medido]**.
    - Causa ainda aberta.
- **Os "55 fps" com a tocha na mão:** medição de 10 s, 3 rodadas intercaladas, com o RustDesk ligado (fora do método).
  - Sem tocha: 314, 319 e 307 fps; com tocha: 294, 274 e 262 fps. A tocha custa ~0,45 ms por quadro **[medido]**.
  - As chamadas de sombra vão de 189 para 351: a sombra de ponto da tocha desenha 6 faces, cheias de bonecos perto **[medido]**.
  - Os 55 fps não se repetiram na medição. Provável origem: o rótulo de fps nos prints, que mostra os primeiros segundos (prints com "1 fps" e "85 fps") **[dedução]**.
- `vagrant.gd`: nós próprios para Luzes, Portas, Rio e Efeitos; testes `--porta`, `--fixa`, `--peso=`, `--controle`, `--rio`, `--efeitos-teste` e `--leva=1`.

## fps Three x Godot (21/11, mesma vista padrão, 1280x720, vsync desligado, 3 rodadas de 10 s, mediana)

| Motor | Rodadas | Mediana | 1% low (mediana) |
|---|---|---|---|
| Página (Chrome, three r117) | 313,5 · 314,4 · 325,1 | **314,4 fps** | 194,9 |
| Godot 4.7.2 (Forward+) | 268,6 · 274,0 · 286,2 | **274,0 fps** | 204,3 |

- Medido com o RustDesk ligado: a placa já estava em ~16% antes de cada rodada, então as duas medições ficam fora do método (trava de placa ≤ 5%) **[medido]**.
- O Godot fica ~13% abaixo na média, mas com o 1% low um pouco melhor (quedas menores) **[medido]**.
- Repetir com o RustDesk desconectado para o número final.
