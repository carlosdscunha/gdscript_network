class_name Error

var name: String = ""
var message: String = ""
var stack: String = ""


func _init(_name: String, _message: String, _stack: String = "") -> void:
	name = _name
	message = _message
	stack = _stack
