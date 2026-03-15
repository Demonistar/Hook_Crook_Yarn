extends Panel
# Main.gd — Builds the entire game UI in code. No sub-panel scripts.
# Matches HTML prototype exactly: left (yarn), center (craft), right (hooks+items+stats+log).

# ─── PALETTE ─────────────────────────────────────────────────────────────────
const C_ROOT_BG  := Color(0.22, 0.19, 0.17)
const C_HDR_BG   := Color(0.15, 0.12, 0.10)
const C_PANEL_BG := Color(0.27, 0.23, 0.20)
const C_CARD_BG  := Color(0.32, 0.27, 0.23)
const C_BORDER   := Color(0.42, 0.35, 0.29)
const C_TEXT     := Color(0.93, 0.88, 0.82)
const C_MUTED    := Color(0.62, 0.56, 0.50)
const C_GOLD     := Color(0.95, 0.82, 0.35)
const C_AMBER    := Color(0.95, 0.68, 0.30)
const C_OK       := Color(0.42, 0.82, 0.48)
const C_WARN     := Color(0.95, 0.70, 0.25)
const C_BAD      := Color(0.92, 0.38, 0.38)

# ─── UI REFS ─────────────────────────────────────────────────────────────────
var _money_lbl: Label
var _active_yarn_lbl: Label
var _grant_btn: Button
var _message_lbl: Label
var _msg_timer: float = 0.0

# Left panel
var _yarn_count_lbls: Dictionary = {}   # color_id -> Label
var _yarn_swatch_btns: Dictionary = {}  # color_id -> Button

# Center panel
var _project_name_lbl: Label
var _variant_lbl: Label
var _variant_container: HBoxContainer
var _variant_btns: Array = []
var _progress_bar: ProgressBar
var _progress_lbl: Label
var _stitch_grid: Control              # StitchGrid instance
var _stitch_btn: Button
var _sell_btn: Button
var _sale_lbl: Label

# Right panel — hooks
var _dur_bar: ProgressBar
var _dur_lbl: Label
var _hook_title_lbls: Dictionary = {}
var _hook_buy_btns: Dictionary = {}
var _hook_equip_btns: Dictionary = {}

# Right panel — items
var _item_select_btns: Dictionary = {}

# Right panel — stats + log
var _run_stats_lbl: Label
var _life_stats_lbl: Label
var _log_lbl: Label

# ─── READY ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	_apply_root_style()
	_build_ui()

	GameState.money_changed.connect(func(v): _money_lbl.text = "$%d" % v)
	GameState.yarn_changed.connect(_refresh_yarn)
	GameState.hook_changed.connect(_refresh_hooks)
	GameState.craft_progress_changed.connect(_refresh_craft)
	GameState.state_changed.connect(_on_state_changed)
	GameState.item_sold.connect(func(_n, _v): _refresh_stats())
	GameState.grant_available.connect(func(): _grant_btn.visible = true)
	GameState.message_posted.connect(_on_message)

	if SaveManager.load_autosave():
		_on_message("Autosave loaded.", C_OK)

	# Auto-start first item if nothing is active
	if GameState.current_item_id.is_empty():
		var items = GameState.get_items()
		if items.size() > 0:
			CraftingManager.start_crafting(items[0]["id"], items[0]["variants"][0]["id"])

	_full_refresh()

func _apply_root_style() -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = C_ROOT_BG
	add_theme_stylebox_override("panel", s)

func _process(delta: float) -> void:
	if _msg_timer > 0.0:
		_msg_timer -= delta
		if _msg_timer <= 0.0:
			_message_lbl.text = ""

# ─── BUILD UI ────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_vbox.add_theme_constant_override("separation", 0)
	add_child(root_vbox)

	_build_header(root_vbox)
	_build_body(root_vbox)
	_build_message_bar(root_vbox)

