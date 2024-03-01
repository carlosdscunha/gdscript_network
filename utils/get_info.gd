class_name GetInfo

## Nome da classe
var type_name: String = "GetInfo"


## Converte as propriedades da classe em um dicionario.
## - `return Dictionary`: Um dicionario contendo as propriedades da classe.
func _get_to_dictionary() -> Dictionary:
	var info_dict = {
		"type_name": type_name,
	}

	return info_dict
