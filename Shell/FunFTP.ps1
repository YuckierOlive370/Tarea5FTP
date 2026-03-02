. .\FunGENERALES
function CrearGrupos{
    $grupos = @("reprobados","recursadores")

    foreach ($grupo in $grupos) {
        if (-not (Get-LocalGroup -Name $grupo -ErrorAction SilentlyContinue)) {
            New-LocalGroup $grupo
            Write-Host "Grupo $grupo creado."
        }
    }
}

function CrearEstructura{
    $grupos = @("reprobados","recursadores")
    
    $FTPPath = "C:\FTP"
    $General = "$FTPPath\general"

    New-Item -ItemType Directory -Force -Path $FTPPath,$General

    foreach ($grupo in $grupos) {
        New-Item -ItemType Directory -Force -Path "$FTPPath\$grupo"
    }
}

function CrearSitioFTP{
    if (-not (Test-Path IIS:\Sites\FTPSite)) {
    New-WebFtpSite -Name "FTPSite" -Port 21 -PhysicalPath $FTPPath -Force
    }
}

function AbilitarAutenticacion{
    Set-ItemProperty IIS:\Sites\FTPSite -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
    Set-ItemProperty IIS:\Sites\FTPSite -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true
}

function CrearUsuario{
    $FTPPath = "C:\FTP"
    $General = "$FTPPath\general"

    $n = Read-Host "¿Cuántos usuarios deseas crear?"

    for ($i=1; $i -le $n; $i++) {

        Write-Host "Nombre del usuario"
        $usuario = Read-Host
        Write-Host "Password"
        $pass = PedirPassword
        Write-Host "Grupo (reprobados/recursadores)"
        $grupo = Read-Host

        if (-not (Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $usuario -Password $pass
        }

        Add-LocalGroupMember -Group $grupo -Member $usuario -ErrorAction SilentlyContinue

        $UserFolder = "$FTPPath\$usuario"
        New-Item -ItemType Directory -Force -Path $UserFolder

        # Permisos NTFS
        icacls $UserFolder /grant "${usuario}:(OI)(CI)M"
        icacls "$FTPPath\$grupo" /grant "${grupo}:(OI)(CI)M"
        icacls $General /grant "IUSR:(OI)(CI)RX"
    }
}

function CambiarGrupoUsuario {
    Write-Host "Usuario"
    $usuario = Read-Host
    Write-Host "Nuevo grupo (reprobados/recursadores)"
    $nuevoGrupo = Read-Host

    $grupos = @("reprobados","recursadores")

    foreach ($g in $grupos) {
        Remove-LocalGroupMember -Group $g -Member $usuario -ErrorAction SilentlyContinue
    }

    Add-LocalGroupMember -Group $nuevoGrupo -Member $usuario

    Write-Host "Grupo actualizado."
}