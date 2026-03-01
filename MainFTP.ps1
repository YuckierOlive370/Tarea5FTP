. .\FunGENERALES.ps1
. .\FunFTP.ps1
$features = @(
    "Web-Server",
    "Web-FTP-Server",
    "Web-FTP-Service",
    "Web-FTP-Ext"
)
$con = "S"

while ($con -match '^[sS]$') {
    Write-Host "Tarea 5: Automatizacion de Servidor FTP"
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.-Verificar la presencia del servicio"
    Write-Host "2.-Instalar el servicio"
    Write-Host "3.-Configurar"
    Write-Host "4.-Crear usuario"
    Write-Host "5.-Salir..."
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{
            foreach ($feature in $features){
                VerificarPaquete "$feature"
            }
        }
        2{
            foreach ($feature in $features){
                InstalarPaquete "$feature"
            }
        }
        3{
            Import-Module WebAdministration
            CrearGrupos
            CrearEstructura
            CrearSitioFTP
            AbilitarAutenticacion
        }
        4{CrearUsuario}
        5{$con = "n"}
        default{Write-Host "Opcion no valida"}
    }
}
Write-Host "Programa terminado." -ForegroundColor Yellow