# No progeto do servidor class ServerManager
extends Node

const DEFAULT_PORT := 7777
const MAX_PLAYERS : int = 4

var selected_port := DEFAULT_PORT
var selected_max_player := MAX_PLAYERS

func _ready():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(selected_port, selected_max_player)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	multiplayer.server_disconnected.connect(_server_disconnected)
	
	print("Servidor iniciado")



func _player_connected(id):
	print("Novo jogador conectado:", id)

func _player_disconnected(id):
	print("Jogador desconectado:", id)

func _server_disconnected():
	print("Servidor desconectado")

# Função para receber mensagens de chat dos clientes e distribuí-las para todos os clientes
@rpc("any_peer","call_remote","reliable",2)
func receive_chat_message(sender_id, message):
	print("Mensagem recebida de", sender_id, ":", message)
