extends Control
# StitchGrid.gd — Renders the stitch grid with cozy visual style.
# Attach to a Control node in the crafting panel.

const CELL_SIZE := 20
const CELL_GAP := 2
const CELL_RADIUS := 3.0

@export var ghost_color := Color(0.75, 0.70, 0.65, 0.45)
@export var ghost_border := Color(0.60, 0.55, 0.50, 0.70)
@export var empty_color := Color(0, 0, 0, 0)

func _ready() -> void:
	GameState.craft_progress_changed.connect(_on_progress_changed)
	GameState.state_changed.connect(_on_progress_changed)

func _on_progress_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var grid = CraftingManager.get_render_grid()
	if grid.is_empty():
		_draw_placeholder()
		return

	var dims = CraftingManager.get_grid_dimensions()
	var step = CELL_SIZE + CELL_GAP
	var total_w = dims.x * step - CELL_GAP
	var total_h = dims.y * step - CELL_GAP

	# Center inside available size
	var ox = (size.x - total_w) * 0.5
	var oy = (size.y - total_h) * 0.5

	for r in range(grid.size()):
		for c in range(grid[r].size()):
			var cell = grid[r][c]
			var rx = ox + c * step
			var ry = oy + r * step
			var rect = Rect2(rx, ry, CELL_SIZE, CELL_SIZE)
			if cell == "empty":
				continue
			elif cell == "ghost":
				_draw_ghost_cell(rect)
			else:
				_draw_stitched_cell(rect, cell)

func _draw_ghost_cell(rect: Rect2) -> void:
	# Rounded tile with dashed-feeling border
	draw_rect(Rect2(rect.position, rect.size), ghost_color, true, -1.0)
	draw_rect(Rect2(rect.position, rect.size), ghost_border, false, 1.0)
	# Small cross-hatch dots to suggest crochet template
	var cx = rect.position.x + rect.size.x * 0.5
	var cy = rect.position.y + rect.size.y * 0.5
	draw_circle(Vector2(cx, cy), 1.2, ghost_border)

func _draw_stitched_cell(rect: Rect2, color_id: String) -> void:
	var yarn = ItemData.get_yarn(color_id)
	var base_col: Color = yarn.get("color", Color.WHITE) if not yarn.is_empty() else Color.WHITE
	# Slightly darkened border
	var border_col = base_col.darkened(0.25)
	var highlight_col = base_col.lightened(0.25)

	# Fill
	draw_rect(Rect2(rect.position, rect.size), base_col, true, -1.0)
	# Border
	draw_rect(Rect2(rect.position, rect.size), border_col, false, 1.5)

	# Cross-hatch texture lines (yarn texture illusion)
	var inner = Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6))
	var x1 = inner.position.x
	var y1 = inner.position.y
	var x2 = inner.end.x
	var y2 = inner.end.y
	var line_col = border_col
	line_col.a = 0.5
	draw_line(Vector2(x1, y1), Vector2(x2, y2), line_col, 0.8)
	draw_line(Vector2(x2, y1), Vector2(x1, y2), line_col, 0.8)

	# Highlight dot in top-left
	draw_circle(Vector2(rect.position.x + 4, rect.position.y + 4), 1.5, highlight_col)

func _draw_placeholder() -> void:
	var msg := "← Select an item\n   to begin crafting"
	var font = ThemeDB.fallback_font
	var font_size := 14
	var lines = msg.split("\n")
	var y = size.y * 0.5 - float(lines.size()) * float(font_size) * 0.5
	for line in lines:
		var tw = font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2((size.x - tw) * 0.5, y + font_size), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.6, 0.55, 0.5, 0.7))
		y += font_size + 4
