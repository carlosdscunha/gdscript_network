class_name GetFunctionInfo
extends GetInfo

var value: Callable
var function_name: String
var declaring_type_name: String
var mh_info: MessageHandlerInfo


func _init(
	_value: Callable,
	_function_name: String,
	_declaring_type_name: String,
	_mh_info: MessageHandlerInfo
):
	type_name = "GetFunctionInfo"
	value = _value
	function_name = _function_name
	declaring_type_name = _declaring_type_name
	mh_info = _mh_info


func _get_to_dictionary() -> Dictionary:
	var info_dict = {
		"value": value,
		"function_name": function_name,
		"mh_info": mh_info._get_to_dictionary(),
		"declaring_type_name": declaring_type_name,
		"type_name": type_name,
	}

	return info_dict
