class_name ClassLoader

static var class_mapping: Dictionary = {}


static func get_all_classes() -> PackedStringArray:
	var classes: PackedStringArray = PackedStringArray()

	for type_class in ProjectSettings.get_global_class_list():
		var type_name: StringName = type_class["class"]
		if find_script(type_name, type_class["path"]):
			classes.append(type_name)

	if classes.size() == 0:
		NetworkLogger.Log(Enums.LogTypes.THROW, "Nenhum classes extends GetMessages")

	return classes


static func find_script(type_name: StringName, path: String) -> bool:
	var script_class: Object = load(path)
	var tess = script_class.get_script_method_list()

	for function_info in tess:
		var ret: Dictionary = function_info["return"]
		if ret["class_name"] == "MessageHandlerInfo":
			class_mapping[type_name] = script_class.new()

			return true

	return false


static func get_functions_infos(type_name: StringName) -> FInfos:
	var mp_infos: FInfos = FInfos.new()

	if class_mapping.has(type_name):
		mp_infos.type_name = type_name
		var script_class: Object = class_mapping[type_name]

		var method_list: Array[Dictionary] = script_class.get_method_list()
		for function_info in method_list:
			var ret: Dictionary = function_info["return"]
			if ret["class_name"] == "MessageHandlerInfo":
				var function_name: StringName = function_info["name"]
				var function: Callable = script_class.get(function_name)
				var args_size: int = function_info["args"].size()

				var message_handler: MessageHandlerInfo = null
				if (args_size == 2) or (args_size == 1):
					if args_size == 2:
						message_handler = function.call(-1, null)
					else:
						message_handler = function.call(null)

					mp_infos.message_handlers.append(message_handler)

				elif args_size > 3:
					var log_message: String = (
						"O tamanho dos argumentos e maior que o esperado: "
						+ str(args_size)
						+ " do ("
						+ str(function)
						+ ")"
					)
					NetworkLogger.Log(Enums.LogTypes.ERROR, log_message)

	else:
		NetworkLogger.Log(
			Enums.LogTypes.THROW,
			type_name + " a classe existe, mas o carregamento do script falhou."
		)

	return mp_infos
