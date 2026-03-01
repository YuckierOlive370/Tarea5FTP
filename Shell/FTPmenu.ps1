. .\FunGENERALES.ps1
. .\FunFTPmenu.ps1

$con = "S"

while ($con -match '^[sS]$') {
    Write-Host "========GESTOR FTP WINDOWS========"-ForegroundColor Yellow
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.- Conectar y listar"
    Write-Host "2.- Subir archivo"
    Write-Host "3.- Descargar archivo"
    Write-Host "4.- Probar permisos"
    Write-Host "5.- Salir"
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{ConectarFTP}
        2{SubirArchivo}
        3{DescargarArchivo}
        4{ProbarPermisos}
        5{$con = "n"}
        default{Write-Host "Opcion no valida" -ForegroundColor Red}
    }
}
Write-Host "Programa terminado." -ForegroundColor Yellow