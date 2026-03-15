extends Node
# ItemData.gd — All item/variant definitions with hand-crafted silhouettes.
# Silhouettes designed from scratch for recognizability, NOT copied from HTML prototype.

# Each shapeGrid row is an array of 0/1.
# 1 = valid stitch cell, 0 = empty space.
# Grids are designed so the shape is clearly recognizable at cell scale.

# ─── YARN CATALOG ───────────────────────────────────────────────────────────
const YARN_CATALOG := [
	{ "id": "red",    "name": "Red Yarn",    "color": Color(0.87, 0.31, 0.31), "price": 3, "pack_units": 8 },
	{ "id": "orange", "name": "Orange Yarn", "color": Color(0.91, 0.54, 0.24), "price": 3, "pack_units": 8 },
	{ "id": "yellow", "name": "Yellow Yarn", "color": Color(0.95, 0.87, 0.30), "price": 3, "pack_units": 8 },
	{ "id": "green",  "name": "Green Yarn",  "color": Color(0.34, 0.65, 0.42), "price": 3, "pack_units": 8 },
	{ "id": "blue",   "name": "Blue Yarn",   "color": Color(0.30, 0.50, 0.85), "price": 3, "pack_units": 8 },
	{ "id": "indigo", "name": "Indigo Yarn", "color": Color(0.29, 0.29, 0.72), "price": 4, "pack_units": 8 },
	{ "id": "violet", "name": "Violet Yarn", "color": Color(0.56, 0.35, 0.78), "price": 4, "pack_units": 8 },
]

# ─── HOOK CATALOG ────────────────────────────────────────────────────────────
const HOOK_CATALOG := [
	{ "id": "basic",   "name": "Basic Hook",       "price": 18,  "max_durability": 120, "stitch_power": 1, "repair_cost": 6,  "durability_loss": 0.35 },
	{ "id": "comfort", "name": "Comfortable Hook", "price": 62,  "max_durability": 180, "stitch_power": 2, "repair_cost": 12, "durability_loss": 0.30 },
	{ "id": "premium", "name": "Premium Hook",     "price": 125, "max_durability": 260, "stitch_power": 3, "repair_cost": 20, "durability_loss": 0.26 },
]

# ─── ITEM DEFINITIONS ────────────────────────────────────────────────────────
# COASTER — flat round disc, ~8x8 cells, clearly circular
# SCARF   — long horizontal rectangle with fringe indent, ~14x5
# BEANIE  — dome with optional pom-pom, brim at bottom
# PLUSHIE — character silhouettes 9x10 or so
# BOOTIE  — shoe profile: rounded toe, heel bump, ankle cuff

func get_items() -> Array:
	return [
		{
			"id": "coaster", "name": "Coaster", "complexity": 1, "sale_value": 62,
			"variants": _coaster_variants()
		},
		{
			"id": "scarf", "name": "Scarf", "complexity": 2, "sale_value": 88,
			"variants": _scarf_variants()
		},
		{
			"id": "beanie", "name": "Beanie Hat", "complexity": 3, "sale_value": 118,
			"variants": _beanie_variants()
		},
		{
			"id": "plushie", "name": "Tiny Plushie", "complexity": 4, "sale_value": 162,
			"variants": _plushie_variants()
		},
		{
			"id": "bootie", "name": "Bootie", "complexity": 4, "sale_value": 176,
			"variants": _bootie_variants()
		},
	]

# ─── COASTER VARIANTS ────────────────────────────────────────────────────────
# Round coaster — a clear disc silhouette, 9x9
# Hexagonal coaster — flat-top hex, 9x9
func _coaster_variants() -> Array:
	return [
		{
			"id": "round", "name": "Round",
			"shape_grid": [
				[0,0,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,0,0],
			]
		},
		{
			"id": "square", "name": "Square",
			"shape_grid": [
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
			]
		},
		{
			"id": "hex", "name": "Hexagonal",
			"shape_grid": [
				[0,0,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,0,0],
			]
		},
	]

# ─── SCARF VARIANTS ──────────────────────────────────────────────────────────
# Classic — long 14-wide, 5-tall rectangle
# Striped ends — same shape but game allows multicolor naturally
# Tapered — slightly narrower at ends (like folded scarf profile)
func _scarf_variants() -> Array:
	return [
		{
			"id": "classic", "name": "Classic",
			"shape_grid": [
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
			]
		},
		{
			"id": "tapered", "name": "Tapered Ends",
			"shape_grid": [
				[0,1,1,1,1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,1,1,1,1,1,1,0],
			]
		},
		{
			"id": "wide", "name": "Wide Wrap",
			"shape_grid": [
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
			]
		},
	]

