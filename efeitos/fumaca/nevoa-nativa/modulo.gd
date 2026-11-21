extends Node
# Névoa volumétrica nativa do Environment (Godot 4, Forward+): neblina uniforme na sala, iluminada pelas tochas pelo próprio motor.

const NOME := "Fumaça: névoa volumétrica nativa"
const EXCLUSIVO := true
const VISTA := "braseiro"

# valores pensados para imitar fumaca.js: cor 0xbfd1ff, ambiente azulado 0x293352, espalhamento Henyey-Greenstein g = 0,35
const NOVO := {
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.03,
	"volumetric_fog_albedo": Color("bfd1ff"),
	"volumetric_fog_emission": Color("293352"),
	"volumetric_fog_emission_energy": 0.15,
	"volumetric_fog_anisotropy": 0.35,
	"volumetric_fog_length": 64.0,
	"volumetric_fog_gi_inject": 0.0,
	"volumetric_fog_sky_affect": 0.0,
	"volumetric_fog_temporal_reprojection_enabled": true,
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
