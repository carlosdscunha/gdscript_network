class_name ArgumentException
var message: String


func _init(param_name: String, _message: String = ""):
	if _message != "":
		message = "Argument exception: " + param_name + " - " + message
	else:
		message = "Argument exception: " + message
