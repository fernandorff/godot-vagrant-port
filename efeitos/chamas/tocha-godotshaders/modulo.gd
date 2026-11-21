extends Node
# "Procedural Torch & Candle Shader" (godotshaders.com, CaptainLaptop, CC0/MIT), sem alterar o shader. Ele é canvas_item
# (2D): desenhado num ColorRect dentro de um SubViewport e a imagem vai num quadrado virado para a câmera em cada fogo.
# shortcut: um SubViewport só para todos os fogos (todas as chamas iguais e em fase); um por fogo custaria 11 desenhos 2D.

const NOME := "Shader de tocha (godotshaders.com, CaptainLaptop)"
const EXCLUSIVO := true
const VISTA := "braseiro"

func ligar(cena: Node3D) -> void:
	var sv := SubViewport.new()
	sv.size = Vector2i(128, 256)
	sv.transparent_bg = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var cr := ColorRect.new()
	cr.size = Vector2(128, 256)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://efeitos/chamas/tocha-godotshaders/tocha.gdshader")
	sm.set_shader_parameter("aspectRatio", 0.5)  # largura/altura do retângulo (USAGE do shader)
	cr.material = sm
	sv.add_child(cr)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.billboard_keep_scale = true
	m.albedo_texture = sv.get_texture()
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 2)
	for f in cena.fogos:
		if f.apagada: continue
		var tam := 1.5 if f.braseiro else 0.9
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * tam * 1.6
		mi.position = f.chama + Vector3(0, tam * 0.6, 0)  # o shader desenha a partir do centro para cima
		add_child(mi)

func desligar() -> void:
	pass
