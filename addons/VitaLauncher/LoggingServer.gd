extends Node

var logging_server: WebSocketServer = WebSocketServer.new()
var connected: bool = false

var log_file: File = File.new()
var logged_bytes: int = 0
var connected_peers: Array = []

func _ready():
	set_process(false)
	
	if OS.get_name() == "Vita" or true:
		logging_server.connect("client_connected", self, "onClientConnected")
		logging_server.connect("client_disconnected", self, "onClientDisconnected")
		logging_server.connect("client_close_request", self, "onClientCloseRequest")
		startLoggingServer()
		
		log_file.open(ProjectSettings.get_setting("logging/file_logging/log_path"), File.READ)

func _input(event):
	if event.is_action_pressed("fire_weapon"):
		print("FAIYAAAAAAAA!!")

func onClientConnected(id: int, _protocol: String):
	connected_peers.append(id)
	print("(SERVER) Connected to client %s:%d" % [logging_server.get_peer_address(id), logging_server.get_peer_port(id)])

func onClientDisconnected(id: int, clean: bool):
	connected_peers.erase(id)
	print("(SERVER) Client %d disconnected (clean: %s)" % [id, clean])

func onClientCloseRequest(id: int, code: int, reason: String):
	print("(SERVER) Client %d requested a close (code: %d, reason: %s)" % [id, code, reason])

func _process(_delta: float):
	if log_file.is_open() and log_file.get_len() > logged_bytes:
		log_file.seek(logged_bytes)
		logMessage(log_file.get_buffer(log_file.get_len() - logged_bytes).get_string_from_utf8().trim_suffix("\n"))
		logged_bytes = log_file.get_len()
	
	logging_server.poll()

func startLoggingServer():
	if logging_server.is_listening():
		return true

	var error: int = logging_server.listen(VitaLauncher.LOGGING_PORT)
	if error == OK:
		set_process(true)
		
		var ip: String = "127.0.0.1"
		if OS.get_name() == "Vita":
			ip = IP.get_local_addresses()[0]
		else:
			var ips: Array = IP.get_local_addresses()
			for i in range(len(ips) - 1, -1, -1):
				if ips[i].count(".") == 3:
					ip = ips[i]
					break
		
		DebugMenu.log("Logging server started successfully at %s:%d\n" % [ip, VitaLauncher.LOGGING_PORT])
	else:
		DebugMenu.log("Could not start logging server on port %d (error %d)" % [VitaLauncher.LOGGING_PORT, error])

func logMessage(msg):
	if not startLoggingServer():
		return
	
	for peer in connected_peers:
		var error: int = logging_server.get_peer(peer).put_packet(str(msg).to_utf8())
		print("REQUEST SENT (%d)" % error)

func onDisconnected(clean: bool):
	print("Connection to server closed (clean: %b)" % clean)

func onConnected(_protocol: String):
	logMessage("Vita logger running")
