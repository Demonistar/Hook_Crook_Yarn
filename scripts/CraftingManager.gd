extends Node
# CraftingManager.gd — Handles crafting UI coordination and stitch grid rendering data.
# Autoload as "CraftingManager".
# The actual stitch grid Control node subscribes to state_changed and redraws itself.

signal craft_started(item_id: String, variant_id: String)
signal craft_completed()

func start_crafting(item_id: String, variant_id: String) -> void:
	GameState.start_craft(item_id, variant_id)
	emit_signal("craft_started", item_id, variant_id)

func attempt_stitch() -> void:
	if not GameState.can_stitch():
		# Diagnose why
		if GameState.active_hook_id.is_empty():
			GameState.post_message("Equip a hook first!", Color(0.9, 0.5, 0.2))
		elif GameState.hooks[GameState.active_hook_id]["durability"] <= 0:
			GameState.post_message("Hook is broken! Repair it.", Color(0.9, 0.3, 0.3))
		elif GameState.yarn_inventory.get(GameState.selected_color, 0) <= 0:
			GameState.post_message("Out of " + GameState.selected_color + " yarn!", Color(0.9, 0.5, 0.2))
		elif GameState.current_item_id.is_empty():
			GameState.post_message("Select an item to craft first.", Color(0.8, 0.8, 0.5))
		else:
			GameState.post_message("Craft is complete! Sell it.", Color(0.4, 0.8, 0.4))
		return
	var placed = GameState.do_stitch()
	if placed > 0 and GameState.is_craft_complete():
		emit_signal("craft_completed")
		GameState.post_message("Craft complete! Ready to sell.", Color(0.4, 0.9, 0.4))

func attempt_sell() -> void:
	if not GameState.is_craft_complete():
		GameState.post_message("Item is not finished yet!", Color(0.9, 0.5, 0.2))
		return
	var earned = GameState.sell_item()
	if earned > 0:
		GameState.post_message("Sold for $%d!" % earned, Color(0.95, 0.85, 0.3))

# Returns a 2D array matching shape_grid dimensions,
# each cell is: "empty" | "ghost" | color_id string
func get_render_grid() -> Array:
	if GameState.current_item_id.is_empty():
		return []
	var variant = GameState.get_variant(GameState.current_item_id, GameState.current_variant_id)
	if variant.is_empty():
		return []
	var sg = variant["shape_grid"]
	var rows = sg.size()
	# Find max cols across all rows (grids can be ragged)
	var max_cols := 0
	for row in sg:
		if row.size() > max_cols:
			max_cols = row.size()
	# Build result grid padded to max_cols
	var grid = []
	for r in range(rows):
		var row = []
		for c in range(max_cols):
			row.append("empty")
		grid.append(row)
	# Mark valid shape cells as ghost
	for r in range(rows):
		for c in range(sg[r].size()):
			if sg[r][c] == 1:
				grid[r][c] = "ghost"
	# Overwrite stitched cells with their color
	for s in GameState.stitches_done:
		grid[s["row"]][s["col"]] = s["color"]
	return grid

func get_grid_dimensions() -> Vector2i:
	if GameState.current_item_id.is_empty():
		return Vector2i.ZERO
	var variant = GameState.get_variant(GameState.current_item_id, GameState.current_variant_id)
	if variant.is_empty():
		return Vector2i.ZERO
	var sg = variant["shape_grid"]
	var max_cols = 0
	for row in sg:
		if row.size() > max_cols:
			max_cols = row.size()
	return Vector2i(max_cols, sg.size())
