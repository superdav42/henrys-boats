class_name UpgradeCatalog
extends RefCounted

const UPGRADES := {
	"hull_plating": {"name": "Hull Plating", "cost": 500, "description": "New water units receive +1 maximum HP."},
	"flight_training": {"name": "Flight Training", "cost": 650, "description": "New aircraft receive +1 movement."},
	"port_grants": {"name": "Port Grants", "cost": 400, "description": "Start each match with +100 money."},
}

static func owns(profile: Dictionary, upgrade_id: String) -> bool:
	return upgrade_id in profile.get("upgrades", [])

static func effects(profile: Dictionary) -> Dictionary:
	return {
		"water_hp_bonus": 1 if owns(profile, "hull_plating") else 0,
		"air_move_bonus": 1 if owns(profile, "flight_training") else 0,
		"starting_money_bonus": 100 if owns(profile, "port_grants") else 0,
	}

static func purchase(profile: Dictionary, upgrade_id: String) -> Dictionary:
	if not UPGRADES.has(upgrade_id):
		return {"ok": false, "message": "That upgrade is unavailable."}
	if owns(profile, upgrade_id):
		return {"ok": false, "message": "You already own that upgrade."}
	var cost: int = UPGRADES[upgrade_id]["cost"]
	if int(profile.get("currency", 0)) < cost:
		return {"ok": false, "message": "Not enough command credits."}
	var updated := profile.duplicate(true)
	updated["currency"] = int(updated["currency"]) - cost
	updated["upgrades"].append(upgrade_id)
	return {"ok": true, "profile": updated, "message": "%s purchased." % UPGRADES[upgrade_id]["name"]}
