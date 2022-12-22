tool
extends Control
class_name VitaLauncher

const LOGGING_PORT: int = 7413
const FTP_PORT: int = 1337
const LOG_MSG_PARAM: String = "message"
const LOGGER_SINGLETON_NAME: String = "VitaLogger"
const POPUP_SIZE: Vector2 = Vector2(300, 100)
const LAUNCH_STEPS: float = 4.0

onready var icon: TextureRect = $HBoxContainer/Icon
onready var launch_button: Button = $HBoxContainer/LaunchButton
onready var logging_button: Button = $HBoxContainer/LoggingButton

onready var ip_popup: ConfirmationDialog = $VitaIPDialog
onready var progress_popup: PopupDialog = $ProgressDialog
onready var notification_popup: AcceptDialog = $NotificationDialog

var logging_client: WebSocketClient = WebSocketClient.new()
var client_connected: bool = false

var plugin_path: String = null
var vita_ip: String = ""

func init(plugin_path: String):
	self.plugin_path = plugin_path
	
	logging_client.connect("data_received", self, "onServerDataReceived")
	logging_client.connect("connection_established", self, "onConnected")
	logging_client.connect("connection_closed", self, "onDisconnected")
	logging_client.connect("connection_error", self, "onDisconnected", [false])

func _ready():
	icon.texture = load(plugin_path + "/icon.png")
	launch_button.icon = get_icon("Navigation2D", "EditorIcons")
	logging_button.icon = get_icon("RichTextLabel", "EditorIcons")
	
	launch_button.connect("pressed", self, "onLaunchButtonPressed")
	logging_button.connect("pressed", self, "onLoggingButtonPressed")
	
	connect("tree_exiting", logging_client, "disconnect_from_host")

func onConnected(_protocol: String):
	print("(CLIENT) Connected to Vita at %s:%d" % [vita_ip, LOGGING_PORT])

func onDisconnected(clean: bool):
	print("(CLIENT) Disconnected from Vita (clean: %s)" % clean)

func onLaunchButtonPressed():
	var ip: String = yield(getVitaIP(), "completed")
	if ip.empty():
		return
	
	progress_popup.popup_centered(POPUP_SIZE)
	
	yield(progress_popup.updateProgress(0, "Getting export preset"), "completed")
	
	var export_preset: Dictionary = VitaExportUtils.getExportPreset()
	if "error" in export_preset:
		progress_popup.hide()
		notify(export_preset["error"], true)
		return
	
	yield(progress_popup.updateProgress(1/LAUNCH_STEPS, "Checking for installed app"), "completed")
	
	var titleids = VitaExportUtils.getInstalledTitleids(ip, FTP_PORT)
	if titleids is String:
		progress_popup.hide()
		notify(titleids, true)
		return
	
	var export_vpk: bool = not export_preset["titleid"] in titleids
	var export_path: String = export_preset["export_path"].get_basename() + (".vpk" if export_vpk else ".pck")
	var export_type: String = "VPK" if export_vpk else "PCK"
	
	yield(progress_popup.updateProgress(2/LAUNCH_STEPS, "Exporting %s" % export_type), "completed")
	
	var error = VitaExportUtils.exportProject(export_vpk, export_preset)
	if not error.empty():
		progress_popup.hide()
		notify(error, true)
		return
	
	OS.execute("bash", ["-c", "echo 'destroy' | nc %s %s" % [ip, 1338]])
	
	yield(progress_popup.updateProgress(3/LAUNCH_STEPS, "Uploading %s" % export_type), "completed")
	
	var upload_path: String = "ftp://%s:%d/ux0:/" % [ip, FTP_PORT]
	if not export_vpk:
		upload_path = upload_path.plus_file("app").plus_file(export_preset["titleid"]).plus_file("game_data").plus_file("game.pck")
	
	var output: Array = []
	error = OS.execute("curl", [
		"-T", export_path, upload_path
	], true, output, true)
	
	if error != OK:
		progress_popup.hide()
		notify("Could not upload %s to %s (%d)\nIs an FTP server running on the Vita?" % [export_path, upload_path, error], true)
		return
	
	if export_vpk:
		yield(notify("Project VPK must be installed manually at least once before PCK can be updated automatically.\nVPK file has been uploaded to ux0:/%s" % export_preset["export_path"].get_file()), "completed")
	else:
		OS.execute("bash", ["-c", "echo 'launch %s' | nc %s %s" % [export_preset["titleid"], ip, 1338]])
	
	yield(progress_popup.updateProgress(1, "Done"), "completed")
	progress_popup.hide()

func onLoggingButtonPressed():
	var ip: String = yield(getVitaIP(), "completed")
	if not ip.empty():
		connectLoggingClient(ip)

func getVitaIP() -> String:
	if not vita_ip.empty():
		yield(get_tree(), "idle_frame")
		return vita_ip
	
	ip_popup.popup_exclusive = true
	ip_popup.popup_centered(POPUP_SIZE)
	
	var result: Array = yield(ip_popup, "COMPLETED")
	if result.empty():
		return ""
	
	var ip: String = result[0].strip_edges().split(":", true, 1)[0]
	var remember: bool = result[1]
	
	var regex: RegEx = RegEx.new()
	regex.compile("^((25[0-5]|(2[0-4]|1\\d|[1-9]|)\\d)\\.?\\b){4}$")
	if not regex.search(ip):
		notify("Invalid IP address %s" % ip, true)
		return vita_ip
	
	if remember:
		vita_ip = ip
	return ip

func connectLoggingClient(ip: String):
	if client_connected:
		return true
	
	var error: int = logging_client.connect_to_url("http://%s:%d" % [ip, LOGGING_PORT])
	if error != OK:
		push_error("Error %d while connecting to server at %s:%d" % [error, ip, LOGGING_PORT])
		return false
	
	print("yay?")
	
#	while not logging_server.get_peer(1).is_connected_to_host():
#		yield(get_tree(), "idle_frame")
	
	client_connected = true
	set_process(true)
	
	return true

func stopLoggingServer():
	set_process(false)
	logging_client.stop()
	print("Stopped logging")

func _process(_delta: float):
	logging_client.poll()

func onServerDataReceived():
	var packet: PoolByteArray = logging_client.get_peer(1).get_packet()
	print("(CLIENT) Received message: ", packet.get_string_from_utf8())

func notify(msg, error: bool = false):
	if error:
		push_error(str(msg))
	
	notification_popup.window_title = "Error" if error else "Notification"
	notification_popup.dialog_text = str(msg)
	notification_popup.popup_centered(POPUP_SIZE)
	yield(notification_popup, "popup_hide")
