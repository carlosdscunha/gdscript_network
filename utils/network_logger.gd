class_name NetworkLogger

static var log_methods: Dictionary
static var include_timestamps: bool = false
static var timestamp_format: String = "{HH}:{mm}:{ss}"

static var is_warning_logging_enabled: bool = false


func _init(
	info_method: Callable,
	debug_method: Callable,
	warning_method: Callable,
	error_method: Callable,
	throw_method: Callable,
	_include_timestamps: bool = false,
	_timestamp_format: String = "{HH}:{mm}:{ss}"
) -> void:
	
	
	if not debug_method.is_null():
		log_methods = {
			Enums.LogTypes.DEBUG: debug_method,
			Enums.LogTypes.INFO: info_method,
			Enums.LogTypes.WARNING: warning_method,
			Enums.LogTypes.ERROR: error_method,
			Enums.LogTypes.THROW: throw_method,
		}
		is_warning_logging_enabled = true
	else:
		log_methods = {
			Enums.LogTypes.INFO: info_method,
		}

	include_timestamps = _include_timestamps
	timestamp_format = _timestamp_format
		


static func enable_logging_for(log_type: Enums.LogTypes, log_method: Callable) -> void:
	log_methods[log_type] = log_method


static func disable_logging_for(log_type: Enums.LogTypes) -> void:
	log_methods.erase(log_type)


static func Log(log_type: Enums.LogTypes, message: String, log_name: String = "") -> void:
	if log_methods.has(log_type):
		var log_method = log_methods[log_type]
		var timestamped_message = ""

		if include_timestamps:
			var timestamp = get_timestamp()
			timestamped_message = "[" + timestamp + "]: "

		if log_name != "":
			timestamped_message += "(" + log_name + "): "

		timestamped_message += message
		log_method.call([timestamped_message])


static func get_timestamp() -> String:
	var time_dict = Time.get_time_dict_from_system()
	return timestamp_format.format(
		{"HH": time_dict.hour, "mm": time_dict.minute, "ss": time_dict.second}
	)


