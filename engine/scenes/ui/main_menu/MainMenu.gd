extends Control

var Samus: KinematicBody2D

func _ready():
	var save_point: Dictionary = Loader.Save.get_data_key(["save_point"])
	Loader.load_room(save_point["room_id"], true, {"preview": true})
#	yield(play_spawn_animation(save_point), "completed")
	queue_free()

func play_spawn_animation(save_point: Dictionary):
	Notification.allow_new_notifications = false
	Notification.clear_all()
	Samus = Loader.Samus
	Samus.visible = false
	Samus.paused = true
	
	yield(Loader.current_room.save_stations[save_point["save_station_id"]].spawn_samus(), "completed")
	Notification.allow_new_notifications = true
