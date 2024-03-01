## A excecao que e lancada quando um metodo com um `MessageHandlerAttribute` nao possui uma assinatura de metodo de manipulador de mensagem aceitavel (seja `Server.message_handler` ou `Client.message_handler`).
class_name InvalidHandlerSignatureException
extends Exception

## O tipo que contem o metodo do manipulador.
var declaring_type_name: String = ""
## O nome do metodo manipulador.
var handler_method_name: String = ""


## Inicializa uma nova instancia `InvalidHandlerSignatureException`.
## - `new(_)`
## - `new(_message: String)`
## - `new(_message: String, _inner: Exception)`
## - `new(_declaring_type_name: String, _handler_method_name: String)`
func _init(
	_message_or_declaring_type_name: Variant = null, _inner_or_handler_method_name: Variant = null
):
	if (
		typeof(_message_or_declaring_type_name) == TYPE_STRING
		and _inner_or_handler_method_name == null
	):
		super._init(_message_or_declaring_type_name)
	elif (
		typeof(_message_or_declaring_type_name) == TYPE_STRING
		and _inner_or_handler_method_name is Exception
	):
		super._init(_message_or_declaring_type_name, _inner_or_handler_method_name)
	elif (
		typeof(_message_or_declaring_type_name) == TYPE_STRING
		and typeof(_inner_or_handler_method_name) == TYPE_STRING
	):
		super._init(
			InvalidHandlerSignatureException._get_error_message(
				_message_or_declaring_type_name, _inner_or_handler_method_name
			)
		)
		declaring_type_name = _message_or_declaring_type_name
		handler_method_name = _inner_or_handler_method_name


## Constroi a mensagem de erro a partir das informacoes fornecidas.
## - `returns`: A mensagem de erro.
static func _get_error_message(
	_declaring_type_name: String, _handler_method_name: String
) -> String:
	return (
		"`"
		+ _declaring_type_name
		+ "."
		+ _handler_method_name
		+ "' nao corresponde a nenhuma assinatura de metodo do manipulador de mensagens aceitavel! Os metodos do manipulador de mensagens do servidor devem ter um parametro 'int' e um 'GDNetwork.Message', enquanto o cliente os metodos do manipulador de mensagens devem ter apenas um parametro 'GDNetwork.Message'."
	)
