class_name UpgradeScreen
extends Control

const SaveStoreResource = preload("res://scripts/save_store.gd")
const UpgradeCatalogResource = preload("res://scripts/upgrade_catalog.gd")

signal cancelled

@onready var credits_label: Label = $Panel/Content/CreditsLabel
@onready var status_label: Label = $Panel/Content/StatusLabel
@onready var upgrades_list: VBoxContainer = $Panel/Content/UpgradesList
@onready var reset_confirm: CheckBox = $Panel/Content/ResetConfirm

var profile: Dictionary

func _ready() -> void:
	profile = SaveStoreResource.load_profile()
	_refresh()

func _refresh() -> void:
	credits_label.text = "Command credits: %d" % profile["currency"]
	for child in upgrades_list.get_children():
		child.queue_free()
	for upgrade_id in UpgradeCatalogResource.UPGRADES:
		var upgrade: Dictionary = UpgradeCatalogResource.UPGRADES[upgrade_id]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 52)
		button.text = "%s — %s%s" % [upgrade["name"], upgrade["description"], " OWNED" if UpgradeCatalogResource.owns(profile, upgrade_id) else " $%d" % upgrade["cost"]]
		button.disabled = UpgradeCatalogResource.owns(profile, upgrade_id)
		button.pressed.connect(_purchase.bind(upgrade_id))
		upgrades_list.add_child(button)

func _purchase(upgrade_id: String) -> void:
	var result := UpgradeCatalogResource.purchase(profile, upgrade_id)
	if not result["ok"]:
		status_label.text = result["message"]
		return
	var updated: Dictionary = result["profile"]
	var error := SaveStoreResource.save_profile(updated)
	if error != OK:
		status_label.text = "Purchase was not saved (error %d). Your credits are unchanged." % error
		return
	profile = updated
	status_label.text = result["message"]
	_refresh()

func _on_reset_pressed() -> void:
	var error := SaveStoreResource.reset_profile(reset_confirm.button_pressed)
	if error == ERR_UNAUTHORIZED:
		status_label.text = "Tick confirmation before resetting your profile."
		return
	if error != OK:
		status_label.text = "Profile reset failed (error %d)." % error
		return
	profile = SaveStoreResource.default_profile()
	reset_confirm.button_pressed = false
	status_label.text = "Profile reset."
	_refresh()

func _on_back_pressed() -> void:
	cancelled.emit()
