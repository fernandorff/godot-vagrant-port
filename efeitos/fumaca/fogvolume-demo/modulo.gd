extends Node
# FogVolume com o shader de névoa rasteira do demo oficial de névoa volumétrica (godot-demo-projects, MIT), só com parâmetros ajustados à sala.

const NOME := "Fumaça: FogVolume do demo oficial (névoa rasteira)"
const EXCLUSIVO := true
const VISTA := "braseiro"

const CAIXA_MIN := Vector3(-2, 0, -2)
const CAIXA_MAX := Vector3(46, 11, 92)
const NOVO := {
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.0,
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
	var mat := ShaderMaterial.new()
	mat.shader = load(get_script().resource_path.get_base_dir() + "/nevoa-ruido.gdshader")
	mat.set_shader_parameter("base_density", 0.25)
	mat.set_shader_parameter("base_color", Color("bfd1ff"))
	mat.set_shader_parameter("fade_out_height", 0.5)   # camada do chão até ~3 de altura (boneco tem ~3,5)
	mat.set_shader_parameter("fade_out_distance", 2.5)
	mat.set_shader_parameter("noise_velocity1", Vector3(0.15, 0, 0))   # o demo anda rápido (0,5 a 1 por segundo); fumaça lenta
	mat.set_shader_parameter("noise_velocity2", Vector3(0.2, 0, -0.2))
	mat.set_shader_parameter("noise_velocity3", Vector3(0, 0.15, 0.1))
	var v := FogVolume.new()
	v.size = CAIXA_MAX - CAIXA_MIN
	v.position = (CAIXA_MIN + CAIXA_MAX) * 0.5
	v.material = mat
	add_child(v)

func desligar() -> void:
	for k in _antes:
		_amb.set(k, _antes[k])
	_antes.clear()
