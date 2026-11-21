# Prints 1280x720 de cada candidato de água (usa printar.mjs do integrador, que espera o lock de medição).
# Uso: pwsh -File prints.ps1 [candidato ...]
param([string[]]$cands = @('base', 'nativo', 'ssr-water', 'waterbox', 'interativa-namey5'))
$raiz = 'D:\Projetos\godot-cidade\lab-engine\godot-candidatos'
Set-Location $raiz
foreach ($c in $cands) {
  $ef = if ($c -eq 'base') { '' } else { "agua/$c" }
  foreach ($v in @(@('padrao', '0'), @('rio', '0'), @('rio', '1'), @('bonecos', '0'), @('bonecos', '1'))) {
    $suf = if ($v[1] -eq '1') { '-claro' } else { '' }
    node printar.mjs --efeitos "$ef" --vista $v[0] --claro $v[1] --png "efeitos/agua/imagens/$c-$($v[0])$suf.png"
  }
}
