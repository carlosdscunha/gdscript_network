## Executa uma pulsacao quando invocado.
class_name HeartbeatEvent
extends DelayedEvent

## O par cujo coracao deve bater.
var peer: Peer


## Inicializa o evento.
## - `_perr` O par cujo coracao deve bater.
func _init(_peer: Peer):
	peer = _peer


func invoke() -> void:
	peer._heartbeat()
