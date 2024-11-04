El archivo de configuración JSON ahora debería tener esta estructura:
```json
{
    "config": {
        "BackupDestination": "/path/to/backup/destination"
    },
    "telegram": {
        "ChatID": "your-chat-id",
        "APIkey": "your-api-key"
    },
    "containers": [
        {
            "name": "container1",
            "volumes": [
                "/path/to/volume1",
                "/path/to/volume2",
                "/path/to/volume3"
            ]
        },
        {
            "name": "container2",
            "volumes": [
                "/path/to/volume1",
                "/path/to/volume2"
            ]
        }
    ]
}
```
Los cambios principales incluyen:

Soporte para múltiples volúmenes por contenedor
Mejor manejo de errores para cada volumen
Verificación de la existencia del contenedor antes de intentar detenerlo
Verificación de la existencia de los directorios de los volúmenes
Los backups ahora incluyen el nombre del volumen en el archivo
Se mantiene un contador de errores global para reportar el estado final
Mejor logging de cada operación

El script:

Detiene el contenedor una sola vez
Respalda todos los volúmenes configurados
Inicia el contenedor nuevamente
Si algún volumen falla, lo registra pero continúa con los demás
Envía un reporte detallado por Telegram

Para ejecutarlo:
```shell
chmod +x backup_containers.sh
./backup_containers.sh config.json
```