# Água (poça, fosso e rio) no Godot 4.7.2: candidatos

Agente B, 20/11/2026. Origem de cada afirmação: **[medido]** = rodado nesta sessão; **[documentação: link]**; **[código]** = lido no arquivo; **[dedução]** = não provado.

## Resumo em 4 linhas

- **A cena exportada não tem poça nem fosso.** A planta é "mundo", e `planta-mundo.js` linha 153 diz `agua: { poca: [], fosso: [] }` [código]. A única água é o **rio** (nó `n184` do `sala.glb`, faixa de 6 tiles de largura, x 63,8 a 76,2, z 0 a 88, y 0,04 [medido na página Three]). Nenhum boneco está no rio (o mais perto, Esqueleto 2, fica em x 61, z 41; o rio passa em x ≈ 67 ali) [dedução pela fórmula `RIO` da linha 34].
- Para ver **boneco dentro d'água**, todos os candidatos criam uma **poça de demonstração** (12 x 5 tiles, y 0,05) sob os 4 bonecos parados (x 16 a 28, z 4,5 a 9,5). Ela não existe no Three; é só bancada.
- **Recomendado: `nativo`** (porte do shader do rio do Three + anéis nos pés). É o mais parecido com o Three (nota 4) e o único em que o boneco mexe a água de forma visível.
- Custo em fps: na rodada larga (3 rodadas, placa às vezes ocupada) nenhum candidato se separou do ruído. Medindo de novo só o `nativo` no rio, 5 rodadas, todas dentro do método: **+0,07 ms por quadro** (756,7 → 718,5 fps; por rodada +0,01 a +0,13 ms). Ver seção 3.

## 1. Tabela