# ── HEADER ────────────────────────────────────────────────────────────────────
func _build_header(parent: Control) -> void:
	var pc := PanelContainer.new()
	_apply_style(pc, C_HDR_BG, C_AMBER, 0, 2, 0, 0)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)

	var hb := _hbox(pc, 8)
	hb.add_theme_constant_override("margin_left", 10)
	hb.add_theme_constant_override("margin_right", 10)

	_mk_label(hb, "Hook, Crook & Yarn", 16, C_AMBER)
	_spacer(hb)

	_money_lbl = _mk_label(hb, "$140", 18, C_GOLD)
	_active_yarn_lbl = _mk_label(hb, "Active: Red Yarn", 12, C_TEXT)

	var save_btn := _mk_btn(hb, "Export Save", 11)
	save_btn.pressed.connect(_on_export)
	var load_btn := _mk_btn(hb, "Import Save", 11)
	load_btn.pressed.connect(_on_import)
	var so_btn := _mk_btn(hb, "Start Over", 11)
	so_btn.pressed.connect(_on_start_over)
	var fr_btn := _mk_btn(hb, "Full Reset", 11)
	fr_btn.modulate = Color(1.0, 0.7, 0.7)
	fr_btn.pressed.connect(_on_full_reset)

	_grant_btn = _mk_btn(hb, "Emergency Grant", 11)
	_grant_btn.visible = false
	_grant_btn.modulate = Color(0.6, 1.0, 0.7)
	_grant_btn.pressed.connect(func(): GameState.use_grant(); _grant_btn.visible = false)

# ── BODY ──────────────────────────────────────────────────────────────────────
func _build_body(parent: Control) -> void:
	var margin := MarginContainer.new()
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6)
	parent.add_child(margin)

	var hb := HBoxContainer.new()
	hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_theme_constant_override("separation", 6)
	margin.add_child(hb)

	_build_left_panel(hb)
	_build_center_panel(hb)
	_build_right_panel(hb)

