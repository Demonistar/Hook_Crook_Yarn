extends Control
# StitchGrid.gd — Custom _draw() stitch grid renderer.
# Attach to a Control that fills its container (PRESET_FULL_RECT or SIZE_EXPAND_FILL).

const CELL_SIZE := 20
const CELL_GAP  := 2

func _ready() -> void:
	GameState.craft_progress_changed.connect(queue_redraw)
	GameState.state_changed.connect(queue_redraw)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x < 4 or size.y < 4:
		return

	var grid = CraftingManager.get_render_grid()
	if grid.is_empty():
		_draw_placeholder()
		return

	var dims = CraftingManager.get_grid_dimensions()
	var step = CELL_SIZE + CELL_GAP
	var total_w = dims.x * step - CELL_GAP
	var total_h = dims.y * step - CELL_GAP

	var ox = (size.x - total_w) * 0.5
	var oy = (size.y - total_h) * 0.5

	for r in range(grid.size()):
		for c in range(grid[r].size()):
			var cell = grid[r][c]
			if cell == "empty":
				continue
			var rx = ox + c * step
			var ry = oy + r * step
			var rect = Rect2(rx, ry, CELL_SIZE, CELL_SIZE)
			if cell == "ghost":
				_draw_ghost(rect)
			else:
				_draw_stitched(rect, cell)

func _draw_ghost(rect: Rect2) -> void:
	var fill  := Color(0.55, 0.50, 0.46, 0.40)
	var bord  := Color(0.65, 0.59, 0.54, 0.65)
	draw_rect(rect, fill, true)
	draw_rect(rect, bord, false, 1.0)
	# Center dot for crochet-template feel
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	draw_circle(Vector2(cx, cy), 1.0, bord)

func _draw_stitched(rect: Rect2, color_id: String) -> void:
	var yarn = ItemData.get_yarn(color_id)
	var base_col: Color = yarn.get("color", Color.WHITE) if not yarn.is_empty() else Color.WHITE
	var border_col = base_col.darkened(0.28)
	var hi_col     = base_col.lightened(0.30)

	draw_rect(rect, base_col, true)
	draw_rect(rect, border_col, false, 1.2)

	# Yarn texture: two diagonal lines
	var ix1 = rect.position.x + 3
	var iy1 = rect.position.y + 3
	var ix2 = rect.end.x - 3
	var iy2 = rect.end.y - 3
	var lc  := border_col
	lc.a = 0.45
	draw_line(Vector2(ix1, iy1), Vector2(ix2, iy2), lc, 0.8)
	draw_line(Vector2(ix2, iy1), Vector2(ix1, iy2), lc, 0.8)

	# Highlight spot
	draw_circle(Vector2(rect.position.x + 4.0, rect.position.y + 4.0), 1.4, hi_col)

func _draw_placeholder() -> void:
	var font   = ThemeDB.fallback_font
	var fsize  := 13
	var lines  := ["Select an item to", "begin crafting"]
	var y      = size.y * 0.5 - float(lines.size()) * float(fsize + 4) * 0.5
	for line in lines:
		var tw = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		draw_string(font, Vector2((size.x - tw) * 0.5, y + fsize), line,
				HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.55, 0.50, 0.46, 0.70))
		y += fsize + 4
