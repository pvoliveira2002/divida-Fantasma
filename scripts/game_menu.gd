extends CanvasLayer

const BACKDROP := preload("res://scripts/menu_backdrop.gd")
var settings_path := "user://preferences.cfg"
var in_game := false
var page := ""
var return_page := "start"
var changing_scene := false
var panel: Control
var column: VBoxContainer
var volume_slider: HSlider
var volume_label: Label


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_volume()
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	if in_game:
		var shade := ColorRect.new()
		shade.color = Color(0.015,0.025,0.06,0.94)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(shade)
	else:
		var backdrop := BACKDROP.new()
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		panel.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(center)
	column = VBoxContainer.new()
	column.custom_minimum_size = Vector2(560, 0)
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	if in_game:
		panel.hide()
	else:
		show_page("start")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.physical_keycode == KEY_ESCAPE and event.pressed and not event.echo):
		return
	if changing_scene:
		return
	if panel.visible:
		if page in ["controls", "volume"]:
			show_page(return_page)
		elif in_game:
			resume_game()
	elif in_game and get_parent().run_state == get_parent().RunState.PLAYING:
		open_pause()
	else:
		return
	get_viewport().set_input_as_handled()


func open_pause() -> void:
	if not in_game or changing_scene or get_parent().run_state != get_parent().RunState.PLAYING:
		return
	get_tree().paused = true
	show_page("pause")


func resume_game() -> void:
	panel.hide()
	get_tree().paused = false


func show_page(next_page: String) -> void:
	page = next_page
	for child in column.get_children():
		column.remove_child(child)
		child.queue_free()
	panel.show()
	match page:
		"start":
			_title("DÍVIDA FANTASMA")
			_text("Recupere suas memórias. Enfrente o Cobrador.")
			_text("3 salas · protocolos combináveis · confronto final")
			_button("INICIAR TENTATIVA", start_run)
			_button("CONTROLES", func(): open_details("controls"))
			_button("VOLUME", func(): open_details("volume"))
			_button("SAIR", func(): get_tree().quit())
			_text("DEMO 0.2.0", 14)
		"pause":
			_title("CONEXÃO EM ESPERA")
			_text("Jogo pausado")
			_button("CONTINUAR", resume_game)
			_button("CONTROLES", func(): open_details("controls"))
			_button("VOLUME", func(): open_details("volume"))
			_button("REINICIAR TENTATIVA", start_run)
			_button("VOLTAR AO MENU", return_to_menu)
			_text("Reiniciar ou voltar ao menu encerra a tentativa atual.", 16)
		"controls":
			_title("CONTROLES")
			_text("WASD — mover\nClique esquerdo — atacar na direção do mouse\nEspaço — atacar na direção atual\nShift / Ctrl — esquivar\n1 / 2 / 3 ou clique — instalar protocolo\nE — atravessar uma porta liberada\nEsc — pausar / continuar\nR — nova tentativa após vitória ou derrota", 20)
			_text("Avisos vermelhos: perigo. Anel ciano do chefe: contra-ataque.", 17)
			_button("VOLTAR", func(): show_page(return_page))
		"volume":
			_title("ÁUDIO")
			volume_label = _text("", 22)
			volume_slider = HSlider.new()
			volume_slider.name = "MasterVolume"
			volume_slider.min_value = 0
			volume_slider.max_value = 100
			volume_slider.step = 1
			volume_slider.custom_minimum_size = Vector2(560, 48)
			volume_slider.value = 0 if AudioServer.is_bus_mute(0) else roundf(db_to_linear(AudioServer.get_bus_volume_db(0)) * 100)
			column.add_child(volume_slider)
			volume_label.text = "Volume geral: %d%%" % volume_slider.value
			volume_slider.value_changed.connect(set_volume)
			_text("0% silencia o jogo. Sua preferência fica salva.", 17)
			_button("VOLTAR", func(): show_page(return_page))
	for child in column.get_children():
		if child is Button:
			child.grab_focus()
			break


func open_details(details: String) -> void:
	return_page = page
	show_page(details)


func _title(value: String) -> void:
	var label := _text(value, 34)
	label.add_theme_color_override("font_color", Color("2fffd5"))


func _text(value: String, font_size: int = 18) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("bed0e0"))
	column.add_child(label)
	return label


func _button(value: String, action: Callable, parent: Node = null) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(260, 46)
	button.add_theme_font_size_override("font_size", 18)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "focus", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("102235") if state == "normal" else Color("183d4a")
		if state == "focus":
			style.bg_color = Color(0,0,0,0)
		style.border_color = Color("2fffd5") if state != "normal" else Color("335065")
		style.set_border_width_all(1)
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(action)
	(column if parent == null else parent).add_child(button)
	return button


func attach_result_buttons(result: Control) -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(365, 430)
	row.add_theme_constant_override("separation", 24)
	result.add_child(row)
	_button("NOVA TENTATIVA", start_run, row)
	_button("VOLTAR AO MENU", return_to_menu, row)


func start_run() -> void:
	_change_scene("res://scenes/main.tscn")


func return_to_menu() -> void:
	_change_scene("res://scenes/menu.tscn")


func _change_scene(path: String) -> void:
	if changing_scene:
		return
	changing_scene = true
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)


func set_volume(value: float) -> void:
	value = clampf(value, 0, 100)
	AudioServer.set_bus_mute(0, value == 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
	if is_instance_valid(volume_label):
		volume_label.text = "Volume geral: %d%%" % value
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", value)
	config.save(settings_path)


func _load_volume() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var value := clampf(float(config.get_value("audio", "master_volume", 100.0)), 0, 100)
		AudioServer.set_bus_mute(0, value == 0)
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value / 100.0, 0.0001)))
