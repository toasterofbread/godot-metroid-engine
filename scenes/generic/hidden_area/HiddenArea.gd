extends Area2D

onready var Samus: KinematicBody2D = Loader.Samus

export(Array, Array) var entered_connections = []
export(Array, Array) var exited_connections = []

func _on_HiddenArea_body_entered(body):
	if body != Samus:
		return
	Global.call_connection_array(self, entered_connections)

func _on_HiddenArea_body_exited(body):
	if body != Samus:
		return
	Global.call_connection_array(self, exited_connections)
