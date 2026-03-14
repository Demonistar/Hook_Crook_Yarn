extends PanelContainer
# HeaderPanel.gd — Top bar: title, money display, save/load buttons.

@onready var money_label: Label = $HBox/MoneyLabel
@onready var save_btn: Button = $HBox/SaveBtn
@onready var load_btn: Button = $HBox/LoadBtn
@onready var start_over_btn: Button = $HBox/StartOverBtn
@onready var full_reset_btn: Button = $HBox/FullResetBtn

func _ready() -> void:
	GameState.money_changed.connect(_on_money_changed)
	save_btn.pressed.connect(_on_save)
	load_btn.pressed.connect(_on_load)
	start_over_btn.pressed.connect(_on_start_over)
	full_reset_btn.pressed.connect(_on_full_reset)
	_on_money_changed(GameState.money)

func _on_money_changed(val: int) -> void:
	money_label.text = "$%d" % val

func _on_save() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.filters = ["*.json ; JSON Save Files"]
	dialog.current_file = "hook_crook_save.json"
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))
	dialog.file_selected.connect(func(path): SaveManager.export_to_file(path); dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_load() -> void:
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = ["*.json ; JSON Save Files"]
	add_child(dialog)
	dialog.popup_centered(Vector2i(600, 400))
	dialog.file_selected.connect(func(path): SaveManager.import_from_file(path); dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_start_over() -> void:
	var c = _confirm("Start Over? (Keeps lifetime stats)")
	c.confirmed.connect(func(): GameState.start_over())

func _on_full_reset() -> void:
	var c = _confirm("Full Reset? This wipes EVERYTHING including lifetime stats!")
	c.confirmed.connect(func(): GameState.full_reset())

func _confirm(msg: String) -> ConfirmationDialog:
	var d = ConfirmationDialog.new()
	d.dialog_text = msg
	add_child(d)
	d.popup_centered()
	d.canceled.connect(func(): d.queue_free())
	d.confirmed.connect(func(): d.queue_free())
	return d
