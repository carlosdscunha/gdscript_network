## Reenvia um `PendingMessage` quando invocado.
class_name PendingMessageResendEvent
extends DelayedEvent

## A mensagem a ser reenviada.
var message: PendingMessage
## A hora em que o evento de reenvio foi colocado na fila.
var initiated_at_time: int


## Inicializa o evento.
func _init(_message: PendingMessage, _initiated_at_time: int):
	message = _message
	initiated_at_time = _initiated_at_time


func invoke() -> void:
	if initiated_at_time == message.last_send_time:
		message.retry_send()
