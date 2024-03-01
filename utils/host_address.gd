class_name HostAddress

var ip: String
var port: int


func _init(_ip: String, _port: int):
	ip = _ip
	port = _port


func to_address() -> String:
	return ip + ":" + str(port)


func try_parse_port(portString: String):
	var _port = portString.to_int()
	if _port != null:
		port = _port
		return [_port > 0 and _port <= 65535, _port]

	return [false, 0]  # Ou qualquer outro valor de retorno padrao
