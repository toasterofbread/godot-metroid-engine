tool
extends EditorPlugin

var menu: Control = null
var path: String = get_script().resource_path.get_base_dir()

func _enter_tree():
	menu = preload("Launcher.tscn").instance()
	menu.init(path)
	add_control_to_container(CONTAINER_TOOLBAR, menu)
	
	add_autoload_singleton(VitaLauncher.LOGGER_SINGLETON_NAME, path + "/LoggingServer.gd")

func _exit_tree():
	if menu:
		remove_control_from_container(CONTAINER_TOOLBAR, menu)
		menu.queue_free()
	remove_autoload_singleton(VitaLauncher.LOGGER_SINGLETON_NAME)
