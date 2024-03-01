class_name OutConnect
var is_success: bool
var connection: Connection
var connect_error: String


func _init(_is_success: bool = false, _connection: Connection = null, _connect_error: String = ""):
	is_success = _is_success
	connection = _connection
	connect_error = _connect_error