# ── LEFT PANEL — Yarn Shop + Swatches ─────────────────────────────────────────
func _build_left_panel(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(230, 0)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var outer := _panel_vbox(scroll, C_PANEL_BG, C_BORDER, 8)

	_section_title(outer, "Yarn Shop & Inventory")

	# One row per yarn: swatch color + name + count + Buy button
	for y in ItemData.YARN_CATALOG:
		var card := _card_hbox(outer)

		var sw := ColorRect.new()
		sw.color = y["color"]
		sw.custom_minimum_size = Vector2(16, 16)
		card.add_child(sw)

		var name_lbl := _mk_label(card, y["name"].replace(" Yarn", ""), 11, C_TEXT)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_contents = true

		var cnt := _mk_label(card, "x0", 11, C_MUTED)
		cnt.custom_minimum_size = Vector2(30, 0)
		_yarn_count_lbls[y["id"]] = cnt

		var buy := _mk_btn(card, "Buy $%d" % y["price"], 10)
		buy.custom_minimum_size = Vector2(58, 22)
		var yid = y["id"]
		buy.pressed.connect(func(): GameState.buy_yarn(yid))
		card.add_child(buy)

	_section_title(outer, "Active Color")

	var swatch_grid := GridContainer.new()
	swatch_grid.columns = 4
	swatch_grid.add_theme_constant_override("h_separation", 4)
	swatch_grid.add_theme_constant_override("v_separation", 4)
	outer.add_child(swatch_grid)

	for y in ItemData.YARN_CATALOG:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(46, 36)
		btn.add_theme_font_size_override("font_size", 9)
		var sty_norm := StyleBoxFlat.new()
		sty_norm.bg_color = y["color"]
		sty_norm.border_width_left = 2
		sty_norm.border_width_top = 2
		sty_norm.border_width_right = 2
		sty_norm.border_width_bottom = 2
		sty_norm.border_color = y["color"].darkened(0.3)
		sty_norm.corner_radius_top_left = 6
		sty_norm.corner_radius_top_right = 6
		sty_norm.corner_radius_bottom_right = 6
		sty_norm.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", sty_norm)
		btn.add_theme_stylebox_override("hover", sty_norm)
		btn.add_theme_stylebox_override("pressed", sty_norm)
		btn.add_theme_color_override("font_color", Color.BLACK if y["color"].get_luminance() > 0.5 else Color.WHITE)
		btn.text = y["id"].capitalize()
		var yid = y["id"]
		btn.pressed.connect(func(): _select_color(yid))
		swatch_grid.add_child(btn)
		_yarn_swatch_btns[y["id"]] = btn

# ── CENTER PANEL — Crafting ───────────────────────────────────────────────────
func _build_center_panel(parent: Control) -> void:
	var pc := PanelContainer.new()
	_apply_style(pc, C_PANEL_BG, C_BORDER)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 8)
	pc.add_child(margin)

	var vb := VBoxContainer.new()
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	margin.add_child(vb)

	_section_title(vb, "Current Project")

	# Project name + variant label
	_project_name_lbl = _mk_label(vb, "No project selected", 13, C_AMBER)
	_variant_lbl = _mk_label(vb, "Variant: --", 11, C_MUTED)

	# Variant selector row
	_variant_container = HBoxContainer.new()
	_variant_container.add_theme_constant_override("separation", 4)
	vb.add_child(_variant_container)

	# Progress bar + label
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 14)
	_progress_bar.max_value = 1.0
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	vb.add_child(_progress_bar)

	_progress_lbl = _mk_label(vb, "Stitches: 0 / 0", 11, C_MUTED)

	# Stitch grid area — fills remaining space
	var grid_panel := Panel.new()
	grid_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var gp_sty := StyleBoxFlat.new()
	gp_sty.bg_color = Color(0.16, 0.13, 0.11)
	gp_sty.corner_radius_top_left = 6
	gp_sty.corner_radius_top_right = 6
	gp_sty.corner_radius_bottom_right = 6
	gp_sty.corner_radius_bottom_left = 6
	grid_panel.add_theme_stylebox_override("panel", gp_sty)
	vb.add_child(grid_panel)

	# StitchGrid fills the grid panel
	_stitch_grid = get_node("StitchGridTemplate").duplicate()
	_stitch_grid.visible = true
	_stitch_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grid_panel.add_child(_stitch_grid)

	# Action row
	var act_row := HBoxContainer.new()
	act_row.add_theme_constant_override("separation", 8)
	vb.add_child(act_row)

	_stitch_btn = _mk_btn(act_row, "Stitch!", 15)
	_stitch_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stitch_btn.custom_minimum_size = Vector2(0, 38)
	_stitch_btn.pressed.connect(_on_stitch)

	_sell_btn = _mk_btn(act_row, "Sell Item", 15)
	_sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sell_btn.custom_minimum_size = Vector2(0, 38)
	_sell_btn.disabled = true
	_sell_btn.pressed.connect(_on_sell)

	_sale_lbl = _mk_label(vb, "", 11, C_OK)

