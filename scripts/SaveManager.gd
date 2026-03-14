extends Node
# SaveManager.gd — Autosave, file export, and file import. Autoload as "SaveManager".

const SAVE_PATH := "user://autosave.json"

func autosave() -> void:
	var data = GameState.to_save_dict()
	var json_str = JSON.stringify(data, "\t")
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(json_str)
		f.close()

func load_autosave() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var text = f.get_as_text()
	f.close()
	return _parse_and_load(text)

func export_to_file(path: String) -> bool:
	var data = GameState.to_save_dict()
	var json_str = JSON.stringify(data, "\t")
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		GameState.post_message("Export failed: could not open file.", Color(0.9, 0.3, 0.3))
		return false
	f.store_string(json_str)
	f.close()
	GameState.post_message("Game exported!", Color(0.4, 0.8, 0.4))
	return true

func import_from_file(path: String) -> bool:
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		GameState.post_message("Import failed: could not open file.", Color(0.9, 0.3, 0.3))
		return false
	var text = f.get_as_text()
	f.close()
	if _parse_and_load(text):
		GameState.post_message("Game imported!", Color(0.4, 0.8, 0.4))
		autosave()
		return true
	GameState.post_message("Import failed: invalid save data.", Color(0.9, 0.3, 0.3))
	return false

func _parse_and_load(text: String) -> bool:
	var result = JSON.parse_string(text)
	if result == null:
		return false
	if not result is Dictionary:
		return false
	GameState.load_from_dict(result)
	return true
