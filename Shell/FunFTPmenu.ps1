. .\FunGENERALES.ps1
function ConectarFTP {
    Write-Host "IP del servidor: "
    $servidor = Pedir-IP
    Write-Host "Usuario (anonymous si es anonimo)"
    $usuario = Read-Host

    if ($usuario -eq "anonymous") {
        $password = "anonymous"
    } else {
        $password = Read-Host "Contraseña"
    }

    $comandos = @"
open $servidor
user $usuario $password
ls
bye
"@

    $archivoTemp = "ftp_commands.txt"
    $comandos | Out-File $archivoTemp -Encoding ascii

    ftp -s:$archivoTemp

    Remove-Item $archivoTemp
}

function SubirArchivo {

    Write-Host "IP del servidor: "
    $servidor = Pedir-IP
    Write-Host "Usuario"
    $usuario = Read-Host
    Write-Host "Contraseña"
    $password = Read-Host
    Write-Host "Archivo local"
    $archivo = Read-Host
    Write-Host "Directorio remoto"
    $directorio = Read-Host

    $comandos = @"
open $servidor
user $usuario $password
cd $directorio
put $archivo
ls
bye
"@

    $archivoTemp = "ftp_commands.txt"
    $comandos | Out-File $archivoTemp -Encoding ascii

    ftp -s:$archivoTemp

    Remove-Item $archivoTemp
}

function DescargarArchivo {

    Write-Host "IP del servidor: "
    $servidor = Pedir-IP
    Write-Host "Usuario: "
    $usuario = Read-Host
    Write-Host "Contraseña: "
    $password = Read-Host
    Write-Host "Archivo remoto: "
    $archivo = Read-Host

    $comandos = @"
open $servidor
user $usuario $password
get $archivo
bye
"@

    $archivoTemp = "ftp_commands.txt"
    $comandos | Out-File $archivoTemp -Encoding ascii

    ftp -s:$archivoTemp

    Remove-Item $archivoTemp
}

function ProbarPermisos {

    Write-Host "IP del servidor: "
    $servidor = Pedir-IP
    Write-Host "Usuario: "
    $usuario = Read-Host
    Write-Host "Password: "
    $password = PedirPassword

    "Archivo de prueba" | Out-File prueba.txt

    Write-Host "Probando escritura en general..."

    $comandos = @"
open $servidor
user $usuario $password
cd general
put prueba.txt
bye
"@

    $archivoTemp = "ftp_test.txt"
    $comandos | Out-File $archivoTemp -Encoding ascii

    ftp -s:$archivoTemp

    Remove-Item $archivoTemp
    Remove-Item prueba.txt
}