# ── RIGHT PANEL — Hooks, Items, Stats, Log ─────────────────────────────────────
func _build_right_panel(parent: Control) -> void:
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(268, 0)
	scroll.size_flags_horizontal = Control.SIZE_SHRINK_END
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(scroll)

	var outer := _panel_vbox(scroll, C_PANEL_BG, C_BORDER, 8)

	# ── Hooks ───────────────────────────────────────
	_section_title(outer, "Hooks / Tools")

	_dur_lbl = _mk_label(outer, "Basic Hook: 120 / 120", 11, C_MUTED)
	_dur_bar = ProgressBar.new()
	_dur_bar.custom_minimum_size = Vector2(0, 12)
	_dur_bar.max_value = 1.0
	_dur_bar.value = 1.0
	_dur_bar.show_percentage = false
	outer.add_child(_dur_bar)

	for h in ItemData.HOOK_CATALOG:
		var card := _card_vbox(outer)
		var title_row := HBoxContainer.new()
		card.add_child(title_row)

		var title := _mk_label(title_row, h["name"], 12, C_TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_hook_title_lbls[h["id"]] = title

		var info := _mk_label(card, "Power %d  |  Repair $%d  |  Price $%d" % [h["stitch_power"], h["repair_cost"], h["price"]], 10, C_MUTED)
		info.autowrap_mode = TextServer.AUTOWRAP_OFF

		var btn_row := HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 4)
		card.add_child(btn_row)

		var buy := _mk_btn(btn_row, "Buy $%d" % h["price"], 11)
		buy.custom_minimum_size = Vector2(72, 24)
		var hid = h["id"]
		buy.pressed.connect(func(): GameState.buy_hook(hid))
		_hook_buy_btns[h["id"]] = buy

		var repair := _mk_btn(btn_row, "Repair $%d" % h["repair_cost"], 11)
		repair.custom_minimum_size = Vector2(80, 24)
		repair.pressed.connect(func(): GameState.repair_hook(hid))

		var equip := _mk_btn(btn_row, "Equip", 11)
		equip.custom_minimum_size = Vector2(52, 24)
		equip.pressed.connect(func(): GameState.equip_hook(hid))
		_hook_equip_btns[h["id"]] = equip

	# ── Choose Item ──────────────────────────────────
	_section_title(outer, "Choose Item")

	for item in GameState.get_items():
		var card := _card_vbox(outer)
		var title_row := HBoxContainer.new()
		card.add_child(title_row)
		_mk_label(title_row, item["name"], 12, C_TEXT).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_mk_label(title_row, "$%d" % item["sale_value"], 11, C_GOLD)

		var variant_names: Array = []
		for v in item["variants"]:
			variant_names.append(v["name"])
		var vnames_lbl := _mk_label(card, ", ".join(variant_names), 10, C_MUTED)
		vnames_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		var sel := _mk_btn(card, "Select", 11)
		sel.custom_minimum_size = Vector2(0, 24)
		var iid = item["id"]
		sel.pressed.connect(func(): _select_item(iid))
		_item_select_btns[item["id"]] = sel

	# ── Run Stats ────────────────────────────────────
	_section_title(outer, "Current Run Stats")
	var run_card := _card_vbox(outer)
	_run_stats_lbl = _mk_label(run_card, "", 11, C_TEXT)
	_run_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF

	# ── Lifetime Stats ───────────────────────────────
	_section_title(outer, "Lifetime Stats")
	var life_card := _card_vbox(outer)
	_life_stats_lbl = _mk_label(life_card, "", 11, C_TEXT)
	_life_stats_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF

	# ── Log ──────────────────────────────────────────
	_section_title(outer, "Message Log")
	var log_card := _card_vbox(outer)
	_log_lbl = _mk_label(log_card, "Game started.", 10, C_MUTED)
	_log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# ── MESSAGE BAR ───────────────────────────────────────────────────────────────
func _build_message_bar(parent: Control) -> void:
	_message_lbl = _mk_label(parent, "", 12, C_TEXT)
	_message_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_lbl.custom_minimum_size = Vector2(0, 20)

# ─── REFRESH FUNCTIONS ────────────────────────────────────────────────────────
func _full_refresh() -> void:
	_money_lbl.text = "$%d" % GameState.money
	_refresh_yarn()
	_refresh_hooks()
	_refresh_craft()
	_refresh_stats()
	_refresh_item_buttons()

func _on_state_changed() -> void:
	_refresh_stats()
	_update_stitch_sell_btns()
	_refresh_item_buttons()
	if GameState.check_grant_available():
		_grant_btn.visible = true

func _refresh_yarn() -> void:
	for cid in _yarn_count_lbls:
		var lbl: Label = _yarn_count_lbls[cid]
		lbl.text = "x%d" % GameState.yarn_inventory.get(cid, 0)
	_update_swatch_selection()
	_update_active_yarn_label()

