## Define metodos, propriedades e eventos que todo cliente de transporte deve implementar.
class_name IClient extends IPeer

## Invocado quando uma conexao e estabelecida no nivel de transporte.
signal connected
## Invocado quando uma tentativa de conexao falha no nivel de transporte.
signal connection_failed

@warning_ignore("unused_parameter")
## Inicia o transporte e tenta se conectar ao endereco de host fornecido.
## - `host_address`: O endereco do host ao qual se conectar.
## - `connection`: A conexao pendente. `null` se ocorreu um problema.
## - `connectError`: A mensagem de erro associada ao problema que ocorreu, se houver.
## - `returns`: `true` se uma tentativa de conexao for feita. `false` se ocorrer um problema (como `hostAddress` estar em um formato invalido) e uma tentativa de conexao <i>nao</i> sera feita.
func connect_host(host_address: String) -> OutConnect:
	return OutConnect.new()


## Fecha a conexao com o servidor.
func disconnect_host() -> void:
	pass
