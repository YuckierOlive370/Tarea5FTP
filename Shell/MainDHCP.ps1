. .\FunGENERALES.ps1
. .\FunDHCP.ps1
$features = @(
    "Web-Server",
    "Web-FTP-Server",
    "Web-FTP-Service",
    "Web-FTP-Ext"
)

$con = "S"

while ($con -match '^[sS]$') {
    Write-Host "Tarea 2: Automatizacion y Gestion del Servidor DHCP"
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.-Verificar la presencia del servicio"
    Write-Host "2.-Instalar el servicio"
    Write-Host "3.-Configurar el servicio"
    Write-Host "4.-Monitoreo"
    Write-Host "5.-Reiniciar Servivicios"
    Write-Host "6.-Salir"
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{VerificarPaquete "$features"}
        2{InstalarPaquete "$features"}
        3{Configurar}
        4{ListarConcesiones}
        5{ReiniciarDHCP}
        6{$con = "n"}
        default{Write-Host "Opcion no valida"}
    }
}
Write-Host "Programa terminado." -ForegroundColor Yellow