func _update_swatch_selection() -> void:
	for cid in _yarn_swatch_btns:
		var btn: Button = _yarn_swatch_btns[cid]
		var yarn = ItemData.get_yarn(cid)
		var sty := StyleBoxFlat.new()
		sty.bg_color = yarn["color"]
		sty.corner_radius_top_left = 6
		sty.corner_radius_top_right = 6
		sty.corner_radius_bottom_right = 6
		sty.corner_radius_bottom_left = 6
		if cid == GameState.selected_color:
			sty.border_width_left = 3
			sty.border_width_top = 3
			sty.border_width_right = 3
			sty.border_width_bottom = 3
			sty.border_color = Color.WHITE
		else:
			sty.border_width_left = 2
			sty.border_width_top = 2
			sty.border_width_right = 2
			sty.border_width_bottom = 2
			sty.border_color = yarn["color"].darkened(0.3)
		btn.add_theme_stylebox_override("normal", sty)
		btn.add_theme_stylebox_override("hover", sty)
		btn.add_theme_stylebox_override("pressed", sty)
		var cnt = GameState.yarn_inventory.get(cid, 0)
		btn.text = "%s\n%d" % [cid.capitalize(), cnt]

func _update_active_yarn_label() -> void:
	var yarn = ItemData.get_yarn(GameState.selected_color)
	_active_yarn_lbl.text = "Active: %s" % yarn.get("name", "None")

func _refresh_hooks() -> void:
	for h in ItemData.HOOK_CATALOG:
		var hid = h["id"]
		var hs = GameState.hooks.get(hid, {})
		var owned: bool = hs.get("owned", false)
		var dur: float = hs.get("durability", 0.0)
		var is_active: bool = (GameState.active_hook_id == hid)

		if _hook_title_lbls.has(hid):
			var lbl: Label = _hook_title_lbls[hid]
			lbl.text = h["name"] + (" [EQUIPPED]" if is_active else "")
			lbl.modulate = C_GOLD if is_active else C_TEXT

		if _hook_buy_btns.has(hid):
			var btn: Button = _hook_buy_btns[hid]
			btn.text = "Owned" if owned else "Buy $%d" % h["price"]
			btn.disabled = owned

		if _hook_equip_btns.has(hid):
			var btn: Button = _hook_equip_btns[hid]
			btn.disabled = not owned or is_active
			btn.text = "Equipped" if is_active else "Equip"

	# Durability bar for active hook
	var ah = GameState.get_active_hook()
	var ahs = GameState.get_active_hook_state()
	if ah.is_empty():
		_dur_lbl.text = "No hook equipped"
		_dur_bar.value = 0.0
	else:
		var dur_val: float = ahs.get("durability", 0.0)
		var max_dur: int = ah.get("max_durability", 1)
		_dur_lbl.text = "%s: %.0f / %d" % [ah["name"], dur_val, max_dur]
		_dur_bar.value = dur_val / float(max_dur)
		var pct = _dur_bar.value
		if pct > 0.6:
			_dur_bar.modulate = C_OK
		elif pct > 0.25:
			_dur_bar.modulate = C_WARN
		else:
			_dur_bar.modulate = C_BAD

func _refresh_craft() -> void:
	if GameState.current_item_id.is_empty():
		_project_name_lbl.text = "No project selected"
		_variant_lbl.text = "Variant: --"
		_progress_lbl.text = "Stitches: 0 / 0"
		_progress_bar.value = 0.0
		_sale_lbl.text = ""
		_update_stitch_sell_btns()
		return

	var item = GameState.get_item(GameState.current_item_id)
	var variant = GameState.get_variant(GameState.current_item_id, GameState.current_variant_id)
	if item.is_empty() or variant.is_empty():
		return

	_project_name_lbl.text = "%s — $%d" % [item["name"], item["sale_value"]]
	_variant_lbl.text = "Variant: %s" % variant["name"]

	var done: int = GameState.stitches_done.size()
	var total: int = variant["total_stitches"]
	_progress_lbl.text = "Stitches: %d / %d" % [done, total]
	_progress_bar.value = float(done) / float(total) if total > 0 else 0.0

	if GameState.is_craft_complete():
		var colors_used = GameState.colors_used.size()
		var bonus = max(0, colors_used - 1) * GameState.MULTI_COLOR_BONUS
		_sale_lbl.text = "Ready to sell! $%d base + $%d color bonus" % [item["sale_value"], bonus]
		_sale_lbl.modulate = C_OK
	else:
		_sale_lbl.text = ""

	_rebuild_variant_buttons(item)
	_update_stitch_sell_btns()

	# Trigger stitch grid redraw
	if _stitch_grid:
		_stitch_grid.queue_redraw()

