extends Node
# GameState.gd — Central game state. Autoload as "GameState".
# All economy, inventory, crafting progress, and stats live here.

signal state_changed()
signal money_changed(new_val: int)
signal yarn_changed()
signal hook_changed()
signal craft_progress_changed()
signal item_sold(item_name: String, value: int)
signal grant_available()
signal message_posted(text: String, color: Color)

# ─── CONSTANTS ───────────────────────────────────────────────────────────────
const STARTING_MONEY := 140
const MULTI_COLOR_BONUS := 3
const GRANT_MONEY := 12
const GRANT_YARN := 8       # units of red yarn
const GRANT_HOOK_DUR := 18
const SAVE_PATH := "user://autosave.json"

# ─── RUN STATE ───────────────────────────────────────────────────────────────
var money: int = STARTING_MONEY
var yarn_inventory: Dictionary = {}   # { "red": 0, "orange": 0, ... }
var hooks: Dictionary = {}            # { "basic": {owned, durability}, ... }
var active_hook_id: String = ""
var grant_used: bool = false
var items_sold_this_run: int = 0
var money_earned_this_run: int = 0

# Current crafting session
var current_item_id: String = ""
var current_variant_id: String = ""
var stitches_done: Array = []        # Array of {row, col, color_id} in path order
var colors_used: Array = []          # unique color ids used in current craft
var selected_color: String = "red"

# ─── LIFETIME STATS ──────────────────────────────────────────────────────────
var lifetime_items_sold: int = 0
var lifetime_money_earned: int = 0
var lifetime_stitches: int = 0
var lifetime_runs: int = 0

# ─── CACHED ITEM DATA ────────────────────────────────────────────────────────
var _items_cache: Array = []

func _ready() -> void:
	_init_yarn()
	_init_hooks()
	_build_items_cache()

func _init_yarn() -> void:
	for y in ItemData.YARN_CATALOG:
		yarn_inventory[y["id"]] = 0

func _init_hooks() -> void:
	for h in ItemData.HOOK_CATALOG:
		hooks[h["id"]] = {"owned": false, "durability": h["max_durability"]}
	# Player starts with basic hook
	hooks["basic"]["owned"] = true
	active_hook_id = "basic"

func _build_items_cache() -> void:
	_items_cache = ItemData.build_items_with_paths()

# ─── ACCESSORS ───────────────────────────────────────────────────────────────
func get_items() -> Array:
	return _items_cache

func get_item(item_id: String) -> Dictionary:
	for it in _items_cache:
		if it["id"] == item_id:
			return it
	return {}

func get_variant(item_id: String, variant_id: String) -> Dictionary:
	var item = get_item(item_id)
	if item.is_empty():
		return {}
	for v in item["variants"]:
		if v["id"] == variant_id:
			return v
	return {}

func get_active_hook() -> Dictionary:
	if active_hook_id.is_empty():
		return {}
	return ItemData.get_hook(active_hook_id)

func get_active_hook_state() -> Dictionary:
	if active_hook_id.is_empty():
		return {}
	return hooks[active_hook_id]

func get_hook_durability_pct() -> float:
	var h = get_active_hook()
	var hs = get_active_hook_state()
	if h.is_empty():
		return 0.0
	return float(hs["durability"]) / float(h["max_durability"])

func total_yarn() -> int:
	var total := 0
	for v in yarn_inventory.values():
		total += v
	return total

func can_stitch() -> bool:
	if active_hook_id.is_empty():
		return false
	var hs = get_active_hook_state()
	if hs["durability"] <= 0:
		return false
	if current_item_id.is_empty():
		return false
	if yarn_inventory.get(selected_color, 0) <= 0:
		return false
	var variant = get_variant(current_item_id, current_variant_id)
	if variant.is_empty():
		return false
	return stitches_done.size() < variant["total_stitches"]

func check_grant_available() -> bool:
	if grant_used:
		return false
	# Truly stuck: can't stitch any more, can't afford anything useful
	if can_stitch():
		return false
	if money >= 3:  # can buy yarn
		return false
	if total_yarn() > 0 and active_hook_id != "" and hooks[active_hook_id]["durability"] > 0:
		return false
	return true

