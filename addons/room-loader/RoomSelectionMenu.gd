tool
extends PopupMenu

signal submenu_id_pressed

func add_submenu_item(label: String, submenu: String, id: int = -1):
	.add_submenu_item(label, submenu, id)
	
	if not get_node(submenu).is_connected("id_pressed", self, "_submenu_id_pressed"):
		get_node(submenu).connect("id_pressed", self, "_submenu_id_pressed", [submenu])

func _submenu_id_pressed(id: int, submenu: PopupMenu):
	emit_signal("submenu_id_pressed", id, submenu)