func _rebuild_variant_buttons(item: Dictionary) -> void:
	# Only rebuild if item changed
	for btn in _variant_btns:
		if is_instance_valid(btn):
			btn.queue_free()
	_variant_btns.clear()

	for v in item["variants"]:
		var btn := _mk_btn(_variant_container, v["name"], 10)
		btn.custom_minimum_size = Vector2(70, 22)
		var iid = item["id"]
		var vid = v["id"]
		btn.pressed.connect(func(): _switch_variant(iid, vid))
		if v["id"] == GameState.current_variant_id:
			btn.modulate = C_GOLD
		_variant_btns.append(btn)

func _switch_variant(item_id: String, variant_id: String) -> void:
	if GameState.stitches_done.size() > 0:
		GameState.post_message("Clear current work first (start a new item to switch variant).", C_WARN)
		return
	CraftingManager.start_crafting(item_id, variant_id)
	_rebuild_variant_buttons(GameState.get_item(item_id))

func _update_stitch_sell_btns() -> void:
	_stitch_btn.disabled = not GameState.can_stitch()
	_sell_btn.disabled = not GameState.is_craft_complete()
	if GameState.is_craft_complete():
		_sell_btn.modulate = C_OK
	else:
		_sell_btn.modulate = C_TEXT

func _refresh_item_buttons() -> void:
	for iid in _item_select_btns:
		var btn: Button = _item_select_btns[iid]
		var is_selected = (GameState.current_item_id == iid)
		btn.text = "Selected" if is_selected else "Select"
		btn.disabled = is_selected
		btn.modulate = C_GOLD if is_selected else C_TEXT

func _refresh_stats() -> void:
	var rs_text := ""
	rs_text += "Money on hand:  $%d\n" % GameState.money
	rs_text += "Items sold:      %d\n" % GameState.items_sold_this_run
	rs_text += "Run earnings:   $%d" % GameState.money_earned_this_run
	_run_stats_lbl.text = rs_text

	var ls_text := ""
	ls_text += "Total items sold: %d\n" % GameState.lifetime_items_sold
	ls_text += "Total earnings:  $%d\n" % GameState.lifetime_money_earned
	ls_text += "Total stitches:   %d\n" % GameState.lifetime_stitches
	ls_text += "Total runs:       %d" % GameState.lifetime_runs
	_life_stats_lbl.text = ls_text

# ─── EVENT HANDLERS ───────────────────────────────────────────────────────────
func _select_color(color_id: String) -> void:
	GameState.select_color(color_id)
	_refresh_yarn()

func _select_item(item_id: String) -> void:
	if GameState.current_item_id == item_id:
		return
	if GameState.stitches_done.size() > 0 and not GameState.is_craft_complete():
		GameState.post_message("Finish or sell the current item first!", C_WARN)
		return
	var item = GameState.get_item(item_id)
	CraftingManager.start_crafting(item_id, item["variants"][0]["id"])
	_refresh_item_buttons()
	_rebuild_variant_buttons(item)

func _on_stitch() -> void:
	CraftingManager.attempt_stitch()

func _on_sell() -> void:
	CraftingManager.attempt_sell()

