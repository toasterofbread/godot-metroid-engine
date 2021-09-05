extends Node

enum dir {LEFT, RIGHT, UP, DOWN, TOPLEFT, TOPRIGHT, BOTLEFT, BOTRIGHT, NONE}

func _ready():
	for i in len(DamageType):
		DamageTypeDict[DamageType.keys()[i]] = i

enum DamageType {
	NONE, 
	BEAM, 
	BOMB, 
	POWERBOMB, 
	MISSILE, 
	SUPERMISSILE, 
	SCREWATTACK, 
	SPEEDBOOSTER, 
	CRUMBLE, 
	SPIKE, 
	FIRE,
	ENEMYCOLLISION
	}
var DamageTypeDict: Dictionary

enum Upgrade {
	
	# Amount-based
	ETANK,
	MISSILE,
	SUPERMISSILE, 
	POWERBOMB, 
	
	# Misc unique
	BOMB, 
	MORPHBALL, 
	SPIDERBALL, 
	SPRINGBALL, 
	POWERGRIP, 
	HIGHJUMP, 
	SPACEJUMP, 
	SCREWATTACK, 
	SPEEDBOOSTER, 
	
	# Suits
	POWERSUIT,
	VARIASUIT, 
	GRAVITYSUIT, 
	
	# Power beams
	POWERBEAM, 
	ICEBEAM, 
	PLASMABEAM, 
	SPAZERBEAM, 
	WAVEBEAM, 
	
	# Other beams
	CHARGEBEAM, 
	GRAPPLEBEAM,
	
	# Visors
	SCANVISOR, 
	XRAYVISOR,
	
	# Special
	FLAMETHROWER,
	SCRAPMETAL,
	AIRSPARK
}

const UpgradeTypes: = {
	"visor": [Upgrade.XRAYVISOR, Upgrade.SCANVISOR],
	"beam": [Upgrade.POWERBEAM, Upgrade.ICEBEAM, Upgrade.PLASMABEAM, Upgrade.SPAZERBEAM, Upgrade.WAVEBEAM],
	"suit": [Upgrade.POWERSUIT, Upgrade.VARIASUIT, Upgrade.GRAVITYSUIT],
	}
const upgrade_gain_amounts = {
	Upgrade.MISSILE: 5,
	Upgrade.SUPERMISSILE: 5,
	Upgrade.POWERBOMB: 5,
}

enum Layers {BACKGROUND, BACKGROUND_ELEMENT, BACKGROUND_FILLER, ENEMY, SAMUS, DOOR, WORLD, BLOCK, AMMOPICKUP, PROJECTILE, FLUID, VISOR, MENU, NOTIFICATION}
enum CanvasLayers {BACKGROUND, BACKGROUND_FRONT, SAMUS, HUD, MENU, NOTIFICATION}

enum SAMUS_PHYSICS_MODES {STANDARD, WATER}

enum Groups {ENEMY, SAVESTATION, SCANNODE, DOOR}
func add_node_to_group(node: Node, group: int):
	node.add_to_group(Groups.keys()[group])
func get_nodes_in_group(group: int):
	return get_tree().get_nodes_in_group(Groups.keys()[group])
func is_node_in_group(node: Node, group: int):
	return node.is_in_group(Groups.keys()[group])

