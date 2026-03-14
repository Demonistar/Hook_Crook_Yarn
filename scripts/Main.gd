extends Panel
# Main.gd — Root scene controller. Wires together all UI panels.

@onready var message_bar: Label = $VBox/MessageBar
@onready var grant_button: Button = $VBox/Header/HBox/GrantBtn

var _message_timer: float = 0.0

func _ready() -> void:
	GameState.message_posted.connect(_on_message)
	GameState.grant_available.connect(_on_grant_available)
	grant_button.pressed.connect(_on_grant_pressed)
	grant_button.visible = false

	# Load autosave
	if SaveManager.load_autosave():
		GameState.post_message("Game loaded from autosave.", Color(0.6, 0.9, 0.6))

func _process(delta: float) -> void:
	if _message_timer > 0:
		_message_timer -= delta
		if _message_timer <= 0:
			message_bar.text = ""
			message_bar.modulate = Color.WHITE

func _on_message(text: String, color: Color) -> void:
	message_bar.text = text
	message_bar.modulate = color
	_message_timer = 3.5

func _on_grant_available() -> void:
	grant_button.visible = true

func _on_grant_pressed() -> void:
	GameState.use_grant()
	grant_button.visible = false
