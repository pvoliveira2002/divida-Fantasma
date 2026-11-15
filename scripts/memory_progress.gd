extends RefCounted

const SAVE_VERSION := 1
const DEFAULT_SAVE_PATH := "user://memory_progress.cfg"
const HEADLESS_SAVE_PATH := "res://.godot/memory_progress_test.cfg"

static var save_path_override := ""


static func get_save_path() -> String:
	if not save_path_override.is_empty():
		return save_path_override
	if DisplayServer.get_name() == "headless":
		return HEADLESS_SAVE_PATH
	return DEFAULT_SAVE_PATH


static func load_total() -> int:
	var config := ConfigFile.new()
	if config.load(get_save_path()) != OK:
		return 0
	return maxi(0, int(config.get_value("memory", "total_fragments", 0)))


static func save_total(total: int) -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("memory", "total_fragments", maxi(0, total))
	return config.save(get_save_path())


static func reset_progress() -> Error:
	return save_total(0)
