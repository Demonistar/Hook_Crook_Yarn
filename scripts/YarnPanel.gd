extends PanelContainer
# YarnPanel.gd — Yarn inventory + buy buttons, color selector.

@onready var yarn_list: VBoxContainer = $Margin/VBox/YarnList
@onready var color_label: Label = $Margin/VBox/ColorLabel

var _color_buttons: Dictionary = {}  # color_id -> Button (select)

func _ready() -> void:
	GameState.yarn_changed.connect(_refresh)
	GameState.state_changed.connect(_refresh)
	_build_ui()
	_refresh()

func _build_ui() -> void:
	for y in ItemData.YARN_CATALOG:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		# Color swatch
		var swatch = ColorRect.new()
		swatch.color = y["color"]
		swatch.custom_minimum_size = Vector2(18, 18)
		row.add_child(swatch)

		# Count label
		var lbl = Label.new()
		lbl.name = "Count_" + y["id"]
		lbl.custom_minimum_size = Vector2(60, 0)
		lbl.text = "0"
		lbl.add_theme_font_size_override("font_size", 12)
		row.add_child(lbl)

		# Buy button
		var buy = Button.new()
		buy.text = "Buy $%d" % y["price"]
		buy.custom_minimum_size = Vector2(64, 24)
		buy.add_theme_font_size_override("font_size", 11)
		buy.pressed.connect(func(): GameState.buy_yarn(y["id"]))
		row.add_child(buy)

		# Select button
		var sel = Button.new()
		sel.text = "Use"
		sel.toggle_mode = true
		sel.custom_minimum_size = Vector2(42, 24)
		sel.add_theme_font_size_override("font_size", 11)
		sel.pressed.connect(func(): _select_color(y["id"]))
		_color_buttons[y["id"]] = sel
		row.add_child(sel)

		yarn_list.add_child(row)

func _select_color(color_id: String) -> void:
	GameState.select_color(color_id)
	_update_selection()

func _update_selection() -> void:
	for cid in _color_buttons:
		var btn: Button = _color_buttons[cid]
		btn.button_pressed = (cid == GameState.selected_color)
	var yarn = ItemData.get_yarn(GameState.selected_color)
	color_label.text = "Active: " + yarn.get("name", "None")

func _refresh() -> void:
	for y in ItemData.YARN_CATALOG:
		var lbl = yarn_list.find_child("Count_" + y["id"], true, false)
		if lbl:
			lbl.text = "%s x%d" % [y["name"].replace(" Yarn", ""), GameState.yarn_inventory.get(y["id"], 0)]
	_update_selection()
