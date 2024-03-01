## Representa um endpoint de IP com um endereco e porta.
class_name IPEndPoint

## Endereco IP do endpoint.
var address: String
## Numero da porta do endpoint.
var port: int


## Inicializa um novo objeto IPEndPoint com um endereco IP e uma porta.
## - `_address`: O endereco IP do endpoint.
## - `_port`: O numero da porta do endpoint.
func _init(_address: String, _port: int):
	address = _address
	port = _port


## Converte o objeto IPEndPoint para uma representacao de string.
##
## Retorna:
## - `return`: Uma string que representa o endereco IP e a porta do endpoint.
func _to_string() -> String:
	return address + ":" + str(port)


## Verifica se outro objeto IPEndPoint e igual a este.
## - `other`: O outro objeto IPEndPoint a ser comparado.
## - `return`: `true` se o endereco IP e a porta forem iguais, caso contrario, `false`.
func equals(other: IPEndPoint) -> bool:
	return address == other.address and port == other.port
