extends Node

enum dir {LEFT, RIGHT, UP, DOWN, TOPLEFT, TOPRIGHT, BOTLEFT, BOTRIGHT}

func _ready():
	for i in range(len(DamageType)):
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
	SCRAPMETAL
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
enum CanvasLayers {BACKGROUND, BACKGROUND_FRONT, DEFAULT, HUD, MENU, NOTIFICATION}

enum MapAreas {CAVES}
