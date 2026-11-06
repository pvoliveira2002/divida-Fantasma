extends Control

signal chosen(room_index: int)

const CARD := preload("res://scripts/protocol_card.gd")
const TITLES := ["CURTO-CIRCUITO", "RASTRO FANTASMA", "SOBRECARGA"]

var ranks: Array[int] = [0, 0, 0]
var rewarded_rooms: Array[int] = []
var pending_room := -1
var buttons: Array[Button] = []
var heading: Label
var summary: Label
var arena: Node


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.02, 0.055, 0.94)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("2fffd5"))
	column.add_child(heading)
	var hint := Label.new()
	hint.text = "Escolha um protocolo para instalar"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 18)
	column.add_child(cards)
	for index in 3:
		var button := CARD.new()
		button.protocol_index = index
		button.pressed.connect(func(): choose(index))
		cards.add_child(button)
		buttons.append(button)
	summary = Label.new()
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.text = "1 / 2 / 3 para instalar · Combine protocolos ou evolua um já instalado."
	column.add_child(summary)
	hide()


func offer(room_index: int) -> bool:
	if pending_room != -1 or room_index in rewarded_rooms or arena.run_state != arena.RunState.PLAYING:
		return false
	if room_index != arena.rooms.room_index or not arena.rooms.room_cleared:
		return false
	pending_room = room_index
	arena._finish_hit_stop()
	arena.player.reset_combat_pose()
	arena.player.controls_enabled = false
	heading.text = "SALA CONCLUÍDA · PROTOCOLOS DISPONÍVEIS"
	for index in 3:
		buttons[index].disabled = false
		buttons[index].rank = ranks[index]
		buttons[index].queue_redraw()
	show()
	return true


func choose(index: int) -> bool:
	if index < 0 or index >= ranks.size() or pending_room < 0 or not visible:
		return false
	if arena.run_state != arena.RunState.PLAYING or arena.player.is_dead:
		return false
	var room := pending_room
	# Consume the reward before applying it: repeated input cannot grant it twice.
	pending_room = -1
	rewarded_rooms.append(room)
	ranks[index] += 1
	for button in buttons:
		button.disabled = true
	arena.protocols.install(index)
	var installed: PackedStringArray = []
	for protocol_index in 3:
		if ranks[protocol_index] > 0:
			installed.append("%s %d" % [TITLES[protocol_index], ranks[protocol_index]])
	arena.get_node("Interface/UpgradeSummary").text = "PROTOCOLOS  " + " · ".join(installed)
	hide()
	arena.player.controls_enabled = true
	chosen.emit(room)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if not visible or pending_room < 0:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index := [KEY_1, KEY_2, KEY_3].find(event.physical_keycode)
		if index >= 0:
			choose(index)
			get_viewport().set_input_as_handled()
