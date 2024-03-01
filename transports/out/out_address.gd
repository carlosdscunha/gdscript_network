class_name OutAddress

var is_success: bool
var ip: String
var port: int
## `"IPv4"` or `"IPv6"`
var address_family: String


func _init(_is_success: bool = false, _ip: String = "", _port: int = 0):
	is_success = _is_success
	ip = _ip
	port = _port
	address_family = ""


func to_dictionary() -> Dictionary:
	return {"is success": is_success, "ip": ip, "port": port, "address family": address_family}
