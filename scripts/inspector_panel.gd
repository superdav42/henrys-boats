class_name InspectorPanel
extends CanvasLayer

@onready var title_label: Label = $Panel/Title
@onready var context_label: Label = $Panel/Context
@onready var details_label: Label = $Panel/Details

func show_snapshot(snapshot: Dictionary) -> void:
	visible = true
	title_label.text = snapshot.get("title", "Inspection")
	context_label.text = snapshot.get("context", "Read-only tactical inspector")
	details_label.text = "\n".join(snapshot.get("details", PackedStringArray()))

func clear() -> void:
	visible = false
	title_label.text = ""
	context_label.text = ""
	details_label.text = ""
