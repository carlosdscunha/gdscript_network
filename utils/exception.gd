class_name Exception
extends Error

var innerException: Exception = null


func _init(_message: String, _innerException: Exception = null) -> void:
	super._init("Exception", _message)
	innerException = _innerException


func tostring() -> String:
	if innerException != null:
		return "Exception: " + message + "\nInner Exception: " + innerException.tostring()
	else:
		return "Exception: " + message
