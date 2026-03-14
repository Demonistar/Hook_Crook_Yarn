extends PanelContainer
# StatsPanel.gd — Run stats and lifetime stats display.

@onready var run_labels: VBoxContainer = $Margin/VBox/RunSection/Labels
@onready var life_labels: VBoxContainer = $Margin/VBox/LifetimeSection/Labels

func _ready() -> void:
	GameState.state_changed.connect(_refresh)
	GameState.item_sold.connect(_on_item_sold)
	_refresh()

func _on_item_sold(_name: String, _val: int) -> void:
	_refresh()

func _refresh() -> void:
	# Run stats
	_set_label(run_labels, 0, "Items sold: %d" % GameState.items_sold_this_run)
	_set_label(run_labels, 1, "Money earned: $%d" % GameState.money_earned_this_run)
	_set_label(run_labels, 2, "Money on hand: $%d" % GameState.money)

	# Lifetime stats
	_set_label(life_labels, 0, "Total items: %d" % GameState.lifetime_items_sold)
	_set_label(life_labels, 1, "Total earned: $%d" % GameState.lifetime_money_earned)
	_set_label(life_labels, 2, "Total stitches: %d" % GameState.lifetime_stitches)
	_set_label(life_labels, 3, "Runs: %d" % GameState.lifetime_runs)

func _set_label(container: VBoxContainer, idx: int, text: String) -> void:
	while container.get_child_count() <= idx:
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		container.add_child(lbl)
	var lbl: Label = container.get_child(idx)
	lbl.text = text