# ─── ECONOMY ACTIONS ─────────────────────────────────────────────────────────
func buy_yarn(color_id: String) -> bool:
	var yarn = ItemData.get_yarn(color_id)
	if yarn.is_empty():
		return false
	if money < yarn["price"]:
		post_message("Not enough money!", Color(0.9, 0.3, 0.3))
		return false
	money -= yarn["price"]
	yarn_inventory[color_id] += yarn["pack_units"]
	emit_signal("money_changed", money)
	emit_signal("yarn_changed")
	emit_signal("state_changed")
	return true

func buy_hook(hook_id: String) -> bool:
	var hook = ItemData.get_hook(hook_id)
	if hook.is_empty():
		return false
	if hooks[hook_id]["owned"]:
		post_message("Already owned!", Color(0.9, 0.6, 0.3))
		return false
	if money < hook["price"]:
		post_message("Not enough money!", Color(0.9, 0.3, 0.3))
		return false
	money -= hook["price"]
	hooks[hook_id]["owned"] = true
	hooks[hook_id]["durability"] = hook["max_durability"]
	emit_signal("money_changed", money)
	emit_signal("hook_changed")
	emit_signal("state_changed")
	return true

func repair_hook(hook_id: String) -> bool:
	var hook = ItemData.get_hook(hook_id)
	if hook.is_empty() or not hooks[hook_id]["owned"]:
		return false
	var cost = hook["repair_cost"]
	if money < cost:
		post_message("Not enough money to repair!", Color(0.9, 0.3, 0.3))
		return false
	money -= cost
	hooks[hook_id]["durability"] = hook["max_durability"]
	emit_signal("money_changed", money)
	emit_signal("hook_changed")
	emit_signal("state_changed")
	post_message("Hook repaired!", Color(0.4, 0.8, 0.4))
	return true

func equip_hook(hook_id: String) -> bool:
	if not hooks[hook_id]["owned"]:
		return false
	active_hook_id = hook_id
	emit_signal("hook_changed")
	emit_signal("state_changed")
	return true

# ─── CRAFTING ACTIONS ────────────────────────────────────────────────────────
func start_craft(item_id: String, variant_id: String) -> void:
	current_item_id = item_id
	current_variant_id = variant_id
	stitches_done = []
	colors_used = []
	emit_signal("craft_progress_changed")
	emit_signal("state_changed")

func do_stitch() -> int:
	# Returns number of stitches actually placed, 0 if failed
	if not can_stitch():
		return 0
	var hook = get_active_hook()
	var hook_state = get_active_hook_state()
	var variant = get_variant(current_item_id, current_variant_id)
	var power: int = hook["stitch_power"]
	var placed := 0
	for _i in range(power):
		if stitches_done.size() >= variant["total_stitches"]:
			break
		if yarn_inventory.get(selected_color, 0) <= 0:
			break
		if hook_state["durability"] <= 0:
			break
		var next_idx = stitches_done.size()
		var path_cell = variant["stitch_path"][next_idx]
		stitches_done.append({
			"row": path_cell["row"],
			"col": path_cell["col"],
			"color": selected_color
		})
		yarn_inventory[selected_color] -= 1
		if not colors_used.has(selected_color):
			colors_used.append(selected_color)
		hook_state["durability"] -= hook["durability_loss"]
		if hook_state["durability"] < 0:
			hook_state["durability"] = 0
		lifetime_stitches += 1
		placed += 1

	emit_signal("craft_progress_changed")
	emit_signal("yarn_changed")
	emit_signal("hook_changed")
	emit_signal("state_changed")
	if placed > 0:
		SaveManager.autosave()
	if check_grant_available():
		emit_signal("grant_available")
	return placed

func is_craft_complete() -> bool:
	if current_item_id.is_empty():
		return false
	var variant = get_variant(current_item_id, current_variant_id)
	if variant.is_empty():
		return false
	return stitches_done.size() >= variant["total_stitches"]

func sell_item() -> int:
	if not is_craft_complete():
		return 0
	var item = get_item(current_item_id)
	var base_value: int = item["sale_value"]
	var bonus: int = (colors_used.size() - 1) * MULTI_COLOR_BONUS
	if bonus < 0:
		bonus = 0
	var total: int = base_value + bonus
	money += total
	items_sold_this_run += 1
	money_earned_this_run += total
	lifetime_items_sold += 1
	lifetime_money_earned += total
	emit_signal("item_sold", item["name"], total)
	emit_signal("money_changed", money)
	# Clear craft
	current_item_id = ""
	current_variant_id = ""
	stitches_done = []
	colors_used = []
	emit_signal("craft_progress_changed")
	emit_signal("state_changed")
	SaveManager.autosave()
	return total

