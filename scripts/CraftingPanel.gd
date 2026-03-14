extends PanelContainer
# CraftingPanel.gd — Item selector, variant picker, stitch grid, stitch/sell buttons.

@onready var item_tabs: TabContainer = $Margin/VBox/ItemTabs
@onready var stitch_grid: Control = $Margin/VBox/GridArea/StitchGrid
@onready var stitch_btn: Button = $Margin/VBox/ActionRow/StitchBtn
@onready var sell_btn: Button = $Margin/VBox/ActionRow/SellBtn
@onready var progress_label: Label = $Margin/VBox/ProgressLabel
@onready var variant_container: HBoxContainer = $Margin/VBox/VariantRow

var _variant_buttons: Array = []
var _current_item_idx: int = 0

func _ready() -> void:
	GameState.craft_progress_changed.connect(_refresh_progress)
	GameState.state_changed.connect(_refresh_buttons)
	CraftingManager.craft_completed.connect(_on_craft_complete)
	stitch_btn.pressed.connect(_on_stitch)
	sell_btn.pressed.connect(_on_sell)
	_build_item_tabs()
	_refresh_progress()
	_refresh_buttons()

func _build_item_tabs() -> void:
	var items = GameState.get_items()
	for i in range(items.size()):
		var item = items[i]
		var tab_content = VBoxContainer.new()
		tab_content.name = item["name"]
		tab_content.add_theme_constant_override("separation", 4)

		var desc = Label.new()
		desc.text = "Sale value: $%d  (+$3 per extra color)" % item["sale_value"]
		desc.add_theme_font_size_override("font_size", 11)
		desc.modulate = Color(0.75, 0.72, 0.68)
		tab_content.add_child(desc)

		item_tabs.add_child(tab_content)

	item_tabs.tab_changed.connect(_on_tab_changed)
	# Trigger initial setup
	_on_tab_changed(0)

func _on_tab_changed(tab_idx: int) -> void:
	_current_item_idx = tab_idx
	var items = GameState.get_items()
	if tab_idx >= items.size():
		return
	var item = items[tab_idx]
	_build_variant_buttons(item)
	# Auto-select first variant
	if item["variants"].size() > 0:
		_select_variant(item["id"], item["variants"][0]["id"])

func _build_variant_buttons(item: Dictionary) -> void:
	# Clear old buttons
	for btn in _variant_buttons:
		btn.queue_free()
	_variant_buttons.clear()

	for v in item["variants"]:
		var btn = Button.new()
		btn.text = v["name"]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(90, 28)
		btn.add_theme_font_size_override("font_size", 11)
		var vid = v["id"]
		var iid = item["id"]
		btn.pressed.connect(func(): _select_variant(iid, vid))
		variant_container.add_child(btn)
		_variant_buttons.append(btn)

func _select_variant(item_id: String, variant_id: String) -> void:
	CraftingManager.start_crafting(item_id, variant_id)
	# Update button states
	var items = GameState.get_items()
	for item in items:
		if item["id"] == item_id:
			for vi in range(item["variants"].size()):
				if vi < _variant_buttons.size():
					_variant_buttons[vi].button_pressed = (item["variants"][vi]["id"] == variant_id)
			break
	_refresh_progress()

func _on_stitch() -> void:
	CraftingManager.attempt_stitch()

func _on_sell() -> void:
	CraftingManager.attempt_sell()

func _on_craft_complete() -> void:
	sell_btn.modulate = Color(0.4, 0.95, 0.4)

func _refresh_progress() -> void:
	if GameState.current_item_id.is_empty():
		progress_label.text = "No item selected"
		sell_btn.modulate = Color.WHITE
		return
	var variant = GameState.get_variant(GameState.current_item_id, GameState.current_variant_id)
	if variant.is_empty():
		return
	var done = GameState.stitches_done.size()
	var total = variant["total_stitches"]
	var pct = int(float(done) / float(total) * 100) if total > 0 else 0
	progress_label.text = "Stitches: %d / %d  (%d%%)" % [done, total, pct]
	if GameState.is_craft_complete():
		progress_label.text += "  ✓ Done!"
		sell_btn.modulate = Color(0.5, 1.0, 0.5)
	else:
		sell_btn.modulate = Color.WHITE

func _refresh_buttons() -> void:
	stitch_btn.disabled = not GameState.can_stitch()
	sell_btn.disabled = not GameState.is_craft_complete()
