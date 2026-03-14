extends PanelContainer
# ToolsPanel.gd — Hook management (buy, repair, equip) and durability display.

@onready var hooks_container: VBoxContainer = $Margin/VBox/HooksContainer
@onready var dur_bar: ProgressBar = $Margin/VBox/DurBar
@onready var dur_label: Label = $Margin/VBox/DurLabel

func _ready() -> void:
	GameState.hook_changed.connect(_refresh)
	GameState.state_changed.connect(_refresh)
	_build_hooks_ui()
	_refresh()

func _build_hooks_ui() -> void:
	for h in ItemData.HOOK_CATALOG:
		var section = VBoxContainer.new()
		section.name = "Hook_" + h["id"]
		section.add_theme_constant_override("separation", 3)

		var title = Label.new()
		title.name = "Title"
		title.text = h["name"]
		title.add_theme_font_size_override("font_size", 13)
		section.add_child(title)

		var info = Label.new()
		info.name = "Info"
		info.text = "Power: %d  |  Dur loss: %.2f" % [h["stitch_power"], h["durability_loss"]]
		info.add_theme_font_size_override("font_size", 10)
		info.modulate = Color(0.7, 0.65, 0.6)
		section.add_child(info)

		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)

		var buy = Button.new()
		buy.name = "BuyBtn"
		buy.text = "Buy $%d" % h["price"]
		buy.custom_minimum_size = Vector2(72, 26)
		buy.add_theme_font_size_override("font_size", 11)
		buy.pressed.connect(func(): GameState.buy_hook(h["id"]))
		btn_row.add_child(buy)

		var repair = Button.new()
		repair.name = "RepairBtn"
		repair.text = "Repair $%d" % h["repair_cost"]
		repair.custom_minimum_size = Vector2(80, 26)
		repair.add_theme_font_size_override("font_size", 11)
		repair.pressed.connect(func(): GameState.repair_hook(h["id"]))
		btn_row.add_child(repair)

		var equip = Button.new()
		equip.name = "EquipBtn"
		equip.text = "Equip"
		equip.custom_minimum_size = Vector2(56, 26)
		equip.add_theme_font_size_override("font_size", 11)
		equip.pressed.connect(func(): GameState.equip_hook(h["id"]))
		btn_row.add_child(equip)

		section.add_child(btn_row)

		var sep = HSeparator.new()
		sep.custom_minimum_size = Vector2(0, 4)
		section.add_child(sep)

		hooks_container.add_child(section)

func _refresh() -> void:
	for h in ItemData.HOOK_CATALOG:
		var section = hooks_container.find_child("Hook_" + h["id"], true, false)
		if not section:
			continue
		var state = GameState.hooks.get(h["id"], {})
		var owned: bool = state.get("owned", false)
		var dur: float = state.get("durability", 0.0)
		var is_active: bool = (GameState.active_hook_id == h["id"])

		var title: Label = section.find_child("Title", true, false)
		if title:
			title.text = h["name"] + (" ★ EQUIPPED" if is_active else "")
			title.modulate = Color(0.95, 0.75, 0.30) if is_active else Color.WHITE

		var buy_btn: Button = section.find_child("BuyBtn", true, false)
		if buy_btn:
			buy_btn.disabled = owned
			buy_btn.text = "Owned" if owned else "Buy $%d" % h["price"]

		var repair_btn: Button = section.find_child("RepairBtn", true, false)
		if repair_btn:
			repair_btn.disabled = not owned

		var equip_btn: Button = section.find_child("EquipBtn", true, false)
		if equip_btn:
			equip_btn.disabled = not owned or is_active

	# Update durability bar for active hook
	var pct = GameState.get_hook_durability_pct()
	dur_bar.value = pct * 100.0
	var ah = GameState.get_active_hook()
	var ahs = GameState.get_active_hook_state()
	if ah.is_empty():
		dur_label.text = "No hook equipped"
	else:
		var dur_val = ahs.get("durability", 0.0)
		var max_dur = ah.get("max_durability", 100)
		dur_label.text = "%s: %.0f / %d" % [ah["name"], dur_val, max_dur]
	# Color bar
	if pct > 0.6:
		dur_bar.modulate = Color(0.4, 0.8, 0.4)
	elif pct > 0.25:
		dur_bar.modulate = Color(0.9, 0.75, 0.2)
	else:
		dur_bar.modulate = Color(0.9, 0.3, 0.3)
