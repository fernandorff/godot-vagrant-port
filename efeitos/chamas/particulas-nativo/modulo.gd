extends Node
# Chamas, halos e brasas só com recursos nativos, imitando a página: chama = quadrado virado para a câmera com o mesmo
# degradê radial (aditivo, sem névoa) esticado na vertical e tremendo; halo = o mesmo degradê maior com opacidade 0,22;
# brasas = GPUParticles3D, 10 por fogo, sobem 0,7 a 1,5 por segundo e vivem 0,8 a 2,4 s (sala-fechada.html 616-647, 982-988, 1608).

const NOME := "Nativo: Sprite + GPUParticles3D (cópia da página)"
const EXCLUSIVO := true
const VISTA := "braseiro"
# a página usa 0,22, mas o three r117 não converte a saída para sRGB e o Godot converte: o mesmo halo fraco fica ~4x mais
# claro na tela. 0,05 calibrado olhando o print lado a lado (efeitos/chamas/imagens).
const HALO := 0.05

var chamas: Array = []  # [MeshInstance3D, tam, fase]
var tempo := 0.0

func _degrade() -> GradientTexture2D:  # o canvas 64x64 da página (linha 617)
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([Color("#fff6d0"), Color("#ffc060"), Color(1, 110 / 255.0, 30 / 255.0, 0.35), Color(1, 80 / 255.0, 20 / 255.0, 0.0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func _material(tex: Texture2D, opacidade: float, particula: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES if particula else BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	m.albedo_texture = tex
	m.albedo_color = Color(1, 1, 1, opacidade)
	m.vertex_color_use_as_albedo = particula
	return m

func ligar(cena: Node3D) -> void:
	var tex := _degrade()
	var m_chama := _material(tex, 1.0, false)
	var m_halo := _material(tex, HALO, false)
	var m_brasa := _material(tex, 1.0, true)
	var quad := QuadMesh.new()
	var i := 0
	for f in cena.fogos:
		i += 1
		if f.apagada: continue
		var tam := 1.5 if f.braseiro else 0.9
		var ch := MeshInstance3D.new()
		ch.mesh = quad
		ch.material_override = m_chama
		ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ch.position = f.chama
		add_child(ch)
		chamas.append([ch, tam, i * 1.37])
		var halo := MeshInstance3D.new()
		halo.mesh = quad
		halo.material_override = m_halo
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.position = f.chama
		halo.scale = Vector3.ONE * (5.0 if f.braseiro else 3.5)
		add_child(halo)
		var p := GPUParticles3D.new()
		p.amount = 10
		p.lifetime = 2.4
		p.preprocess = 2.4
		p.position = f.chama
		p.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 6, 4))
		var pm := ParticleProcessMaterial.new()
		pm.gravity = Vector3.ZERO
		pm.direction = Vector3.UP
		pm.spread = 15.0
		pm.initial_velocity_min = 0.7
		pm.initial_velocity_max = 1.5
		pm.lifetime_randomness = 0.66  # 0,8 a 2,4 s
		var rampa := Gradient.new()
		rampa.colors = PackedColorArray([Color(1.0, 0.75, 0.35, 1), Color(1.0, 0.4, 0.1, 0)])
		var rt := GradientTexture1D.new()
		rt.gradient = rampa
		pm.color_ramp = rt
		p.process_material = pm
		var pq := QuadMesh.new()
		pq.size = Vector2(0.09, 0.09)
		p.draw_pass_1 = pq
		p.material_override = m_brasa
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(p)

func _process(dt: float) -> void:
	tempo += dt
	for c in chamas:
		var f := 0.85 + 0.15 * sin(tempo * 9.0 + c[2]) * sin(tempo * 5.3 + c[2] * 2.0)  # tremor (a página usa tremor(tempo, fase))
		c[0].scale = Vector3(c[1] * (0.9 + 0.1 * f), c[1] * 1.4 * f, 1.0)

func desligar() -> void:
	chamas.clear()