func select_color(color_id: String) -> void:
	selected_color = color_id
	emit_signal("state_changed")

# ─── EMERGENCY GRANT ─────────────────────────────────────────────────────────
func use_grant() -> void:
	if grant_used:
		return
	grant_used = true
	money += GRANT_MONEY
	yarn_inventory["red"] += GRANT_YARN
	if hooks["basic"]["owned"]:
		hooks["basic"]["durability"] = max(hooks["basic"]["durability"], GRANT_HOOK_DUR)
	else:
		hooks["basic"]["owned"] = true
		hooks["basic"]["durability"] = GRANT_HOOK_DUR
		active_hook_id = "basic"
	emit_signal("money_changed", money)
	emit_signal("yarn_changed")
	emit_signal("hook_changed")
	emit_signal("state_changed")
	post_message("Emergency grant received! +$12, +8 red yarn.", Color(0.4, 0.8, 0.9))
	SaveManager.autosave()

# ─── RESET ───────────────────────────────────────────────────────────────────
func start_over() -> void:
	# Reset run, keep lifetime stats
	lifetime_runs += 1
	money = STARTING_MONEY
	_init_yarn()
	_init_hooks()
	active_hook_id = "basic"
	grant_used = false
	items_sold_this_run = 0
	money_earned_this_run = 0
	current_item_id = ""
	current_variant_id = ""
	stitches_done = []
	colors_used = []
	selected_color = "red"
	emit_signal("state_changed")
	emit_signal("money_changed", money)
	emit_signal("yarn_changed")
	emit_signal("hook_changed")
	emit_signal("craft_progress_changed")
	SaveManager.autosave()
	post_message("New run started! Good luck.", Color(0.4, 0.8, 0.4))

func full_reset() -> void:
	lifetime_items_sold = 0
	lifetime_money_earned = 0
	lifetime_stitches = 0
	lifetime_runs = 0
	start_over()
	SaveManager.autosave()
	post_message("Full reset complete.", Color(0.8, 0.5, 0.3))

# ─── HELPERS ─────────────────────────────────────────────────────────────────
func post_message(text: String, color: Color = Color.WHITE) -> void:
	emit_signal("message_posted", text, color)

func to_save_dict() -> Dictionary:
	return {
		"version": 2,
		"runState": {
			"money": money,
			"yarn_inventory": yarn_inventory.duplicate(),
			"hooks": hooks.duplicate(true),
			"active_hook_id": active_hook_id,
			"grant_used": grant_used,
			"items_sold_this_run": items_sold_this_run,
			"money_earned_this_run": money_earned_this_run,
			"current_item_id": current_item_id,
			"current_variant_id": current_variant_id,
			"stitches_done": stitches_done.duplicate(true),
			"colors_used": colors_used.duplicate(),
			"selected_color": selected_color,
		},
		"lifetimeStats": {
			"lifetime_items_sold": lifetime_items_sold,
			"lifetime_money_earned": lifetime_money_earned,
			"lifetime_stitches": lifetime_stitches,
			"lifetime_runs": lifetime_runs,
		}
	}

func load_from_dict(d: Dictionary) -> void:
	if not d.has("runState") or not d.has("lifetimeStats"):
		return
	var r = d["runState"]
	var l = d["lifetimeStats"]
	money = r.get("money", STARTING_MONEY)
	yarn_inventory = r.get("yarn_inventory", {})
	hooks = r.get("hooks", {})
	active_hook_id = r.get("active_hook_id", "basic")
	grant_used = r.get("grant_used", false)
	items_sold_this_run = r.get("items_sold_this_run", 0)
	money_earned_this_run = r.get("money_earned_this_run", 0)
	current_item_id = r.get("current_item_id", "")
	current_variant_id = r.get("current_variant_id", "")
	stitches_done = r.get("stitches_done", [])
	colors_used = r.get("colors_used", [])
	selected_color = r.get("selected_color", "red")
	lifetime_items_sold = l.get("lifetime_items_sold", 0)
	lifetime_money_earned = l.get("lifetime_money_earned", 0)
	lifetime_stitches = l.get("lifetime_stitches", 0)
	lifetime_runs = l.get("lifetime_runs", 0)
	emit_signal("state_changed")
	emit_signal("money_changed", money)
	emit_signal("yarn_changed")
	emit_signal("hook_changed")
	emit_signal("craft_progress_changed")
