extends SceneTree

const MEMORY_PROGRESS := preload("res://scripts/memory_progress.gd")
const TEST_SAVE_PATH := "res://.godot/phase15_memory_progress_test.cfg"

var failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	MEMORY_PROGRESS.save_path_override = TEST_SAVE_PATH
	_assert(MEMORY_PROGRESS.reset_progress() == OK, "O progresso de teste deve poder ser zerado sem tocar no save real.")

	var scene := load("res://scenes/main.tscn") as PackedScene
	var first_run = scene.instantiate()
	root.add_child(first_run)
	await _settle()
	_assert(first_run.memory_fragments == 0, "Uma tentativa nova deve iniciar sem fragmentos da tentativa.")
	_assert(first_run.total_memory_fragments == 0, "Um arquivo novo deve iniciar sem fragmentos recuperados.")

	first_run.collect_memory_fragment(null)
	_assert(first_run.memory_fragments == 1, "A coleta deve aumentar o contador da tentativa.")
	_assert(first_run.total_memory_fragments == 1, "A coleta deve aumentar imediatamente o total permanente.")
	_assert(MEMORY_PROGRESS.load_total() == 1, "A coleta deve ser gravada imediatamente no arquivo de progresso.")
	_assert("TENTATIVA 01" in first_run.memory_fragment_label.text and "RECUPERADOS 001" in first_run.memory_fragment_label.text, "A HUD deve diferenciar tentativa e total recuperado.")
	first_run.queue_free()
	await _settle()

	var second_run = scene.instantiate()
	root.add_child(second_run)
	await _settle()
	_assert(second_run.memory_fragments == 0, "Reiniciar deve zerar somente os fragmentos da tentativa.")
	_assert(second_run.total_memory_fragments == 1, "Reiniciar deve carregar os fragmentos permanentes.")

	second_run.spawn_memory_fragment(second_run.player.global_position)
	await process_frame
	second_run._end_run(second_run.RunState.DEFEAT)
	await process_frame
	_assert(second_run.memory_fragments == 1, "Encerrar a tentativa deve recolher fragmentos que ainda estejam na arena.")
	_assert(second_run.total_memory_fragments == 2 and MEMORY_PROGRESS.load_total() == 2, "Fragmentos recolhidos no encerramento tambem devem permanecer salvos.")
	second_run.queue_free()
	await _settle()

	var reopened = scene.instantiate()
	root.add_child(reopened)
	await _settle()
	_assert(reopened.memory_fragments == 0 and reopened.total_memory_fragments == 2, "Fechar e reabrir deve preservar somente o total recuperado.")
	reopened.queue_free()
	await _settle()

	_assert(MEMORY_PROGRESS.reset_progress() == OK and MEMORY_PROGRESS.load_total() == 0, "A ferramenta de teste deve conseguir limpar o progresso isolado.")
	MEMORY_PROGRESS.save_path_override = ""
	await create_timer(0.2).timeout
	if not failed:
		print("PHASE15_MEMORY_PROGRESS_TEST: PASS")
	quit(1 if failed else 0)


func _settle() -> void:
	for _frame in 4:
		await process_frame


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error("PHASE15_MEMORY_PROGRESS_TEST: " + message)
