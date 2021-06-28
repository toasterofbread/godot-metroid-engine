extends StaticBody2D

func damage(type: int, amount: int, _impact_position):
#	if amount <= 0:
#		return
#	if type in [Enums.DamageType.MISSILE, Enums.DamageType.SUPERMISSILE]:
#		get_parent().get_node("Ice/ShardEmitter").shatter()
	if type in [Enums.DamageType.POWERBOMB, Enums.DamageType.FIRE]:
		get_parent().get_parent().melt_ice()
