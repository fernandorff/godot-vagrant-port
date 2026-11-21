extends Node
# FogVolume com shader de ruído animado: porte da densidade de fumaca.js (camada rasteira + pluma por fogo aceso).

const NOME := "Fumaça: FogVolume + ruído (porte do fumaca.js)"
const EXCLUSIVO := true
const VISTA := "braseiro"

const CAIXA_MIN := Vector3(-2, 0, -2)   # a parte da sala perto da câmera, como a caixa do LEIAME (2 além das paredes, teto 11)
const CAIXA_MAX := Vector3(46, 11, 92)
# névoa volumétrica ligada só para os volumes: densidade global 0
const NOVO := {
	"volumetric_fog_enabled": true,
	"volumetric_fog_density": 0.0,
	"volumetric_fog_anisotropy": 0.35,   # Henyey-Greenstein g = 0,35 do fumaca.js
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
	var fontes := PackedVector4Array()
	for f in cena.fogos:
		if not f.apagada and fontes.size() < 18:
			fontes.append(Vector4(f.chama.x, f.chama.y, f.chama.z, f.forca))
	var mat := ShaderMaterial.new()
	mat.shader = load(get_script().resource_path.get_base_dir() + "/fumaca.gdshader")
	mat.set_shader_parameter("fontes", fontes)
	mat.set_shader_parameter("n_fontes", fontes.size())
	mat.set_shader_parameter("caixa_min", CAIXA_MIN)
	mat.set_shader_parameter("caixa_max", CAIXA_MAX)
	var v := FogVolume.new()
	v.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	v.size = CAIXA_MAX - CAIXA_MIN
	v.position = (CAIXA_MIN + CAIXA_MAX) * 0.5
	v.material = mat
	add_child(v)

func desligar() -> void:
	for k in _antes:
		_amb.set(k, _antes[k])
	_antes.clear()
