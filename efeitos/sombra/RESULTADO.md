# Sombra e cantos escurecidos: candidatos testados (20/11/2026)

Origem: **[medido]** = rodado hoje nesta pasta; **[documentação: link]**; **[dedução]** = não provado.
Godot 4.7.2, Forward+, RTX 5070, 1280x720. A base (menu "desligado") é a sombra suave da etapa 1 (filtro SOFT_HIGH), como o
padrão "suave" da página. Só 2 luzes de ponto têm sombra (como na página): o braseiro em (29; 2,95; 13) e a tocha em (3; 5,4; 14,75).

## Tabela

| Efeito | Candidato | Origem | Licença | Funciona no 4.7.2? | fps (mediana de 3) e custo | Semelhança 0-5 | Usar? |
|---|---|---|---|---|---|---|---|
| Sombra suave | base (filtro SOFT_HIGH) | nativo | MIT (motor) | sim (etapa 1) | 740,4 fps, 1,35 ms | não avaliável (ver abaixo) | É a base |
| Sombra dura | `dura`: filtro HARD | nativo | MIT | **sim, sem erro** [medido] | 761,9 fps; -0,04 ms (dentro do ruído) | não avaliável | Só se o jogo quiser o `sombras=dura` |
| Penumbra que alarga (PCSS) | `pcss-nativo`: `light_size = 0,4` nas luzes de ponto | nativo, [documentação: https://docs.godotengine.org/en/stable/classes/class_light3d.html, light_size: "Penumbras are simulated with percentage-closer soft shadows, or PCSS"] | MIT | **sim, sem erro** [medido] | 724,3 fps; +0,03 ms (dentro do ruído) | **não avaliável** | **Usar** no lugar do PCSS próprio da página: é uma linha, sem shader, sem custo medível. A semelhança da penumbra não pôde ser julgada (nenhuma vista tem borda de sombra visível) |
| Cantos escurecidos (SSAO) | `ssao-nativo`: SSAO do Environment, raio 1, intensidade 2, `ssao_light_affect` 0,6 | nativo, [documentação: https://docs.godotengine.org/en/stable/classes/class_environment.html, "SSAO is only supported in the Forward+ and Compatibility"; light_affect > 0 "will make the SSAO effect visible in direct light"] | MIT | **sim, sem erro** [medido] | 649,6 fps; +0,19 ms (2 de 3 rodadas fora do método) | **1** | **Não usar agora:** na luz real da sala não muda nenhum pixel, nem com `ssao_light_affect` 1,0 e intensidade 8 [medido]; só aparece com a luz clara de diagnóstico. Rever quando a sala tiver luz ambiente |

Plugin de sombra ou SSAO de terceiros: nenhum testado. O nativo já cobre os dois e não achei pacote consagrado de PCSS para
Godot 4 (o recurso virou nativo no 4.0, via `light_size`) [dedução a partir da documentação acima].

## Imagens (olhei cada uma)

Em `imagens/`: `three-<suave|dura|pcss>-braseiro.png`, `three-<suave|ssao>-bonecos.png` (original, mesma câmera, fumaça desligada
para a sombra aparecer), `base|dura|pcss-nativo-braseiro[-claro].png`, `base|ssao-nativo-bonecos[-claro].png`,
`lado-braseiro-x3.png` (lado a lado, brilho x3), `recorte-x5-godot-cima-three-baixo.png`, `lado-bonecos-x4.png`, `lado-bonecos-claro.png`,
`dif-x40-base-vs-pcss-godot.png` (diferença entre base e PCSS, ampliada 40x).

- **Sombra suave x dura x PCSS:** nesta sala a diferença quase não aparece, nos dois motores. No Godot, diferença média de pixel
  entre base e dura: 0,004 de 255; base e PCSS: 0,044 (1.433 pixels mudam mais de 8) [medido]. No mapa de diferença o PCSS muda a
  borda da bacia do braseiro e uma auréola fraca no chão em volta do pé. No Three a comparação por pixel não serve (a chama e as
  brasas mudam entre os prints), mas olhando, as três versões também ficam quase iguais.
- **Câmera da etapa 1 (`padrao`) e vista dos bonecos:** dura e PCSS não mudam a imagem (diferença média 0,001 a 0,009 de 255,
  no máximo 1 pixel acima de 8) [medido]. Na vista dos bonecos a sombra deles no chão não aparece em nenhum dos dois motores (estão
  na borda do alcance do braseiro; `lado-sombra-bonecos-x6.png`, brilho x6). **Conclusão: nesta sala, com a luz atual, não há
  borda de sombra visível para comparar suave, dura e PCSS**; a nota de semelhança fica "não avaliável". Para avaliar, precisa de
  uma cena de teste com um objeto entre a tocha e uma parede próxima.
- **Diferença que aparece:** no Three a bacia esconde a parte de cima e a chama cobre a luz; no Godot (sem chama nesses prints) a borda
  da bacia brilha muito, porque a luz está dentro dela. O chão em volta do pé fica iluminado nos dois.
- **SSAO:** na luz clara de diagnóstico escurece a base das paredes e o chão em volta dos pés (brilho médio 65,5 -> 64,3) [medido].
  Na luz real a mudança é **exatamente zero** no Godot, nas três vistas: `padrao`, `bonecos` e `braseiro` (onde pilar, chão e pé do
  braseiro estão iluminados), e também com `--ssao-luz=1.0 --ssao-forca=8` (`ssao-nativo-braseiro-luz1-forca8.png`, diferença 0,0)
  [medido]. A documentação diz que `ssao_light_affect` acima de 0 faz o efeito aparecer na luz direta; aqui não apareceu. Causa não
  identificada [dedução possível: o efeito só multiplica a luz ambiente/indireta e a sala tem ambiente zero]. No Three o SSAO da
  página muda quase nada nessa câmera (0,09 de 255).

## Fps [medido]

Mesma execução das chamas (`medicoes/chamas-sombra-braseiro.json`), vista `braseiro`, rodadas intercaladas.

| Variante | r1 | r2 | r3 | Mediana | ms | Custo vs base |
|---|---|---|---|---|---|---|
| base | 740,38 | 782,96 | 581,90 | 740,38 | 1,35 | — |
| dura | 761,89 | 778,69 | 701,85 | 761,89 | 1,31 | -0,04 |
| PCSS | 724,27 | 681,09 | 734,49 | 724,27 | 1,38 | +0,03 |
| SSAO | 717,88 | 631,04 | 649,60 | 649,60 | 1,54 | +0,19 |

Ruído: a base variou 582 a 783 fps; a placa ficou acima de 5% antes de algumas rodadas (RustDesk ~12% e Edge), marcadas
"fora do método" no JSON. Só o SSAO (+0,19 ms) passa perto do tamanho do ruído; dura e PCSS ficam dentro dele.

## Não testado e por quê

- Ajuste fino de `light_size` (0,4 copia o `PCSS_LUZ` da página; o módulo aceita `--pcss=X`): não comparei outros valores.
- Sombra que só alguns objetos recebem (receiveShadow da página): o Godot não tem por objeto (anotado na etapa 1).
