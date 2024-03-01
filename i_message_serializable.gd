## Representa um tipo que pode ser adicionado e recuperado de mensagens usando `Message.add_serializable(T)` e `Message.get_serializable` metodos.
class_name IMessageSerializable


## Adiciona o tipo a mensagem.
## - `_message`: A mensagem para adicionar o tipo.
func _serialize(_message: Message) -> void:
	pass


## Recupera o tipo da mensagem.
## - `_message`: A mensagem da qual recuperar o tipo.
func _deserialize(_message: Message) -> void:
	pass