| Efeito | Candidato | Origem/URL | Licença | Popularidade (lida em 20/11/2026) | Funciona no 4.7.2? | fps e custo vs base (mediana de 3; vista rio / vista bonecos) | Semelhança 0-5 | Boneco mexe a água? | Usar? Por quê |
|---|---|---|---|---|---|---|---|---|---|
| Água | **nativo** (porte do rio do Three + poça com anéis) | feito aqui a partir de `planta-mundo.js` linhas 338-374 e `respingos()` linhas 391-399 | do projeto | n/a | **Sim**, sem erro no log [medido] | **+0,07 ms** (rio, 5 rodadas: 756,7 → 718,5 fps) [medido]; na rodada larga: rio +0,23 ms, bonecos −0,02 ms, dentro do ruído | **4** no rio [medido: olhando `nativo-rio.png` x `three-rio.png`]; poça: sem nota (não há referência Three) | **Sim**: anel forte ao entrar, anel fraco a cada 1,3 s parado, como no Three; anéis visíveis nos pés em `nativo-bonecos-claro.png` [medido] | **Sim.** Mesma conta do Three, mais parecido, interage, só shader nativo |
| Água | **ssr-water** (GodotSSRWater) | https://github.com/marcelb/GodotSSRWater | MIT | 121 estrelas, último push 05/07/2026 [documentação: API do GitHub] | **Sim**, sem erro [medido] | rio 569,9 fps (−0,09 ms); bonecos 639,8 fps (−0,17 ms) [medido]; dentro do ruído | **2** no rio: água lilás-azulada com reflexo do céu e linha rosa na margem; o Three é escuro com brilhos laranja [medido: olhando] | **Não** (o shader não tem entrada para isso) [código] | Não como rio do Vagrant. Bom reflexo em tela, mas visual de "água realista" fora do estilo; contorno branco/rosa nas margens |
| Água | **waterbox** (godot-waterbox) | https://github.com/Adisoreq/godot-waterbox | MIT | 6 estrelas, último push 11/07/2026 [documentação: API do GitHub] | **Sim** (só o shader), sem erro [medido] | rio 599,6 fps (−0,17 ms); bonecos 631,0 fps (−0,15 ms) [medido]; dentro do ruído | **1**: no rio a água quase some (vê-se o leito); na poça, azul chapado [medido: olhando] | **Não**. O addon é empuxo de `RigidBody3D` (`water_box.gd`); os bonecos não são corpos rígidos [código] | Não. Shader de 20 linhas (seno + cor fixa); o valor do addon é física de boia, que esta cena não usa |
| Água | **interativa-namey5** (godot-interactive-water) | https://github.com/Namey5/godot-interactive-water | MIT | 20 estrelas, último push 06/02/2025 [documentação: API do GitHub] | **Sim**, com aviso: "shader requires tangents" no rio (a malha do glTF não tem tangentes) [medido, log de `printar.mjs`] | rio 517,8 fps (+0,09 ms); bonecos 573,7 fps (+0,01 ms) [medido]; dentro do ruído | **1**: no rio, névoa verde turva que vaza da margem; na poça, quase invisível (diferença média de 3,6 em 255 contra a base no recorte da poça) [medido]. A nota vale para esta adaptação: o rio dele não recebeu sol e céu (camada 2) e a malha não tem tangentes | **Sim na simulação, quase nada na tela**: a grade de onda tem os 4 pés como fontes de anéis (altura 0,26 a 0,79, repouso 0,5; `AGUA_DIAG`) [medido], mas com 5 cm de água o shader deixa a superfície quase transparente | Talvez como base técnica (equação da onda na placa de vídeo, que o Three faz no processador); pede ajuste de visual e grade de 16 bits |
| Água | DynamicWaterDemo (CaptainProton42) | https://github.com/CaptainProton42/DynamicWaterDemo | MIT | 259 estrelas, último push 14/06/2022 [documentação: API do GitHub] | **Não testado**: é projeto Godot 3 (`config_version=4`, driver GLES2, `onready`, `export(int, ...)`, `setget`), sintaxe que o Godot 4 não aceita [código, zip baixado em 20/11, sha256 `03c5da773bdf06b75fb086bf7a8c58247793ca4acd574ab07571bb6d076d3989`]. Não rodei o projeto | não medido | não avaliado | Sim no original (objetos geram ondas) [documentação: README] | Não sem portar para 4.x; a técnica é a mesma do Namey5 (viewports em pingue-pongue) |
| Água | Swell (fórum do Godot) | https://forum.godotengine.org/t/swell-a-free-water-system-for-godot-4-7-2-some-4-8-features/146916 | não informada ("free") | 15 curtidas no post, 08/11/2026 [documentação: fórum] | **Não testado**: ainda sem download (prévia; lançamento previsto fim de 2026 ou 1º tri 2027) [documentação: fórum] | não medido | não avaliado | Diz ter "push dents" e esteira para nadadores [documentação: fórum] | Não agora; rever quando sair |
| Água | shoreline-waves (Realistic Shoreline & Ocean Waves, Reboot16) | https://store.godotengine.org/asset/reboot16/waves/ | MIT (código), CC0 (texturas) [documentação: loja] | 1 avaliação positiva, versão 1.0 de 05/07/2026 marcada como instável [documentação: loja] | **Não testado**: `baixados/shoreline-waves/waves.zip` está **truncado** (229.376 bytes; o pacote oficial tem 647 MB; `tar` acusa "Truncated input") [medido], sha256 do truncado `04a3866379ce4ee03e5cd9ec9de005e804619056804273b41c31a706c6cd831f` | não medido | não avaliado | Não diz [documentação: loja] | Não baixei os 647 MB (simulação de praia/oceano em escala de quilômetros; ver dúvidas) |

Imagens: `imagens/<candidato>-<vista>[-claro].png`, vistas `padrao`, `rio` e `bonecos` (claro = luz de diagnóstico do integrador). Referência Three: `imagens/three-rio.png` (mesma câmera da vista `rio`, tirada com `print-three-rio.mjs`).

## 2. O que cada candidato faz aqui