# ─── BEANIE VARIANTS ─────────────────────────────────────────────────────────
# Classic Beanie: dome top, straight sides, wide brim band at bottom.
# Pom-Pom: small round cluster (3 cells) above dome.
# Slouch: taller, slight lean/gather at top.
# Folded Rim: wider brim section at bottom.
func _beanie_variants() -> Array:
	return [
		{
			"id": "classic", "name": "Classic Beanie",
			# 10 wide, 8 tall. Dome narrows at top, widens at brim.
			"shape_grid": [
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
			]
		},
		{
			"id": "pompom", "name": "Pom-Pom Beanie",
			# Pom-pom is 3 cells at top center, then dome body below.
			"shape_grid": [
				[0,0,0,0,1,1,0,0,0,0],  # pom-pom ball
				[0,0,0,1,1,1,1,0,0,0],  # pom-pom base
				[0,0,1,1,1,1,1,1,0,0],  # dome top
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
			]
		},
		{
			"id": "slouch", "name": "Slouch Beanie",
			# Taller crown that leans/gathers — asymmetric dome
			"shape_grid": [
				[0,0,0,0,0,1,1,1,0,0,0,0],
				[0,0,0,0,1,1,1,1,1,0,0,0],
				[0,0,0,1,1,1,1,1,1,1,0,0],
				[0,0,1,1,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1,1,1],
			]
		},
		{
			"id": "folded_rim", "name": "Folded Rim",
			# Dome top, then double-thickness brim at bottom
			"shape_grid": [
				[0,0,0,1,1,1,1,0,0,0],
				[0,0,1,1,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],  # brim fold start
				[1,1,1,1,1,1,1,1,1,1],  # brim fold end (wider than dome)
				[1,1,1,1,1,1,1,1,1,1],
			]
		},
	]

