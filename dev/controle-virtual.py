# Controle de Xbox virtual (ViGEmBus + vgamepad) para o teste --controle-real do vagrant.gd.
# Uso: python dev/controle-virtual.py [--menu] --sinal=<arq>
#      junto com ./godot.sh -- --caso=1 --controle-real --sinal=<o mesmo arq, apagado antes> --saida=...
# Sem --menu: aperta cada comando do jogo (~11 s). Com --menu: abre o menu com Start, desce 2 itens, marca e desmarca com A, fecha.
import os
import sys
import time
import vgamepad as vg

B = vg.XUSB_BUTTON
g = vg.VX360Gamepad()
sinal = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--sinal=")), None)
if sinal:  # espera o Godot criar o arquivo-sinal (o tempo de carga varia; o stdout dele sai em blocos)
    fim = time.time() + 60
    while time.time() < fim and not os.path.exists(sinal):
        time.sleep(0.2)
    time.sleep(0.5)
else:
    time.sleep(4)


def aperta(botao, nome):
    print("aperta", nome, flush=True)
    g.press_button(button=botao); g.update(); time.sleep(0.15)
    g.release_button(button=botao); g.update(); time.sleep(0.35)


if "--menu" in sys.argv:
    # Start abre; A abre a lista (1º item), baixo e A trocam o valor; baixo 2x e A marcam uma caixa
    for b, n in [(B.XUSB_GAMEPAD_START, "Start"), (B.XUSB_GAMEPAD_A, "A (abre a lista)"), (B.XUSB_GAMEPAD_DPAD_DOWN, "baixo"),
                 (B.XUSB_GAMEPAD_A, "A (escolhe)"), (B.XUSB_GAMEPAD_DPAD_DOWN, "baixo"), (B.XUSB_GAMEPAD_DPAD_DOWN, "baixo"),
                 (B.XUSB_GAMEPAD_A, "A (marca)")]:
        aperta(b, n)
    print("menu aberto: analógico segurado 1 s, X (o herói não pode andar nem golpear)", flush=True)
    g.left_joystick_float(0.0, 1.0); g.update(); time.sleep(1.0)
    g.left_joystick_float(0.0, 0.0); g.update(); time.sleep(0.3)
    aperta(B.XUSB_GAMEPAD_X, "X")
    aperta(B.XUSB_GAMEPAD_B, "B (fecha o menu, sem fogo)")
else:
    print("anda (analógico esquerdo) 1,5 s", flush=True)
    g.left_joystick_float(0.0, -1.0); g.update(); time.sleep(1.5)
    g.left_joystick_float(0.0, 0.0); g.update(); time.sleep(0.3)
    print("gira a câmera (analógico direito) 1 s", flush=True)
    g.right_joystick_float(1.0, 0.0); g.update(); time.sleep(1.0)
    g.right_joystick_float(0.0, 0.0); g.update(); time.sleep(0.3)
    print("corre (RT) e anda 1 s", flush=True)
    g.right_trigger_float(1.0); g.left_joystick_float(0.0, 1.0); g.update(); time.sleep(1.0)
    g.right_trigger_float(0.0); g.left_joystick_float(0.0, 0.0); g.update(); time.sleep(0.3)
    print("LT", flush=True)
    g.left_trigger_float(1.0); g.update(); time.sleep(0.2); g.left_trigger_float(0.0); g.update(); time.sleep(0.3)
    for b, n in [(B.XUSB_GAMEPAD_A, "A"), (B.XUSB_GAMEPAD_X, "X"), (B.XUSB_GAMEPAD_B, "B"), (B.XUSB_GAMEPAD_Y, "Y"),
                 (B.XUSB_GAMEPAD_LEFT_SHOULDER, "LB"), (B.XUSB_GAMEPAD_RIGHT_SHOULDER, "RB"),
                 (B.XUSB_GAMEPAD_DPAD_UP, "cima"), (B.XUSB_GAMEPAD_DPAD_DOWN, "baixo"),
                 (B.XUSB_GAMEPAD_RIGHT_THUMB, "RS"), (B.XUSB_GAMEPAD_START, "Start"), (B.XUSB_GAMEPAD_START, "Start")]:
        aperta(b, n)
time.sleep(1)
aperta(B.XUSB_GAMEPAD_BACK, "Back (encerra o teste)")
time.sleep(1)
del g
