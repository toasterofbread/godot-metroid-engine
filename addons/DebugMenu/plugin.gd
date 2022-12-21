tool
extends EditorPlugin

const PLUGIN_NAME: String = "DebugMenu"
var PLUGIN_DIR: String = get_script().resource_path.get_base_dir()

func _enter_tree():
	add_autoload_singleton(PLUGIN_NAME, PLUGIN_DIR + "/Overlay.tscn")

func _exit_tree():
	remove_autoload_singleton(PLUGIN_NAME)
