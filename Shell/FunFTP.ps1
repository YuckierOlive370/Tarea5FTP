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
    Import-Module WebAdministration
    $FTPPath = "C:\FTP"

    if (-not (Test-Path IIS:\Sites\FTPSite)) {
        New-WebFtpSite -Name "FTPSite" -Port 21 -PhysicalPath $FTPPath -Force
        Write-Host "Sitio FTP creado."
    } else {
        Write-Host "El sitio ya existe."
    }

    # Desactivar SSL obligatorio
    Set-ItemProperty "IIS:\Sites\FTPSite" `
    -Name ftpServer.security.ssl.controlChannelPolicy `
    -Value 0

    Set-ItemProperty "IIS:\Sites\FTPSite" `
    -Name ftpServer.security.ssl.dataChannelPolicy `
    -Value 0

    Restart-WebItem "IIS:\Sites\FTPSite"
}

function HabilitarAutenticacion{
    Import-Module WebAdministration

    # Desactivar anónimo
    Set-ItemProperty IIS:\Sites\FTPSite `
    -Name ftpServer.security.authentication.anonymousAuthentication.enabled `
    -Value $false

    # Activar básica
    Set-ItemProperty IIS:\Sites\FTPSite `
    -Name ftpServer.security.authentication.basicAuthentication.enabled `
    -Value $true

    Restart-WebItem "IIS:\Sites\FTPSite"
}

function ConfigurarAutorizacion {

    Import-Module WebAdministration

    # Limpiar reglas anteriores
    Clear-WebConfiguration `
    -Filter "system.ftpServer/security/authorization" `
    -PSPath "IIS:\" `
    -Location "FTPSite"

    # Regla para grupo reprobados
    Add-WebConfigurationProperty `
    -Filter "system.ftpServer/security/authorization" `
    -PSPath "IIS:\" `
    -Location "FTPSite" `
    -Name "." `
    -Value @{
        accessType="Allow";
        roles="reprobados";
        permissions="Read,Write"
    }

    # Regla para grupo recursadores
    Add-WebConfigurationProperty `
    -Filter "system.ftpServer/security/authorization" `
    -PSPath "IIS:\" `
    -Location "FTPSite" `
    -Name "." `
    -Value @{
        accessType="Allow";
        roles="recursadores";
        permissions="Read,Write"
    }

    Write-Host "Autorización configurada correctamente."
}

function CrearUsuario{
    $FTPPath = "C:\FTP"
    $General = "$FTPPath\general"

    $n = Read-Host "¿Cuantos usuarios deseas crear?"

    for ($i=1; $i -le $n; $i++) {

        Write-Host "Nombre del usuario"
        $usuario = Read-Host
        Write-Host "Password"
        $pass = PedirPassword
        Write-Host "Grupo (reprobados/recursadores)"
        $grupo = Read-Host

        if (-not (Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $usuario -Password $pass -FullName $usuario
        }

        Add-LocalGroupMember -Group $grupo -Member $usuario -ErrorAction SilentlyContinue

        $UserFolder = "$FTPPath\$usuario"
        New-Item -ItemType Directory -Force -Path $UserFolder

        # Permisos NTFS correctos
        icacls $UserFolder /grant "${usuario}:(OI)(CI)F"
        icacls $FTPPath /grant "${grupo}:(OI)(CI)M"
        icacls $General /grant "${grupo}:(OI)(CI)M"

        Write-Host "Usuario $usuario creado correctamente."
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

function Puerto {
    New-NetFirewallRule -DisplayName "FTP Port 21" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
}