class_name ArrayUtil


static func clear(array: Array, index: int, length: int) -> void:
	if array != null and index >= 0 and length > 0 and index + length <= array.size():
		for i in range(index, index + length):
			array[i] = null


static func copy(
	source_array: Array,
	source_or_index_or_destination_or_array: Variant,
	destination_or_array_or_length: Variant,
	destination_or_index: int = -1,
	length: int = -1
) -> void:
	if (
		typeof(source_or_index_or_destination_or_array) == TYPE_INT
		and (
			typeof(destination_or_array_or_length) == TYPE_ARRAY
			or typeof(destination_or_array_or_length) == TYPE_PACKED_BYTE_ARRAY
		)
	):
		if (
			source_or_index_or_destination_or_array < 0
			or source_or_index_or_destination_or_array + length > source_array.size()
			or destination_or_index < 0
			or destination_or_index + length > destination_or_array_or_length.size()
		):
			NetworkLogger.Log(Enums.LogTypes.THROW, "Index ou length invalido")

		for i in range(length):
			destination_or_array_or_length[destination_or_index + i] = source_array[
				source_or_index_or_destination_or_array + i
			]

	elif (
		(
			typeof(source_or_index_or_destination_or_array) == TYPE_ARRAY
			or typeof(source_or_index_or_destination_or_array) == TYPE_PACKED_BYTE_ARRAY
		)
		and typeof(destination_or_array_or_length) == TYPE_INT
	):
		if (
			destination_or_array_or_length > source_array.size()
			or destination_or_array_or_length > source_or_index_or_destination_or_array.size()
		):
			NetworkLogger.Log(Enums.LogTypes.THROW, "Length invalido")

		for i in range(destination_or_array_or_length):
			source_or_index_or_destination_or_array[i] = source_array[i]
	else:
		NetworkLogger.Log(Enums.LogTypes.THROW, "Argumentos invalidos")


static func to_array_dictionary(array: Array) -> Array[Dictionary]:
	var array_dict: Array[Dictionary] = []

	for element in array:
		if element is GetInfo:
			array_dict.append(element._get_to_dictionary())
		else:
			var frames := get_stack()
			if frames.size() > 0:
				var frame = frames[1]
				var source: String = frame["source"]
				if source.begins_with("res://"):
					source = source.substr(6)  # Remove 'res://'
				var line: String = str(frame["line"])
				var function: String = str(frame["function"])
				var message = "[WARNING][" + source + ":" + line + " @ " + function + "()]: "

				print_rich(
					(
						"[color=yellow][b]"
						+ message
						+ "[/b][/color]"
						+ "[color=white][b]"
						+ "Elemento nao estende GetInfo: "
						+ str(element)
						+ "[/b][/color]"
					)
				)

	return array_dict


static func find_key_from_properties(
	dic: Dictionary, properties: PackedStringArray
) -> PackedStringArray:
	var keys: PackedStringArray = PackedStringArray()

	if properties:
		for key in dic.keys() as PackedStringArray:
			for propertie in properties:
				if key == propertie:
					keys.append(key)

		if keys.size() == 0:
			(
				NetworkLogger
				. log_warning(
					[
						"Nenhuma correspondencia encontrada entre as propriedades e as chaves do dicionario."
					],
					3
				)
			)
			return []
		for propertie in properties:
			if not keys.has(propertie):
				NetworkLogger.log_warning(
					[
						(
							"A propriedade '"
							+ str(propertie)
							+ "' nao esta presente nas chaves do dicionario."
						)
					],
					3
				)
				return []
	else:
		keys = dic.keys() as PackedStringArray

	return keys