static func table(data: Variant, properties: PackedStringArray = PackedStringArray()):
	if data.is_empty():
		return

	match typeof(data):
		TYPE_ARRAY:
			var dic: Dictionary = data[0]
			var keys: PackedStringArray = ArrayUtil.find_key_from_properties(dic, properties)
			if keys.is_empty():
				return

			var start_index: String = "(index)"

			var max_data_length: Dictionary = {"start_index": start_index.length()}

			for i in range(data.size()):
				var entry: Dictionary = data[i]

				if str(i).length() > max_data_length["start_index"]:
					max_data_length["start_index"] = str(i).length()
				for key in ArrayUtil.find_key_from_properties(entry, properties):
					var value_var: Variant = entry[key]
					var value_length: int = type_length(value_var)

					if not max_data_length.has(key) or value_length > max_data_length[key]:
						max_data_length[key] = value_length

			var header_row := "║"
			header_row += format_escape_int(start_index, max_data_length["start_index"])
			max_data_length["start_index"] = header_row.length() - 1

			for i in range(keys.size()):
				var key := keys[i]
				header_row += "║"
				var old_length: int = header_row.length()
				header_row += format_escape_int(key, max_data_length[key])
				max_data_length[key] = header_row.length() - old_length
			header_row += "║"

			var top_row := "╔"
			for __ in range(max_data_length["start_index"]):
				top_row += "═"
			top_row += "╦"

			var top_index: int = 0
			for key in keys:
				top_index += 1
				for __ in range(max_data_length[key]):
					top_row += "═"
				if top_index < keys.size():
					top_row += "╦"
				else:
					top_row += "╗"
			print_rich("[b]" + top_row + "[/b]")

			print_rich("[b]" + header_row + "[/b]")

			var mid_row = "╠"
			for __ in range(max_data_length["start_index"]):
				mid_row += "═"
			mid_row += "╬"

			var mid_index: int = 0
			for key in keys:
				mid_index += 1
				for __ in range(max_data_length[key]):
					mid_row += "═"
				if mid_index < keys.size():
					mid_row += "╬"
				else:
					mid_row += "╣"
			print_rich("[b]" + mid_row + "[/b]")

			for i in range(data.size()):
				var entry: Dictionary = data[i]
				var data_row := "║"
				data_row += format_escape_string(i, max_data_length["start_index"])

				for key in ArrayUtil.find_key_from_properties(entry, properties):
					var value_string: Variant = entry.get(key)
					data_row += "║"
					data_row += format_escape_string(value_string, max_data_length[key])
				data_row += "║"
				print_rich("[b]" + data_row + "[/b]")
				if i != data.size() - 1:
					print_rich("[b]" + mid_row + "[/b]")
			var botton_row := "╚"

			for __ in range(max_data_length["start_index"]):
				botton_row += "═"
			botton_row += "╩"

			var botton_index: int = 0
			for key in keys:
				botton_index += 1
				for __ in range(max_data_length[key]):
					botton_row += "═"
				if botton_index < keys.size():
					botton_row += "╩"
				else:
					botton_row += "╝"
			print_rich("[b]" + botton_row + "[/b]")
		TYPE_DICTIONARY:
			var dic: Dictionary = data
			var keys: PackedStringArray = ArrayUtil.find_key_from_properties(dic, properties)

			var max_data_length: Dictionary = {}

			for key in keys:
				var value_var: Variant = dic[key]

				var value_length: int = type_length(value_var)

				if not max_data_length.has(key) or value_length > max_data_length[key]:
					max_data_length[key] = value_length


			var header_row := ""
			for key in keys:
				header_row += "║"
				var old_length: int = header_row.length()
				header_row += format_escape_int(key, max_data_length[key])
				max_data_length[key] = header_row.length() - old_length

			header_row += "║"

			var top_row := "╔"

			var top_index: int = 0
			for key in keys:
				top_index += 1
				for __ in range(max_data_length[key]):
					top_row += "═"
				if top_index < keys.size():
					top_row += "╦"
				else:
					top_row += "╗"
			print_rich("[b]" + top_row + "[/b]")

			print_rich("[b]" + header_row + "[/b]")

			var mid_row = "╠"

			var mid_index: int = 0
			for key in keys:
				mid_index += 1
				for __ in range(max_data_length[key]):
					mid_row += "═"
				if mid_index < keys.size():
					mid_row += "╬"
				else:
					mid_row += "╣"
			print_rich("[b]" + mid_row + "[/b]")

			var data_row := ""

			for key in keys:
				var value_var: Variant = dic[key]
				data_row += "║"
				data_row += format_escape_string(value_var, max_data_length[key])
			data_row += "║"
			print_rich("[b]" + data_row + "[/b]")

			var botton_row := "╚"

			var botton_index: int = 0
			for key in keys:
				botton_index += 1
				for __ in range(max_data_length[key]):
					botton_row += "═"
				if botton_index < keys.size():
					botton_row += "╩"
				else:
					botton_row += "╝"
			print_rich("[b]" + botton_row + "[/b]")

		_:
			log_warning(["o tipo de dados nao e valido (ou seja, nao e um dicionario)."])


static func format_escape_string(value: Variant, max_space: int) -> String:
	var escape: String = ""

	var space_to_add: int = type_length(value, max_space)

	if space_to_add > 0:
		var left_space: int = int(float(space_to_add) / 2)
		var right_space: int = space_to_add - left_space

		for i in range(left_space):
			escape += " "
		escape += type_to_color(value)
		for i in range(right_space):
			escape += " "
	else:
		escape = type_to_color(value)

	return escape


static func format_escape_int(value: String, max_space: int = 0) -> String:
	var middle_index: int = int(float(max_space) / 2)
	var escape = ""
	for i in range(middle_index):
		escape += " "
	escape += value
	for i in range(middle_index):
		escape += " "
	return escape


