extends Node

signal peer_connected(id)
signal peer_disconnected(id)
signal connection_failed()
signal connected_to_server()

var network := null
const PORT := 12345
var host_ip := "127.0.0.1" # Default for local testing

func host_game():
	network = NetworkedMultiplayerENet.new()
	network.create_server(PORT, 2)
	get_tree().set_network_peer(network)
	print("[NetworkingManager] Hosting game on port %d" % PORT)

func join_game(ip := "127.0.0.1"):
	host_ip = ip
	network = NetworkedMultiplayerENet.new()
	network.create_client(host_ip, PORT)
	get_tree().set_network_peer(network)
	print("[NetworkingManager] Joining host at %s:%d" % [host_ip, PORT])

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_peer_connected")
	get_tree().connect("network_peer_disconnected", self, "_on_peer_disconnected")
	get_tree().connect("connection_failed", self, "_on_connection_failed")
	get_tree().connect("connected_to_server", self, "_on_connected_to_server")

func _on_peer_connected(id):
	emit_signal("peer_connected", id)
	print("[NetworkingManager] Peer connected: %s" % id)

func _on_peer_disconnected(id):
	emit_signal("peer_disconnected", id)
	print("[NetworkingManager] Peer disconnected: %s" % id)

func _on_connection_failed():
	emit_signal("connection_failed")
	print("[NetworkingManager] Connection failed!")

func _on_connected_to_server():
	emit_signal("connected_to_server")
	print("[NetworkingManager] Connected to server!")
