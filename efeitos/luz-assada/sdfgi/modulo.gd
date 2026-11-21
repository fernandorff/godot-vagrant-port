extends Node
# SDFGI (luz indireta em tempo real, campo de distância em cascatas) do Environment do Godot 4: rebate a luz das tochas sem assar.

const NOME := "Luz indireta: SDFGI (tempo real)"
const EXCLUSIVO := true
const VISTA := "braseiro"

const NOVO := {
	"sdfgi_enabled": true,
	"sdfgi_use_occlusion": true,
	"sdfgi_cascades": 4,
	"sdfgi_min_cell_size": 0.2,
	"sdfgi_energy": 1.0,
	"sdfgi_bounce_feedback": 0.5,
}
var _antes := {}
var _amb: Environment

func ligar(cena: Node3D) -> void:
	_amb = cena.ambiente
	for k in NOVO:
		_antes[k] = _amb.get(k)
		_amb.set(k, NOVO[k])

func desligar() -> void:
	for k in _antes:
		_amb.set(k, _antes[k])
	_antes.clear()
