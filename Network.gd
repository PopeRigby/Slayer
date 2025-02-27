extends Node

const DEFAULT_IP = '192.168.50.10'
const DEFAULT_PORT = 31400
const MAX_PLAYERS = 5

var players = { }
var start_position = Vector2(360,180)
var self_data = {name = '', position = Vector2(), received_disconnect=false}
var disconnected_player_info
var connected_player_info
var connected_player
var disconnected

signal player_disconnected
signal server_disconnected
signal player_connection_completed
signal player_disconnection_completed
signal server_stopped

func _ready():
	get_tree().connect('network_peer_disconnected', self, '_on_player_disconnected')
	get_tree().connect('network_peer_connected', self, '_on_player_connected')

func create_server(port, player_nickname):
	self_data.name = player_nickname
	players[1] = self_data
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(port, MAX_PLAYERS)
	get_tree().set_network_peer(peer)

func connect_to_server(ip, port, player_nickname):
	self_data.name = player_nickname
	get_tree().connect('connected_to_server', self, '_connected_to_server')
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(ip, port)
	get_tree().set_network_peer(peer)
	
func close_server():
	for player in players:
		if player != 1:
			kick_player(player, "Server Closed")
	emit_signal("server_stopped")
	get_tree().set_network_peer(null)

func kick_player(player, reason):
	rpc_id(player, "kicked", reason)
	get_tree().network_peer.disconnect_peer(player)
	
remote func kicked(reason):
	Global.kick_reason = reason 
	get_parent().get_node("GameController").get_node(str(get_tree().get_network_unique_id())).get_node("Camera2D").make_current()
	get_tree().change_scene("res://MainMenu.tscn")
	emit_signal("player_disconnection_completed", get_tree().get_network_unique_id())
	get_tree().set_network_peer(null)
	
func update_position(id, position):
	players[id].position = position
	
func _connected_to_server():
	var local_player_id = get_tree().get_network_unique_id()
	players[local_player_id] = self_data
	rpc('_send_player_info', local_player_id, self_data)

func _on_player_disconnected(id):
	disconnected_player_info = players[id]
	players.erase(id)

func _on_player_connected(connected_player_id): 
	connected_player = connected_player_id
	var local_player_id = get_tree().get_network_unique_id()
	if not(get_tree().is_network_server()):
		rpc_id(1, '_request_player_info', local_player_id, connected_player_id)
		rpc_id(1, '_request_map', local_player_id)
	  
remote func _request_player_info(request_from_id, player_id):
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_player_info', player_id, players[player_id])

remote func _send_player_info(id, info):
	players[id] = info
	if Network.connected_player in Network.players:
		Network.connected_player_info = Network.players[Network.connected_player]
		emit_signal("player_connection_completed")

remote func _request_players(request_from_id):
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_players', Network.players)
	
remote func _send_players(players_array):
	Network.players = players_array
	
remote func _request_map(request_from_id):
	if get_tree().is_network_server():
		rpc_id(request_from_id, '_send_map', Global.map)
		
remote func _send_map(map):
	Global.map = map
	get_tree().change_scene("res://GameController.tscn")
