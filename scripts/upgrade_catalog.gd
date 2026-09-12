class_name UpgradeCatalog
extends RefCounted

const UPGRADES := {
	"hull_plating": {"name": "Hull Plating", "cost": 500, "description": "New water units receive +1 maximum HP."},
	"flight_training": {"name": "Flight Training", "cost": 650, "description": "New aircraft receive +1 movement."},
	"port_grants": {"name": "Port Grants", "cost": 400, "description": "Start each match with +100 money."},
}

static func owns(profile: Dictionary, upgrade_id: String) -> bool:
	return upgrade_id in profile.get("upgrades", [])
