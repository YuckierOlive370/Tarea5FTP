. .\FunGENERALES.ps1
. .\FunDNS.ps1

$con = "S"

while ($con -match '^[sS]$') {
    Write-Host "Tarea 3: Automatizacion y Gestion del Servidor DNS"-ForegroundColor Yellow
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.-Verificar la presencia del servicio"
    Write-Host "2.-Instalar el servicio"
    Write-Host "3.-Configurar"
    Write-Host "4.-Reconfigurar"
    Write-Host "5.-ABC dominios"
    Write-Host "6.-Monitoreo"
    Write-Host "7.-Salir"
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{VerificarPaquete "DNS"}
        2{InstalarPaquete "DNS"}
        3{Configurar}
        4{Reconfigurar}
        5{ABC}
        6{Monitoreo}
        7{$con = "n"}
        default{Write-Host "Opcion no valida" -ForegroundColor Red}
    }
}
Write-Host "Programa terminado." -ForegroundColor Yellow