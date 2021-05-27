extends Node

enum dir {LEFT, RIGHT, UP, DOWN, TOPLEFT, TOPRIGHT, BOTLEFT, BOTRIGHT}

func dir_angle(direction: int) -> int:
	match direction:
		dir.LEFT: return -90
		dir.RIGHT: return 90
		dir.UP: return 0
		dir.DOWN: return 180
		dir.TOPLEFT: return -45
		dir.TOPRIGHT: return 45
		dir.BOTLEFT: return -135
		dir.BOTRIGHT: return 135
		_: return 0

enum DamageType {NONE, BEAM, BOMB, POWERBOMB, MISSILE, SUPERMISSILE, SCREWATTACK, SPEEDBOOSTER, CRUMBLE, SPIKE}

enum Upgrade {GRAPPLEBEAM, BEAM, BOMB, CHARGEBEAM, ETANK, GRAVITY, HIGHJUMP, ICEBEAM, MISSILE, MORPHBALL, PLASMABEAM, POWERBOMB, POWERGRIP, SCREWATTACK, SPACEJUMP, SPAZERBEAM, SPEEDBOOSTER, SPIDERBALL, SPRINGBALL, SUPERMISSILE, VARIA, WAVEBEAM, SCAN, XRAY}
var UpgradeTypes: = {
	"visor": [Upgrade.XRAY, Upgrade.SCAN],
	"beam": [Upgrade.BEAM, Upgrade.ICEBEAM, Upgrade.SPAZERBEAM, Upgrade.WAVEBEAM, Upgrade.PLASMABEAM],
	"suit": [Upgrade.VARIA, Upgrade.GRAVITY],
	}

enum Layers {ENEMY, SAMUS, WORLD, DOOR, PROJECTILE}

const upgrade_data: = {
	Upgrade.BEAM: {"name" :"Power Beam", "description": "Standard Chozo-built beam weapon. Low power, but extremely energy-efficient.", "gain_amount": 1}, 
	Upgrade.BOMB: {"name": "Bombs", "description": "Basic weapon useable in Morph Ball form with utility for exploration and traversal.", "gain_amount": 1}, 
	Upgrade.CHARGEBEAM: {"name": "Charge Beam", "description": "Upgrade for the Arm Cannon that allows the equipped beam type to be charged for higher damage output.", "gain_amount": 1}, 
	Upgrade.ETANK: {"name": "Energy Tank", "description": "A vital component of the Power Suit. Increases energy capacity by 100.", "gain_amount": 1}, 
	Upgrade.VARIA: {"name": "Varia Suit", "description": "Increases the heat-resisting ability of the Power Suit, allowing its wearer to traverse heated environments", "gain_amount": 1},
	Upgrade.GRAVITY: {"name": "Gravity Suit", "description": "Allows the wearer to move freely within fluids. Inherits and improves the heat-resisting ability of the Varia suit.", "gain_amount": 1}, 
	Upgrade.HIGHJUMP: {"name": "High Jump Boots", "description": "Significantly improves the Power Suit's maximum jump height", "gain_amount": 1}, 
	Upgrade.ICEBEAM: {"name": "Ice Beam", "description": "Instantly freezes small objects such as creatures and projectiles on contact, increasing their vulnerability and allowing them to be used as platforms.", "gain_amount": 1}, 
	Upgrade.MISSILE: {"name": "Missiles", "description": "Basic explosive projectile. Capable of dealing high damage in a small radius upon contact.", "gain_amount": 5}, 
	Upgrade.MORPHBALL: {"name": "Morph Ball", "description": "Highly advanced Chozo invention which allows the user to become small and round. Enables use of certain weapons including bombs.", "gain_amount": 1}, 
	Upgrade.PLASMABEAM: {"name": "Plasma Beam", "description": "Beam with an extremely damage output. Able to through multiple entities while maintaining energy, only dissipating upon contact with a solid surface.", "gain_amount": 1}, 
	Upgrade.POWERBOMB: {"name": "Power Bombs", "description": "The most powerful weapon known to be created by the Chozo. Anything caught in the large blast radius is likely to sustain extreme damage.", "gain_amount": 1}, 
	Upgrade.POWERGRIP: {"name": "Power Grip", "description": "Utility feature of the Power Suit which allows the weared to grab onto ledges, and then climb up onto the surface at any time.", "gain_amount": 1}, 
	Upgrade.SCREWATTACK: {"name": "Screw Attack", "description": "", "gain_amount": 1}, 
	Upgrade.SPACEJUMP: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}, 
	Upgrade.SPAZERBEAM: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}, 
	Upgrade.SPEEDBOOSTER: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}, 
	Upgrade.SPIDERBALL: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}, 
	Upgrade.SPRINGBALL: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}, 
	Upgrade.SUPERMISSILE: {"name": "Super Missiles", "description": "", "gain_amount": 5}, 
	Upgrade.WAVEBEAM: {"name": "PlasmaBeam", "description": "", "gain_amount": 1}
}

