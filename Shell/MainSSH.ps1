. .\FunGENERALES.ps1
. .\FunSSH.ps1

$con = "S"

while ($con -match '^[sS]$') {
    Write-Host "Tarea 4: SSH"-ForegroundColor Yellow
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.-Instalar"
    Write-Host "2.-Verificar Servicio"
    Write-Host "3.-Mostrar el Usuario actual"
    Write-Host "4.-Listar Usuarios"
    Write-Host "5.-Crear Usuario"
    Write-Host "6.-Abrir puerto 22 y iniciar ssh"
    Write-Host "7.-Salir"
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{InstalarPaquete "SSH"}
        2{VerificarPaquete "SSH"}
        3{MostrarUsuarioActual}
        4{ListarUsuarios}
        5{CrearUsuario}
        6{AbrirPuerto22}
        7{$con = "n"}
        default{Write-Host "Opcion no valida" -ForegroundColor Red}
    }
}
Write-Host "Programa terminado." -ForegroundColor Yellow