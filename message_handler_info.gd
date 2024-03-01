## Especifica um metodo como manipulador de mensagens para mensagens com o ID fornecido.
class_name MessageHandlerInfo
extends GetInfo

## O ID do tipo de mensagem que este metodo deve manipular.
var message_id: int
## O ID do grupo de manipuladores de mensagens ao qual este metodo pertence.
var group_id: int
## O callable para o manipulador de mensagens.
var function: Callable


## - `_message_id`: O ID da mensagem que este metodo deve manipular.
## - `_function`: O callable para o manipulador de mensagens.
## - `is_reliable`: Indica se a mensagem e confiavel (true) ou nao confiavel (false).
## - `is_server`: Indica se e um servidor (true) ou se e para um cliente (false).
func _init(_message_id: int, _function: Callable, _group_id: int = 0):
	type_name = "MessageHandlerInfo"

	message_id = _message_id
	function = _function
	group_id = _group_id


func _get_to_dictionary() -> Dictionary:
	var info_dict = {
		"message_id": message_id,
		"group_id": group_id,
		"function": function,
		"type_name": type_name,
	}

	return info_dict
