# No progeto do cliente class Message_panel
extends PanelContainer

@onready var _message_text_edit : TextEdit = $VBoxContainer/MessageTextEdit

func _on_send_button_button_up():
	#rpc("receive_chat_message", multiplayer.get_unique_id(), _message_text_edit.text)
	NetworkManager.receive_chat_message.rpc_id(1, multiplayer.get_unique_id(),_message_text_edit.text)




