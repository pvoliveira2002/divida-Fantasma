extends Button

const NAMES := ["CURTO-CIRCUITO", "RASTRO FANTASMA", "SOBRECARGA"]
const TYPES := ["PROTOCOLO DE ATAQUE", "PROTOCOLO DE ESQUIVA", "PROTOCOLO CORPO A CORPO"]
const COLORS := [Color("49f4ff"), Color("ff48c4"), Color("ffd36c")]
const LINES := [
	["Acerte 3 golpes no mesmo alvo", "para liberar uma descarga", "em um inimigo próximo."],
	["A esquiva deixa uma silhueta", "que explode após um breve", "atraso, atingindo a área."],
	["Conecte 3 golpes para carregar", "o braço. O próximo acerto", "libera uma onda frontal."],
]
var protocol_index := 0
var rank := 0

func _ready() -> void:
	custom_minimum_size = Vector2(340, 350)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("0b1826") if state == "normal" else Color("142b3b")
		if state == "focus":
			style.bg_color = Color(0, 0, 0, 0)
		style.border_color = COLORS[protocol_index] if state in ["hover", "pressed", "focus"] else Color("2a4256")
		style.set_border_width_all(2)
		style.set_corner_radius_all(8)
		add_theme_stylebox_override(state, style)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	tooltip_text = "Atalho: %d. Reinstalar aumenta em 1 o dano do efeito. Bônus duram até reiniciar." % (protocol_index + 1)

func _center_text(value: String, y: float, font_size: int, color: Color) -> void:
	var font := get_theme_default_font()
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2((size.x - width) * 0.5, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var accent: Color = COLORS[protocol_index]
	var active := is_hovered() or has_focus()
	var wire := Color(accent, 0.4 if active else 0.16)
	for side in [-1, 1]:
		var x: float = size.x * 0.5 + side * 68
		draw_polyline(PackedVector2Array([Vector2(x, 23), Vector2(x, 57), Vector2(x + side * 38, 75), Vector2(x + side * 38, 118)]), wire, 2.0, true)
		draw_circle(Vector2(x + side * 38, 118), 3, wire)
	var center := Vector2(size.x * 0.5, 76)
	draw_arc(center, 43, 0, TAU, 48, Color(accent, 0.2), 1.0, true)
	match protocol_index:
		0:
			draw_polyline(PackedVector2Array([center + Vector2(9,-29), center + Vector2(-17,4), center + Vector2(3,4), center + Vector2(-9,29), center + Vector2(20,-6), center + Vector2(0,-6), center + Vector2(9,-29)]), accent, 4, true)
		1:
			for echo in 3:
				var offset := center + Vector2(echo * 10 - 10, 0)
				draw_arc(offset + Vector2(0,-16), 9, PI, TAU, 16, Color(accent, 1.0 - echo * 0.25), 3, true)
				draw_polyline(PackedVector2Array([offset + Vector2(-9,-16), offset + Vector2(-17,23), offset + Vector2(0,16), offset + Vector2(17,23), offset + Vector2(9,-16)]), Color(accent, 1.0 - echo * 0.25), 2, true)
		2:
			for bar in 3:
				draw_rect(Rect2(center + Vector2(-24 + bar * 18, 18 - bar * 12), Vector2(12, 12 + bar * 12)), accent)
			draw_arc(center, 33, PI * 1.1, TAU * 0.95, 24, accent, 3, true)
	_center_text(TYPES[protocol_index], 147, 12, accent)
	_center_text(NAMES[protocol_index], 179, 23, Color("edf8ff"))
	for line in 3:
		_center_text(LINES[protocol_index][line], 216 + line * 24, 17, Color("b9cbd9"))
	draw_line(Vector2(24, 285), Vector2(size.x - 24, 285), wire, 1)
	var badge := "NOVO PROTOCOLO" if rank == 0 else "EVOLUIR · +1 DANO DO EFEITO"
	_center_text(badge, 312, 14, accent)
	_center_text("[ %d ]  INSTALAR" % (protocol_index + 1), 336, 13, Color("829db2"))