- **Todos** trocam o material do rio por `material_override` (volta a `null` ao desligar) e criam a poça como filha do módulo (o menu apaga). `ssr-water` e `waterbox` também ligam a camada 2 no rio (sol e céu), porque são shaders iluminados e o rio do glTF está na camada 1 (só tochas); `desligar` devolve a camada antiga [código].
- **nativo**: `rio.gdshader` é o shader do Three linha a linha, com três mudanças: (1) a "borda" vem da distância ao centro do rio, porque o atributo `borda` não veio no glTF; (2) a cor final passa de sRGB para linear, porque o Three r117 escreve sem conversão e o Godot converte na saída [dedução, igual à etapa 1]; (3) o hash `fract(sin(x)*43758)` virou um hash sem seno: com o original, o rio saiu cheio de quadrados duros; com o novo, ficou como o Three [medido: dois prints na mesma câmera, causa provável = seno impreciso em argumento grande no Vulkan, dedução]. `poca.gdshader`: água escura iluminada pelas tochas do Godot, fundo entortado pela onda (lido da tela), mesmos anéis. Os anéis seguem `respingos()` do Three; gotas (pontos que pulam) não foram feitas, porque com bonecos parados só aparecem na entrada.
- **ssr-water**: shader original sem mudança; texturas de ruído recriadas com os parâmetros da demo; escala ajustada (`wave_height_scale` 0,05, `max_visible_depth` 1,5, `border_scale` 0,12), porque a demo é um mar de 320 x 320.
- **waterbox**: só `water.gdshader` do addon, `wave_strength` 0,03 (o padrão 0,2 levanta a água acima da margem).
- **interativa-namey5**: os dois shaders do autor, marcados "ALTERADO": 8 pés no lugar do mouse, grade num quadrado de 12 x 12 tiles sobre a poça, ondulação com repouso em zero. Os dois SubViewports de 1024 x 1024 são montados em código e avançam 60 passos por segundo (o original avança um por quadro, então a onda correria 10 vezes mais rápido a 600 fps) [código]. A grade é de 8 bits: os anéis saem em degraus (`sim.png` de diagnóstico) [medido].

## 3. Fps: método e leitura

- Driver do integrador `medir.mjs` (método da etapa 1: 1280 x 720, vsync desligado, janela fora da tela em x 20008, 2 s + 10 s, 3 rodadas intercaladas com a base, mediana), com o lock. Janela empurrada por `esconder-janela-agua.ps1`, e não pelo `godot-port\esconder-janela.ps1` do coordenador: é uma cópia que só mexe em Godot aberto depois dele, para não tirar da tela a janela "Vagrant sala (Godot)" do Fernando. Placa: RTX 5070, Vulkan Forward+ [medido].
- Arquivos: `medicoes/agua-rio.json`, `medicoes/agua-bonecos.json` [medido].

| Vista | Variante | fps por rodada | Mediana | ms (mediana) | Custo vs base |
|---|---|---|---|---|---|
| rio | base | 540,8 · 544,0 · 563,0 | 544,0 | 1,84 | 0 |
| rio | nativo | 414,7 · 616,0 · 482,6 | 482,6 | 2,07 | +0,23 |
| rio | ssr-water | 458,4 · 669,0 · 569,9 | 569,9 | 1,75 | −0,09 |
| rio | waterbox | 615,1 · 574,8 · 599,6 | 599,6 | 1,67 | −0,17 |
| rio | interativa-namey5 | 512,6 · 570,7 · 517,8 | 517,8 | 1,93 | +0,09 |
| bonecos | base | 553,4 · 577,4 · 708,7 | 577,4 | 1,73 | 0 |
| bonecos | nativo | 513,6 · 584,8 · 587,3 | 584,8 | 1,71 | −0,02 |
| bonecos | ssr-water | 593,1 · 678,5 · 639,8 | 639,8 | 1,56 | −0,17 |
| bonecos | waterbox | 625,6 · 694,8 · 631,0 | 631,0 | 1,58 | −0,15 |
| bonecos | interativa-namey5 | 573,7 · 640,8 · 479,0 | 573,7 | 1,74 | +0,01 |