static func type_length(value: Variant, max_space: int = 0) -> int:
	var value_str: String = ""

	if max_space == 0:
		match typeof(value):
			TYPE_STRING:
				var text: String = value
				value_str = '"' + text + '"'
			TYPE_COLOR:
				value_str = "  __  "
			TYPE_ARRAY:
				var array: Array = value
				value_str = get_limited_array_string(array, 2)
			TYPE_DICTIONARY:
				var dic: Dictionary = value
				value_str = get_limited_dictionary_string(dic, 3)
			TYPE_OBJECT:
				var _class: GetInfo = value
				var name := _class.type_name
				if name and name.length() > 0:
					value_str = (
						"  [class "
						+ name
						+ "] list: "
						+ get_limited_dictionary_string(_class._get_to_dictionary(), 3)
						+ "  "
					)
				else:
					value_str = "  [class Unknown]  "
			TYPE_PACKED_BYTE_ARRAY:
				var byte_array: PackedByteArray = value
				value_str = "  [PackedByteArray, len: " + str(byte_array.size()) + "]  "
			TYPE_CALLABLE:
				var callable: Callable = value
				value_str = str(callable)
			TYPE_NIL:
				value_str = " null "
			_:
				value_str = " " + str(value) + " "

		return len(value_str)

	else:
		match typeof(value):
			TYPE_STRING:
				var text: String = value
				value_str = '"' + text + '"'
			TYPE_COLOR:
				value_str = "__"
			TYPE_ARRAY:
				var array: Array = value
				value_str = get_limited_array_string(array, 2)
			TYPE_DICTIONARY:
				var dic: Dictionary = value
				value_str = get_limited_dictionary_string(dic, 3)
			TYPE_OBJECT:
				var _class: GetInfo = value
				var name := _class.type_name
				if name and name.length() > 0:
					value_str = (
						"[class "
						+ name
						+ "] list: "
						+ get_limited_dictionary_string(_class._get_to_dictionary(), 3)
					)
				else:
					value_str = "[class Unknown]"
			TYPE_PACKED_BYTE_ARRAY:
				var byte_array: PackedByteArray = value
				value_str = "[PackedByteArray, len: " + str(byte_array.size()) + "]"
			TYPE_CALLABLE:
				var callable: Callable = value
				value_str = str(callable)
			TYPE_NIL:
				value_str = "null"
			_:
				value_str = str(value)

		return max_space - len(value_str)


static func type_to_color(value: Variant) -> String:
	var value_string := str(value)

	match typeof(value):
		TYPE_STRING:
			value_string = "[color=green]" + '"' + value + '"' + "[/color]"
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL:
			value_string = "[color=#4BBBF5]" + value_string + "[/color]"  # Lighter shade of blue
		TYPE_VECTOR2, TYPE_RECT2, TYPE_VECTOR3, TYPE_AABB, TYPE_BASIS:
			value_string = "[color=orange]" + value_string + "[/color]"
		TYPE_TRANSFORM2D, TYPE_TRANSFORM3D:
			value_string = "[color=purple]" + value_string + "[/color]"
		TYPE_COLOR:
			value_string = "[fgcolor=#" + value.to_html() + "]" + "__" + "[/fgcolor]"
		TYPE_ARRAY:
			var array: Array = value
			value_string = "[color=yellow]" + get_limited_array_string(array, 2) + "[/color]"
		TYPE_DICTIONARY:
			var dic: Dictionary = value
			value_string = "[color=#FF615B]" + get_limited_dictionary_string(dic, 3) + "[/color]"
		TYPE_OBJECT:
			var _class: GetInfo = value
			var name := _class.type_name
			if name and name.length() > 0:
				value_string = (
					"[color=cyan]"
					+ "[class "
					+ name
					+ "] list: [color=#FF615B]"
					+ get_limited_dictionary_string(_class._get_to_dictionary(), 3)
					+ "[/color]"
					+ "[/color]"
				)
			else:
				value_string = "[color=cyan]" + "[class Unknown]" + "[/color]"
		TYPE_PACKED_BYTE_ARRAY:
			value_string = (
				"[color=gray]" + "[PackedByteArray, len: " + str(value.size()) + "]" + "[/color]"
			)
		TYPE_NIL:
			value_string = "[color=white]" + "null" + "[/color]"
		TYPE_CALLABLE:
			var callable: Callable = value
			value_string = "[color=#ADF55B]" + str(callable) + "[/color]"
		_:
			value_string = "[color=black]" + value_string + "[/color]"

	return value_string


static func get_limited_array_string(arr: Array, limit: int) -> String:
	var array_str: String = "Array["
	var count: int = 0

	for i in range(arr.size()):
		if count >= limit:
			break

		if count > 0:
			array_str += ", "

		if typeof(arr[i]) == TYPE_STRING:
			array_str += '"' + str(arr[i]) + '"'
		else:
			array_str += str(arr[i])

		count += 1

	if arr.size() > limit:
		array_str += ", ..."

	array_str += "]"

	return array_str