# ─── PLUSHIE VARIANTS ────────────────────────────────────────────────────────
# Each is ~8–10 wide, ~9–10 tall. Designed to be clearly readable.
func _plushie_variants() -> Array:
	return [
		{
			"id": "frog", "name": "Frog",
			# Big round head with eye-bumps on top, chubby body, stubby legs
			"shape_grid": [
				[0,1,1,0,0,1,1,0],  # eye bumps
				[1,1,1,1,1,1,1,1],  # top of head
				[1,1,1,1,1,1,1,1],  # head mid
				[1,1,1,1,1,1,1,1],  # head lower
				[0,1,1,1,1,1,1,0],  # neck
				[0,1,1,1,1,1,1,0],  # body upper
				[1,1,1,1,1,1,1,1],  # body mid
				[1,1,1,1,1,1,1,1],  # body lower
				[1,1,0,1,1,0,1,1],  # legs spread
				[1,0,0,1,1,0,0,1],  # feet
			]
		},
		{
			"id": "cat", "name": "Cat",
			# Triangle ears on top, round head, oval body, tiny paws
			"shape_grid": [
				[1,1,0,0,0,0,1,1],  # ear tips
				[1,1,1,0,0,1,1,1],  # ear base
				[0,1,1,1,1,1,1,0],  # forehead
				[1,1,1,1,1,1,1,1],  # head wide
				[1,1,1,1,1,1,1,1],  # head lower
				[0,1,1,1,1,1,1,0],  # neck
				[0,1,1,1,1,1,1,0],  # body
				[0,1,1,1,1,1,1,0],  # body lower
				[0,1,1,0,0,1,1,0],  # paws gap
				[0,1,0,0,0,0,1,0],  # paw tips
			]
		},
		{
			"id": "bear", "name": "Bear",
			# Round ears on top, chubby round head, barrel body, small paws
			"shape_grid": [
				[1,1,0,0,0,0,1,1],  # ear tops
				[1,1,1,0,0,1,1,1],  # ears + forehead
				[0,1,1,1,1,1,1,0],  # head
				[1,1,1,1,1,1,1,1],  # head wide (cheeks)
				[1,1,1,1,1,1,1,1],  # head lower / snout
				[0,1,1,1,1,1,1,0],  # neck
				[1,1,1,1,1,1,1,1],  # body
				[1,1,1,1,1,1,1,1],  # belly
				[0,1,1,0,0,1,1,0],  # legs
				[1,1,0,0,0,0,1,1],  # paws
			]
		},
		{
			"id": "stegosaurus", "name": "Stegosaurus",
			# Side profile: plates on back-top, 4 stubby legs at bottom, long tail right
			"shape_grid": [
				[0,1,0,0,0,0,0,0,0,0],  # back plate tip
				[0,1,1,0,0,0,0,0,0,0],  # plate
				[1,1,1,1,0,0,0,0,0,0],  # plate wide, head left
				[0,1,1,1,1,1,1,0,0,0],  # back + head
				[0,0,1,1,1,1,1,1,1,1],  # body long
				[0,0,1,1,1,1,1,1,1,0],  # body
				[0,1,1,1,1,1,1,1,0,0],  # belly
				[1,1,0,1,1,0,1,0,0,0],  # legs
				[1,0,0,1,0,0,1,0,0,0],  # feet
			]
		},
		{
			"id": "trex", "name": "T-Rex",
			# Upright: big head upper left, tiny arm mid, big legs bottom
			"shape_grid": [
				[0,0,1,1,1,1,0,0],  # head top
				[0,1,1,1,1,1,1,0],  # head
				[1,1,1,1,1,1,1,0],  # head + jaw
				[0,0,1,1,1,1,0,0],  # neck
				[0,0,1,1,1,1,0,0],  # upper body
				[0,0,1,1,1,1,1,0],  # body + tiny arm
				[0,0,1,1,1,1,0,0],  # lower body
				[0,1,1,0,1,1,0,0],  # thighs
				[0,1,1,0,1,1,0,0],  # lower legs
				[1,1,0,0,1,1,1,0],  # feet
			]
		},
		{
			"id": "triceratops", "name": "Triceratops",
			# Side profile: frill/horns left, long body right, 4 legs
			"shape_grid": [
				[0,1,1,0,0,0,0,0,0,0],  # frill top
				[1,1,1,1,0,0,0,0,0,0],  # frill
				[1,1,1,1,1,1,0,0,0,0],  # frill + head
				[0,1,1,1,1,1,1,1,0,0],  # head + body
				[0,0,1,1,1,1,1,1,1,0],  # body
				[0,0,0,1,1,1,1,1,1,1],  # body + tail
				[0,1,1,1,1,1,1,1,1,0],  # belly
				[1,1,0,1,1,0,1,1,0,0],  # legs
				[1,0,0,1,0,0,1,0,0,0],  # feet
			]
		},
		{
			"id": "dragon", "name": "Dragon",
			# Wings on sides, round body, horns on head, tail
			"shape_grid": [
				[0,0,1,0,0,0,1,0,0,0],  # horn tips
				[0,0,1,1,1,1,1,0,0,0],  # head + horns
				[0,1,1,1,1,1,1,1,0,0],  # head wide
				[1,1,1,1,1,1,1,1,1,0],  # wing + body
				[1,1,1,1,1,1,1,1,1,1],  # full width
				[1,1,1,1,1,1,1,1,1,0],  # body + wing
				[0,1,1,1,1,1,1,1,0,0],  # lower body
				[0,0,1,1,0,1,1,0,1,0],  # legs + tail
				[0,0,1,0,0,0,1,0,1,1],  # feet + tail end
			]
		},
		{
			"id": "witch", "name": "Witch Doll",
			# Pointy hat on top, round head, dress body that flares wide
			"shape_grid": [
				[0,0,0,1,1,0,0,0],  # hat tip
				[0,0,1,1,1,1,0,0],  # hat upper
				[0,1,1,1,1,1,1,0],  # hat brim
				[1,1,1,1,1,1,1,1],  # hat brim wide
				[0,0,1,1,1,1,0,0],  # head
				[0,1,1,1,1,1,1,0],  # head/collar
				[0,1,1,1,1,1,1,0],  # body upper
				[1,1,1,1,1,1,1,1],  # dress
				[1,1,1,1,1,1,1,1],  # dress wide
				[1,0,1,0,0,1,0,1],  # feet/broomstick
			]
		},
		{
			"id": "unicorn", "name": "Unicorn",
			# Side profile: horn on head, mane, horse body, tail
			"shape_grid": [
				[0,0,1,0,0,0,0,0,0],  # horn tip
				[0,0,1,1,0,0,0,0,0],  # horn
				[0,1,1,1,1,0,0,0,0],  # head + horn base
				[1,1,1,1,1,1,0,0,0],  # head + mane
				[0,1,1,1,1,1,1,1,0],  # neck + body
				[0,0,1,1,1,1,1,1,1],  # body + tail
				[0,0,1,1,1,1,1,1,0],  # body
				[0,1,1,0,1,1,0,0,0],  # legs front
				[1,1,0,0,1,1,0,0,0],  # hooves
			]
		},
		{
			"id": "octopus", "name": "Octopus",
			# Round head, 8 tentacles dangling below
			"shape_grid": [
				[0,0,1,1,1,1,0,0],
				[0,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1],
				[0,1,1,1,1,1,1,0],
				[1,0,1,0,1,0,1,0],  # tentacle tops
				[1,0,1,0,1,0,1,0],
				[1,0,1,0,1,0,1,0],
				[1,0,1,0,1,0,1,0],  # tentacle ends
			]
		},
		{
			"id": "fairy", "name": "Fairy",
			# Wings spread wide, tiny body, round head
			"shape_grid": [
				[0,0,0,1,1,0,0,0],  # head
				[0,0,1,1,1,1,0,0],  # head wide
				[1,1,0,1,1,0,1,1],  # wings out
				[1,1,1,1,1,1,1,1],  # wings + body
				[1,1,0,1,1,0,1,1],  # wing lower
				[0,0,1,1,1,1,0,0],  # body
				[0,0,1,1,1,1,0,0],  # skirt
				[0,1,1,1,1,1,1,0],  # skirt wide
				[0,1,0,0,0,0,1,0],  # feet
			]
		},
		{
			"id": "wizard", "name": "Wizard",
			# Tall pointy hat, robes flare at bottom, beard
			"shape_grid": [
				[0,0,0,0,1,0,0,0],  # hat tip
				[0,0,0,1,1,1,0,0],  # hat
				[0,0,1,1,1,1,1,0],  # hat lower
				[0,1,1,1,1,1,1,1],  # hat brim
				[0,0,1,1,1,1,0,0],  # head/beard
				[0,1,1,1,1,1,1,0],  # shoulders
				[1,1,1,1,1,1,1,1],  # robe
				[1,1,1,1,1,1,1,1],  # robe wide
				[0,1,1,0,0,1,1,0],  # feet
			]
		},
	]