- **Leitura:** custo negativo é impossível de verdade (o efeito só acrescenta trabalho), então a diferença entre variantes é ruído. A mesma variante oscilou até 0,8 ms entre rodadas (nativo no rio: 1,62 a 2,41 ms), enquanto a base no rio variou só 0,07 ms. Contra a base da mesma rodada, o `nativo` deu +0,56, −0,22 e +0,29 ms no rio e +0,14, −0,02 e +0,29 ms na vista bonecos. Conclusão: **esta medição não separa um candidato do outro nem dá o custo do `nativo` com precisão melhor que algo entre 0 e ~0,6 ms** [medido]. Por isso medi de novo o `nativo` (abaixo).
- **Segunda medição, só base e `nativo`, vista rio, 5 rodadas, todas com a placa em até 5% antes** (`medicoes/agua-rio-nativo-5r.json`) [medido]: base 749,3 · 725,7 · 769,5 · 756,7 · 769,3 (mediana 756,7 fps, 1,32 ms); nativo 694,1 · 718,5 · 718,6 · 729,4 · 697,1 (mediana 718,5 fps, 1,39 ms). Contra a base da mesma rodada: +0,11, +0,01, +0,09, +0,05, +0,13 ms. **Custo do `nativo`: cerca de 0,07 ms por quadro (0,01 a 0,13).** Os outros três não foram medidos de novo.
- Fora do método: 1 de 3 rodadas por variante (placa acima de 5% antes de medir; RustDesk ligado, como avisa o contrato), marcado `foraDoMetodo` nos JSON [medido].
- Triângulos na vista bonecos: base 21.285; nativo 21.287 (poça de 1 quad); ssr-water e waterbox 23.343 (poça subdividida 48 x 20); namey5 29.239 (96 x 40). Chamadas de desenho: +1 em todos [medido].
- A vista `padrao` (câmera da etapa 1) quase não mostra água: o rio está fora do quadro e a poça fica no escuro (diferença média de 0,02 a 0,15 em 255 contra a base) [medido]. Por isso as vistas `rio` e `bonecos`.

## 4. Liga e desliga

- `teste_ligar.gd` (rodar: `Godot --headless --path godot-candidatos -s res://efeitos/agua/teste_ligar.gd`) usa o mesmo `ligar`/`desligar` do menu em `vagrant.gd`: para cada candidato, liga, desliga, liga e desliga de novo, e confere que o rio volta ao material e à camada originais e que a poça some. Resultado: 8 de 8 voltas certas, `falhas: 0` [medido]. Não cliquei no menu na tela.

## 5. Arquivos

- `comum/agua_comum.gd`: onde fica a água (rio e poça), anéis dos pés (sem `modulo.gd`, o menu não lista).
- `nativo/` (`modulo.gd`, `rio.gdshader`, `poca.gdshader`); `ssr-water/`, `waterbox/`, `interativa-namey5/` (`modulo.gd`, shaders copiados, licença, `ORIGEM.md` com URL e sha256).
- `imagens/` (26 PNG + `.gdignore` para o Godot não importar), `medicoes/` (JSON das medições).
- `teste_ligar.gd` (autoteste de liga e desliga), `print-three-rio.mjs` (referência Three, usa o abridor da etapa 1 só para ler), `prints.ps1` (lote de prints), `esconder-janela-agua.ps1`.
- `interativa-namey5/modulo.gd` tem um diagnóstico ligado só pela variável de ambiente `AGUA_DIAG` (grava a grade de ondas em PNG).

## 6. Dúvidas abertas

- **Poça e fosso de verdade:** a planta exportada (mundo) não tem. Para testar como no `agua-LEIAME.md` (poça x 16 a 22, z 6 a 10; fosso x 32 a 34, z 14 a 16 na planta da sala), seria preciso exportar outra planta. A poça daqui é de demonstração e não tem referência Three; a nota dela é dedução.
- **Rio sem boneco:** nenhum boneco pisa no rio nesta cena (só o clipe "parado" foi exportado). A interação no rio está no código (mesmos anéis), mas não foi vista em print.
- **agua.js (equação da onda no processador)** não foi portado. O `nativo` usa os anéis analíticos do rio do Three; o Namey5 é o equivalente na placa de vídeo. Portar a grade do `agua.js` em GDScript é possível, mas custaria processador a cada quadro.
- **shoreline-waves:** o arquivo em `baixados/` está truncado. Baixar os 647 MB oficiais vale a pena? É simulação de praia e oceano; o próprio autor mede 60 fps numa RTX 4070 notebook [documentação: loja].
- Os zips do Namey5 (sha256 `408b8685…7f16`) e do DynamicWaterDemo (sha256 `03c5da77…3989`) estão só na pasta temporária da sessão, que pode ser apagada; o integrador pode copiá-los para `baixados\` (não mexo lá).
- Só o `nativo` foi medido de novo com 5 rodadas limpas; `ssr-water`, `waterbox` e `interativa-namey5` ficaram com a medição de 3 rodadas, que não separa custo do ruído.