func _on_message(text: String, color: Color) -> void:
	_message_lbl.text = text
	_message_lbl.modulate = color
	_msg_timer = 3.5
	# Append to log
	if _log_lbl:
		var old = _log_lbl.text
		var lines = old.split("\n")
		lines.insert(0, text)
		if lines.size() > 12:
			lines = lines.slice(0, 12)
		_log_lbl.text = "\n".join(lines)

func _on_start_over() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Start Over? Resets run but keeps lifetime stats."
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(func(): GameState.start_over(); d.queue_free(); _full_refresh())
	d.canceled.connect(func(): d.queue_free())

func _on_full_reset() -> void:
	var d := ConfirmationDialog.new()
	d.dialog_text = "Full Reset? This wipes EVERYTHING including lifetime stats. Cannot be undone."
	add_child(d)
	d.popup_centered()
	d.confirmed.connect(func(): GameState.full_reset(); d.queue_free(); _full_refresh())
	d.canceled.connect(func(): d.queue_free())

func _on_export() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	dialog.current_file = "hook_crook_save.json"
	add_child(dialog)
	dialog.popup_centered(Vector2i(700, 450))
	dialog.file_selected.connect(func(path): SaveManager.export_to_file(path); dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_import() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json"])
	add_child(dialog)
	dialog.popup_centered(Vector2i(700, 450))
	dialog.file_selected.connect(func(path): SaveManager.import_from_file(path); dialog.queue_free(); _full_refresh())
	dialog.canceled.connect(func(): dialog.queue_free())

func _on_grant_available() -> void:
	_grant_btn.visible = true

# ─── UI FACTORY HELPERS ───────────────────────────────────────────────────────
func _mk_label(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func _mk_btn(parent: Control, text: String, font_size: int) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", font_size)
	parent.add_child(btn)
	return btn

func _hbox(parent: Control, separation: int = 6) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", separation)
	parent.add_child(hb)
	return hb

func _spacer(parent: Control) -> Control:
	var s := Control.new()
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(s)
	return s

func _apply_style(node: Control, bg: Color, border: Color,
		bl: int = 1, bt: int = 1, br: int = 1, bb: int = 1) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_width_left = bl
	s.border_width_top = bt
	s.border_width_right = br
	s.border_width_bottom = bb
	s.border_color = border
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_right = 6
	s.corner_radius_bottom_left = 6
	s.content_margin_left = 6.0
	s.content_margin_top = 6.0
	s.content_margin_right = 6.0
	s.content_margin_bottom = 6.0
	node.add_theme_stylebox_override("panel", s)

# Creates a PanelContainer+MarginContainer+VBoxContainer triple,
# returns the VBoxContainer so callers can add children directly.
func _panel_vbox(parent: Control, bg: Color, border: Color, pad: int = 8) -> VBoxContainer:
	var pc := PanelContainer.new()
	_apply_style(pc, bg, border)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(pc)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, pad)
	pc.add_child(margin)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	margin.add_child(vb)
	return vb

func _section_title(parent: Control, text: String) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)
	var lbl := _mk_label(parent, text, 13, C_AMBER)
	lbl.add_theme_font_size_override("font_size", 13)

func _card_hbox(parent: Control) -> HBoxContainer:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_CARD_BG
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4
	s.content_margin_left = 6.0
	s.content_margin_top = 4.0
	s.content_margin_right = 6.0
	s.content_margin_bottom = 4.0
	pc.add_theme_stylebox_override("panel", s)
	parent.add_child(pc)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	pc.add_child(hb)
	return hb

func _card_vbox(parent: Control) -> VBoxContainer:
	var pc := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = C_CARD_BG
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_right = 4
	s.corner_radius_bottom_left = 4
	s.content_margin_left = 6.0
	s.content_margin_top = 4.0
	s.content_margin_right = 6.0
	s.content_margin_bottom = 4.0
	pc.add_theme_stylebox_override("panel", s)
	parent.add_child(pc)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 3)
	pc.add_child(vb)
	return vb
