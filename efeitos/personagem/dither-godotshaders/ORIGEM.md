# Origem: Transparency Dither (godotshaders.com)

- Página: https://godotshaders.com/shader/transparency-dither/ (autor "jacob", publicado 22/01/2025). Licença: CC0, lida na página ("all code snippets in this post are under CC0 license").
- Página salva em 20/11/2026 no scratchpad da sessão, sha256 `5e3ebc3bb05f53ad41a131393eb07ef4191c4b9c751d033be7e5c1f749e83c6a` (HTML muda com anúncios; o código extraído é o que vale).
- Código dele (11 linhas) usado em `dither_inteiro.gdshader`: a constante `ign` e o teste de descarte por ruído de gradiente intercalado, o mesmo ruído ("fino") do Three.
- Mudanças do lab, marcadas no arquivo: textura x cor de vértice no lugar da cor lisa; o alfa vem de `visto` (uniforme por instância) em vez de `color.a`; `visto` é a função `visto()` da sala-fechada.html (modo "Boneco inteiro").
