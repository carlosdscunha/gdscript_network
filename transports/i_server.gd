## Define metodos, propriedades e eventos que todo servidor de transporte deve implementar.
class_name IServer extends IPeer
## Invocado quando uma conexao e estabelecida no nivel de transporte.
## `event EventHandler<ConnectedEventArgs> Connected`
signal connected(e: ConnectedEventArgs)

## A porta local na qual o servidor esta sendo executado.
var port: int:
	get:
		return 0

@warning_ignore("unused_parameter")
## Inicia o transporte e comeca a ouvir as conexoes de entrada.
## - `port_`: A porta local na qual escutar as conexoes.
func start(port_: int):
	pass


@warning_ignore("unused_parameter")
## Fecha uma conexao ativa.
## - `connection`: A conexao a ser fechada.
func close(connection: Connection):
	pass


## Fecha todas as conexoes existentes e para de ouvir novas conexoes.
func shutdown():
	pass
