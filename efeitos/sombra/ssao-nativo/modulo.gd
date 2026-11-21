extends Node
# Cantos escurecidos (SSAO) nativos do Environment (Forward+). A sala tem luz ambiente zero e o SSAO do Godot só escurece
# a luz ambiente por padrão; ssao_light_affect > 0 faz ele escurecer também a luz das tochas (documentação de Environment).

const NOME := "Cantos escurecidos (SSAO nativo)"
const EXCLUSIVO := false  # liga junto com a sombra escolhida
const VISTA := "bonecos"
const CAMPOS := {"ssao_enabled": true, "ssao_radius": 1.0, "ssao_intensity": 2.0, "ssao_power": 1.5, "ssao_detail": 0.5, "ssao_light_affect": 0.6}

var antes := {}
var amb: Environment

func ligar(cena: Node3D) -> void:
	amb = cena.ambiente
	var campos := CAMPOS.duplicate()
	for a in OS.get_cmdline_user_args():  # --ssao-luz=X e --ssao-forca=X: teste de calibração
		if a.begins_with("--ssao-luz="): campos.ssao_light_affect = float(a.substr(11))
		elif a.begins_with("--ssao-forca="): campos.ssao_intensity = float(a.substr(13))
	for k in campos:
		antes[k] = amb.get(k)
		amb.set(k, campos[k])

func desligar() -> void:
	for k in antes: amb.set(k, antes[k])
	antes.clear()
