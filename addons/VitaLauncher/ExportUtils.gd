extends Node
class_name VitaExportUtils

const CONNECT_TIMEOUT: float = 3.0

static func getExportPreset() -> Dictionary:
	var ret: Dictionary = {}
	var presets: ConfigFile = ConfigFile.new()
	
	var error: int = presets.load("res://export_presets.cfg")
	if error != OK:
		ret["error"] = "Could not open res://exports_presets.cfg, make sure Vita preset has been created (%d)" % error
		return ret
	
	for section in presets.get_sections():
		var path = presets.get_value(section, "export_path")
		if path != null and path.get_extension() == "vpk":
			ret["export_path"] = ProjectSettings.globalize_path("res://").plus_file(path)
			ret["name"] = presets.get_value(section, "name")
			ret["titleid"] = presets.get_value(section + ".options", "param_sfo/title_id")
			return ret
	
	ret["error"] = "Could not find an export preset which exports a .vpk file"
	return ret

static func exportProject(export_vpk: bool, preset: Dictionary = {}, executable_path: String = OS.get_executable_path()) -> String:
	
	if preset.empty():
		preset = getExportPreset()
		if "error" in preset:
			return preset["eror"]
	
	var export_path: String = preset["export_path"].get_basename() + (".vpk" if export_vpk else ".pck")
	
	var output: Array = []
	var error: int = OS.execute(executable_path, [
		"--no-window", 
		"--path", 
		ProjectSettings.globalize_path("res://"),
		"--export" if export_vpk else "--export-pack", 
		preset["name"],
		export_path
	], true, output, true)
	
	if error != OK:
		var msg: String = "Exporting project failed (%d)" % error
		msg += "\nExport preset: %s" % preset["name"]
		msg += "\nExport path: %s" % export_path
		msg += "\nGodot executable path: %s" % executable_path
		for line in output:
			if not line.empty():
				msg += "\nCommand output: %s" % "\n".join(output)
				break
		return msg
	
	return ""

static func getInstalledTitleids(ip: String, port: int): # -> String | PoolStringArray
	var output: Array = []
	var error: int = OS.execute("curl", [
		"ftp://%s:%d/ux0:/app/" % [ip, port], "-s", "--connect-timeout", str(CONNECT_TIMEOUT)
	], true, output, true)
	
	if error != OK:
		return "Could not reach ftp://%s:%d (%d)\nIs an FTP server running on the Vita?" % [ip, port, error]
	
	var ret: PoolStringArray = []
	for line in output[0].split("\n"):
		if line.empty():
			continue
		var start: int = line.find_last(" ") + 1
		ret.append(line.substr(start))
	
	return ret

static func _getAllFiles(path: String, files: Array = []) -> Array:
	
	var dir: Directory = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true)
		var file_name: String = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				files = _getAllFiles(dir.get_current_dir().plus_file(file_name), files)
			else:
				files.append(dir.get_current_dir().plus_file(file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access %s." % path)
	
	return files