static func get_limited_dictionary_string(dic: Dictionary, limit: int = -1) -> String:
	var dict_str: String = "Dictionary{"

	var count: int = 0
	if limit == -1 or limit > dic.size():
		limit = dic.size()

	for key in dic.keys():
		if count >= limit:
			break

		if count > 0:
			dict_str += ", "

		dict_str += '"' + str(key) + '"' + " = "

		if typeof(dic[key]) == TYPE_STRING:
			dict_str += "'" + str(dic[key]) + "'"
		else:
			dict_str += str(dic[key])

		count += 1

	if dic.size() > limit:
		dict_str += ", ..."

	dict_str += "}"

	return dict_str

static func to_tabel(dic: Dictionary, group_id: int):
	print_rich("[b]══════ START ══════[/b]")
	NetworkLogger.table({"GROPU ID": group_id})
	for key in dic.keys():
		NetworkLogger.table(dic[key]._get_to_dictionary(), [ "mh_info"])
	print_rich("[b]══════ END ══════[/b]\n\n\n")

static func log_debug(l: PackedStringArray) -> void:
	var frames := get_stack()
	var message :String =""

	if frames.size() > 0:
		var frame = frames[2]
		var source: String = frame["source"]
		if source.begins_with("res://"):
			source = source.substr(6)  # Remove 'res://'
		var line: String = str(frame["line"])
		var function: String = str(frame["function"])
		message = "[DEBUG][" + source + ":" + line + " @ " + function + "()]: "
	else:
		message = "[DEBUG]: "
	
	if Logger.singleton:
		Logger.singleton.log(
			(
				"[color=orange][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
	else:
		print_rich(
			(
				"[color=orange][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
			


static func log_info(l: PackedStringArray) -> void:
	var frames := get_stack()
	var message :String =""

	if frames.size() > 0:
		var frame = frames[2]
		var source: String = frame["source"]
		if source.begins_with("res://"):
			source = source.substr(6)  # Remove 'res://'
		var line: String = str(frame["line"])
		var function: String = str(frame["function"])
		message = "[INFO][" + source + ":" + line + " @ " + function + "()]: "
	else:
		message = "[INFO]: "

	if Logger.singleton:
		Logger.singleton.log(
			(
				"[color=green][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
	else:
		print_rich(
			(
				"[color=green][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
			


static func log_warning(l: PackedStringArray, frame_index: int = 2) -> void:
	var frames := get_stack()
	var message :String =""

	if frames.size() > 0:
		var frame = frames[frame_index]
		var source: String = frame["source"]
		if source.begins_with("res://"):
			source = source.substr(6)  # Remove 'res://'
		var line: String = str(frame["line"])
		var function: String = str(frame["function"])
		message = "[WARNING][" + source + ":" + line + " @ " + function + "()]: "
	else:
		message = "[WARNING]: "

	if Logger.singleton:
		Logger.singleton.log(
			(
				"[color=yellow][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
	else:
		print_rich(
			(
				"[color=yellow][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
			


static func log_error(l: PackedStringArray) -> void:
	var frames := get_stack()
	var message :String =""

	if frames.size() > 0:
		var frame = frames[2]
		var source: String = frame["source"]
		if source.begins_with("res://"):
			source = source.substr(6)  # Remove 'res://'
		var line: String = str(frame["line"])
		var function: String = str(frame["function"])
		message = "[ERROR][" + source + ":" + line + " @ " + function + "()]: "
	else:
		message = "[ERROR]: "

	if Logger.singleton:
		Logger.singleton.log(
			(
				"[color=red][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
	else:
		print_rich(
			(
				"[color=red][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)



static func log_throw(l: PackedStringArray) -> void:
	var frames := get_stack()
	var message :String =""

	if frames.size() > 0:
		var frame = frames[2]
		var source: String = frame["source"]
		if source.begins_with("res://"):
			source = source.substr(6)  # Remove 'res://'
		var line: String = str(frame["line"])
		var function: String = str(frame["function"])
		message = "[THROW][" + source + ":" + line + " @ " + function + "()]: "
	else:
		message = "[THROW]: "

	if Logger.singleton:
		Logger.singleton.log(
			(
				"[color=cyan][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)
	else:
		print_rich(
			(
				"[color=cyan][b]"
				+ message
				+ "[/b][/color]"
				+ "[code][b]"
				+ "".join(l)
				+ "[/b][/code]"
			)
		)

	assert(false)