# ─── BOOTIE VARIANTS ─────────────────────────────────────────────────────────
# All bootie variants must read as a shoe/sock from the side.
# Profile: toe curves forward/up on left, heel at right, ankle cuff at top-right.
func _bootie_variants() -> Array:
	return [
		{
			"id": "simple_shoe", "name": "Simple Shoe",
			# Side profile: rounded toe (left), flat sole, ankle rises on right
			"shape_grid": [
				[0,0,0,0,1,1,1,1,0,0],  # ankle cuff top
				[0,0,0,0,1,1,1,1,0,0],  # ankle
				[0,0,0,1,1,1,1,1,1,0],  # ankle + upper
				[0,0,1,1,1,1,1,1,1,0],  # instep
				[0,1,1,1,1,1,1,1,1,0],  # instep lower
				[1,1,1,1,1,1,1,1,1,1],  # toe + sole
				[1,1,1,1,1,1,1,1,1,1],  # sole
				[0,1,1,1,1,1,1,1,1,1],  # sole + heel
				[0,0,0,0,0,1,1,1,1,1],  # heel base
			]
		},
		{
			"id": "ankle_boot", "name": "Ankle Boot",
			# Taller ankle section, distinct heel block
			"shape_grid": [
				[0,0,0,0,1,1,1,1,0,0],
				[0,0,0,0,1,1,1,1,0,0],
				[0,0,0,0,1,1,1,1,0,0],
				[0,0,0,1,1,1,1,1,1,0],
				[0,0,1,1,1,1,1,1,1,0],
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],
				[1,1,1,1,1,1,1,1,1,1],
				[0,0,0,0,1,1,1,1,1,1],  # heel block
			]
		},
		{
			"id": "mary_jane", "name": "Mary Jane",
			# Low profile, rounded toe, strap across instep
			"shape_grid": [
				[0,0,0,0,0,1,1,0,0,0],  # ankle/strap
				[0,0,0,0,1,1,1,1,0,0],  # strap wide
				[0,0,0,1,1,1,1,1,1,0],  # upper shoe
				[0,1,1,1,1,1,1,1,1,0],
				[1,1,1,1,1,1,1,1,1,1],  # toe + sole
				[1,1,1,1,1,1,1,1,1,1],  # sole
				[0,1,1,1,1,1,1,1,1,1],
				[0,0,0,0,1,1,1,1,1,1],  # heel
			]
		},
	]

# ─── PATH BUILDER ────────────────────────────────────────────────────────────
# Generates snake-order stitch path from shape_grid.
func make_stitch_path(shape_grid: Array) -> Array:
	var path := []
	for r in range(shape_grid.size()):
		var row = shape_grid[r]
		var cols := []
		for c in range(row.size()):
			if row[c] == 1:
				cols.append(c)
		if r % 2 == 1:
			cols.reverse()
		for c in cols:
			path.append({"row": r, "col": c})
	return path

# ─── RESOLVE HELPERS ─────────────────────────────────────────────────────────
func get_yarn(id: String) -> Dictionary:
	for y in YARN_CATALOG:
		if y["id"] == id:
			return y
	return {}

func get_hook(id: String) -> Dictionary:
	for h in HOOK_CATALOG:
		if h["id"] == id:
			return h
	return {}

func build_items_with_paths() -> Array:
	var result := []
	for item in get_items():
		var built_variants := []
		for v in item["variants"]:
			var path = make_stitch_path(v["shape_grid"])
			var bv = v.duplicate(true)
			bv["stitch_path"] = path
			bv["total_stitches"] = path.size()
			built_variants.append(bv)
		var bi = item.duplicate(true)
		bi["variants"] = built_variants
		result.append(bi)
	return result
