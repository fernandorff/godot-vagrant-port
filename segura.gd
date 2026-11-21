class_name Segura
extends SkeletonModifier3D
## Tocha na mão (sala-fechada.html:1225-1238, segura()): o ombro gira até a mão apontar para um ponto à frente do peito,
## do lado daquela mão; a tocha fica em pé no punho. Roda depois da animação (modificador do esqueleto), e a animação do
## quadro seguinte devolve o ombro do clipe, como o q0 da página.

const ALT_ASHLEY := 3.67
const INCLINA := 0.3             # rad: a tocha pende para a frente
const CHAMA := Vector3(0, 0.95, 0)  # a chama no copo, em coordenadas da tocha

var u: Unidade
var mao := -1
var ombro := -1

func _process_modification() -> void:
	var l := u.leva
	var sk := get_skeleton()
	var ry := u.no.rotation.y
	var esc := u.alt / ALT_ASHLEY
	if l.braco > 0.01:
		var inv := sk.global_transform.affine_inverse()
		var o := sk.get_bone_global_pose(ombro).origin
		var m := sk.get_bone_global_pose(mao).origin
		var alvo := u.no.position + Vector3(sin(ry) * 0.95 * esc, u.alt * 0.62, cos(ry) * 0.95 * esc)
		alvo.x += cos(ry) * l.lado * 0.5 * esc
		alvo.z -= sin(ry) * l.lado * 0.5 * esc
		var qa := Quaternion((m - o).normalized(), ((inv * alvo) - o).normalized())  # de onde a mão está para onde deve ir, no espaço do esqueleto
		var gl := sk.get_bone_global_pose(ombro).basis.get_rotation_quaternion()
		var pai := sk.get_bone_parent(ombro)
		var gp := sk.get_bone_global_pose(pai).basis.get_rotation_quaternion() if pai >= 0 else Quaternion.IDENTITY
		sk.set_bone_pose_rotation(ombro, sk.get_bone_pose_rotation(ombro).slerp(gp.inverse() * qa * gl, l.braco))
	# a tocha no punho, em pé e virada com o corpo
	var pm := sk.global_transform * sk.get_bone_global_pose(mao).origin
	var b := Basis(Vector3.UP, ry) * Basis(Vector3.RIGHT, INCLINA)
	l.modelo.global_transform = Transform3D(b.scaled(Vector3.ONE * esc), pm)
	l.chama = l.modelo.global_transform * CHAMA
