. .\FunGENERALES
function CrearGrupos {
    $grupos = @("reprobados","recursadores")

    foreach ($grupo in $grupos) {
        if (-not (Get-LocalGroup -Name $grupo -ErrorAction SilentlyContinue)) {
            New-LocalGroup $grupo
            Write-Host "Grupo $grupo creado."
        }
    }
}

function CrearEstructura {

    $FTPPath   = "C:\FTP"
    $LocalUser = "$FTPPath\LocalUser"
    $Public    = "$LocalUser\Public"
    $General   = "$Public\general"
    $grupos    = @("reprobados","recursadores")

    # Crear carpetas base
    New-Item -ItemType Directory -Force -Path $General | Out-Null

    foreach ($grupo in $grupos) {
        New-Item -ItemType Directory -Force -Path "$LocalUser\$grupo" | Out-Null
    }

    # Resetear permisos COMPLETAMENTE
    icacls $FTPPath /reset /T /C

    # Permisos raíz
    icacls $FTPPath /inheritance:r
    icacls $FTPPath /grant "SYSTEM:(OI)(CI)F"
    icacls $FTPPath /grant "Administrators:(OI)(CI)F"
    icacls $FTPPath /grant "IIS_IUSRS:(OI)(CI)RX"

    # Permitir atravesar LocalUser
    icacls $LocalUser /grant "IIS_IUSRS:(OI)(CI)RX"

    # Permisos carpeta Public (anónimo)
    icacls $Public /grant "IUSR:(OI)(CI)RX"
    icacls $General /grant "IUSR:(OI)(CI)RX"

    # Permisos carpetas de grupo
    foreach ($grupo in $grupos) {

        $RutaGrupo = "$LocalUser\$grupo"

        icacls $RutaGrupo /inheritance:r
        icacls $RutaGrupo /grant "${grupo}:(OI)(CI)M"
        icacls $RutaGrupo /grant "SYSTEM:(OI)(CI)F"
        icacls $RutaGrupo /grant "Administrators:(OI)(CI)F"
        icacls $RutaGrupo /grant "IIS_IUSRS:(OI)(CI)RX"
    }

    Write-Host "Estructura y permisos configurados correctamente."
}

function CrearSitioFTP {

    Import-Module WebAdministration
    $FTPPath = "C:\FTP"

    if (-not (Get-Item IIS:\Sites\FTPSite -ErrorAction SilentlyContinue)) {
        New-WebFtpSite -Name "FTPSite" -Port 21 -PhysicalPath $FTPPath -Force
        Write-Host "Sitio FTP creado."
    }

    # User Isolation modo 3
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.userIsolation.mode" -Value 3

    # SSL opcional
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.controlChannelPolicy" -Value "SslAllow"
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.dataChannelPolicy" -Value "SslAllow"

    Restart-WebItem "IIS:\Sites\FTPSite"
}

function HabilitarAutenticacion {

    Import-Module WebAdministration

    Set-ItemProperty IIS:\Sites\FTPSite -Name ftpServer.security.authentication.anonymousAuthentication.enabled -Value $true
    Set-ItemProperty IIS:\Sites\FTPSite -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $true

    Restart-WebItem "IIS:\Sites\FTPSite"
}

function ConfigurarAutorizacion {

    Import-Module WebAdministration

    Clear-WebConfiguration -Filter "system.ftpServer/security/authorization" -PSPath "IIS:\" -Location "FTPSite"

    foreach ($grupo in @("reprobados","recursadores")) {
        Add-WebConfigurationProperty `
        -Filter "system.ftpServer/security/authorization" `
        -PSPath "IIS:\" `
        -Location "FTPSite" `
        -Name "." `
        -Value @{ accessType="Allow"; roles=$grupo; permissions="Read,Write" }
    }

    Add-WebConfigurationProperty `
    -Filter "system.ftpServer/security/authorization" `
    -PSPath "IIS:\" `
    -Location "FTPSite" `
    -Name "." `
    -Value @{ accessType="Allow"; users="?"; permissions="Read" }

    Write-Host "Autorización configurada."
}

function Construir-Jaula-Usuario {

    param(
        [string]$usuario,
        [string]$grupo
    )

    $FTPPath = "C:\FTP"
    $jaula   = "$FTPPath\LocalUser\$usuario"
    $LocalUser = "$FTPPath\LocalUser"

    # Crear home
    New-Item -ItemType Directory -Force -Path "$jaula\personal" | Out-Null

    # Permisos usuario
    icacls $jaula /inheritance:r
    icacls $jaula /grant "${usuario}:(OI)(CI)F"
    icacls $jaula /grant "SYSTEM:(OI)(CI)F"
    icacls $jaula /grant "Administrators:(OI)(CI)F"
    icacls $jaula /grant "IIS_IUSRS:(OI)(CI)RX"

    # Junction general
    $jGeneral = "$jaula\general"
    if (-not (Test-Path $jGeneral)) {
        cmd /c "mklink /J `"$jGeneral`" `"$LocalUser\Public\general`"" | Out-Null
    }

    # Junction grupo
    $jGrupo = "$jaula\$grupo"
    if (-not (Test-Path $jGrupo)) {
        cmd /c "mklink /J `"$jGrupo`" `"$LocalUser\$grupo`"" | Out-Null
    }

    Write-Host "Jaula creada para $usuario."
}

function CrearUsuario {

    $n = Read-Host "¿Cuántos usuarios deseas crear?"

    for ($i=1; $i -le $n; $i++) {

        $usuario = Read-Host "Nombre del usuario"
        $pass    = Read-Host "Contraseña" -AsSecureString
        $grupo   = Read-Host "Grupo (reprobados/recursadores)"

        if (-not (Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $usuario `
            -Password $pass `
            -PasswordNeverExpires `
            -UserMayNotChangePassword `
            -AccountNeverExpires `
            -PasswordRequired $true
        }

        foreach ($g in @("reprobados","recursadores")) {
            Remove-LocalGroupMember -Group $g -Member $usuario -ErrorAction SilentlyContinue
        }

        Add-LocalGroupMember -Group $grupo -Member $usuario

        Construir-Jaula-Usuario -usuario $usuario -grupo $grupo

        Write-Host "Usuario $usuario configurado correctamente."
    }

    Restart-Service FTPSVC
}

function Puerto {
    New-NetFirewallRule -DisplayName "FTP Port 21" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
}