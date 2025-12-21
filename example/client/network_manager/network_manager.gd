# No progeto do cliente
extends Node

const DEFAULT_IP := "127.0.0.1"
const DEFAULT_PORT := 7777

var selected_ip := DEFAULT_IP
var selected_port := DEFAULT_PORT

func _ready():
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.connection_failed.connect(_connected_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)
	
	_connect_to_server()

func _connect_to_server():
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(selected_ip, selected_port)
	multiplayer.multiplayer_peer = peer

func _connected():
	print("Conectado ao servidor com sucesso")

func _connected_fail():
	print("Falha ao conectar ao servidor")

func _player_connected(id):
	print("Novo jogador conectado:", id)

func _player_disconnected(id):
	print("Jogador desconectado:", id)

func _server_disconnected():
	print("Servidor desconectado")

@rpc("any_peer","call_remote","reliable",2)
func receive_chat_message(sender_id, message):
	print("Mensagem recebida de", sender_id, ":", message)
