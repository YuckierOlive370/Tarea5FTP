. .\FunGENERALES.ps1  # Asegúrate que PedirPassword y funciones generales estén disponibles

# =====================================
# 1. Crear grupos
# =====================================
function CrearGrupos {
    $grupos = @("reprobados","recursadores")
    foreach ($grupo in $grupos) {
        if (-not (Get-LocalGroup -Name $grupo -ErrorAction SilentlyContinue)) {
            New-LocalGroup $grupo
            Write-Host "Grupo $grupo creado."
        }
    }
}

# =====================================
# 2. Crear estructura raíz y carpetas físicas
# =====================================
function CrearEstructura {
    $FTPPath = "C:\FTP"
    $LocalUser = "$FTPPath\LocalUser"
    $grupos = @("reprobados", "recursadores")

    # Carpetas físicas
    New-Item -ItemType Directory -Force -Path "$FTPPath\publica" | Out-Null
    foreach ($grupo in $grupos) {
        New-Item -ItemType Directory -Force -Path "$FTPPath\$grupo" | Out-Null
    }
    New-Item -ItemType Directory -Force -Path $LocalUser | Out-Null

    # Reset y permisos raíz
    icacls $FTPPath /reset /T /C
    icacls $FTPPath /inheritance:r
    icacls $FTPPath /grant "SYSTEM:(OI)(CI)F"
    icacls $FTPPath /grant "Administrators:(OI)(CI)F"
    icacls $FTPPath /grant "IIS_IUSRS:(RX)"

    # Carpetas físicas de grupo
    foreach ($g in $grupos) {
        $RutaG = "$FTPPath\$g"
        icacls $RutaG /inheritance:r
        icacls $RutaG /grant "SYSTEM:(OI)(CI)F"
        icacls $RutaG /grant "Administrators:(OI)(CI)F"
        icacls $RutaG /grant "$g:(OI)(CI)M"  # RW para miembros del grupo
    }

    # Carpeta pública
    $RutaPublica = "$FTPPath\publica"
    icacls $RutaPublica /inheritance:r
    icacls $RutaPublica /grant "SYSTEM:(OI)(CI)F"
    icacls $RutaPublica /grant "Administrators:(OI)(CI)F"
    icacls $RutaPublica /grant "Users:(OI)(CI)M"   # Todos usuarios RW
    icacls $RutaPublica /grant "IUSR:(OI)(CI)RX"   # Anonimo solo lectura

    Write-Host "Estructura raíz y permisos configurados." -ForegroundColor Green
}

# =====================================
# 3. Construir Jaula por usuario
# =====================================
function Construir-Jaula-Usuario {
    param([string]$usuario, [string]$grupo)

    $FTPPath = "C:\FTP"
    $HomeUsuario = "$FTPPath\LocalUser\$usuario"
    $CarpetaPrivada = "$HomeUsuario\$usuario"

    # Crear directorios
    New-Item -ItemType Directory -Force -Path $HomeUsuario | Out-Null
    New-Item -ItemType Directory -Force -Path $CarpetaPrivada | Out-Null

    # Reset y permisos de home
    icacls $HomeUsuario /inheritance:r
    icacls $HomeUsuario /grant "SYSTEM:(OI)(CI)F"
    icacls $HomeUsuario /grant "Administrators:(OI)(CI)F"
    icacls $HomeUsuario /grant "IIS_IUSRS:(RX)"      # Servicio FTP puede entrar
    icacls $HomeUsuario /grant "${usuario}:(RX)"     # Usuario puede ver enlaces

    # Carpeta privada = solo el usuario RW
    icacls $CarpetaPrivada /grant "${usuario}:(OI)(CI)F"

    # Crear junction a carpeta pública
    $jPublica = "$HomeUsuario\publica"
    if (-not (Test-Path $jPublica)) {
        cmd /c "mklink /J `"$jPublica`" `"$FTPPath\publica`"" | Out-Null
    }

    # Crear junction a carpeta de grupo
    $jGrupo = "$HomeUsuario\$grupo"
    if (-not (Test-Path $jGrupo)) {
        cmd /c "mklink /J `"$jGrupo`" `"$FTPPath\$grupo`"" | Out-Null
    }

    Write-Host "Jaula correcta creada para $usuario" -ForegroundColor Green
}

# =====================================
# 4. Crear usuario
# =====================================
function CrearUsuario {
    $n = Read-Host "¿Cuántos usuarios deseas crear?"
    for ($i=1; $i -le $n; $i++) {
        $usuario = Read-Host "Nombre del usuario"
        $pass    = PedirPassword
        $grupo   = Read-Host "Grupo (reprobados/recursadores)"

        if (-not (Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $usuario -Password $pass -PasswordNeverExpires -UserMayNotChangePassword
        }

        # Limpiar grupos anteriores
        foreach ($g in @("reprobados","recursadores")) {
            Remove-LocalGroupMember -Group $g -Member $usuario -ErrorAction SilentlyContinue
        }
        Add-LocalGroupMember -Group $grupo -Member $usuario

        # Construir jaula
        Construir-Jaula-Usuario -usuario $usuario -grupo $grupo
    }

    Restart-Service FTPSVC
    Write-Host "Usuarios creados y servicio FTP reiniciado." -ForegroundColor Yellow
}

# =====================================
# 5. Configurar IIS FTP
# =====================================
function CrearSitioFTP {
    Import-Module WebAdministration
    $FTPPath = "C:\FTP"

    if (-not (Get-Item IIS:\Sites\FTPSite -ErrorAction SilentlyContinue)) {
        New-WebFtpSite -Name "FTPSite" -Port 21 -PhysicalPath $FTPPath -Force
    }

    # User Isolation modo 3
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.userIsolation.mode" -Value 3

    # SSL opcional (0 = SslAllow)
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.controlChannelPolicy" -Value 0
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.dataChannelPolicy" -Value 0

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
        Add-WebConfigurationProperty -Filter "system.ftpServer/security/authorization" `
            -PSPath "IIS:\" -Location "FTPSite" `
            -Name "." -Value @{ accessType="Allow"; roles=$grupo; permissions="Read,Write" }
    }

    # Anonimo solo lectura
    Add-WebConfigurationProperty -Filter "system.ftpServer/security/authorization" `
        -PSPath "IIS:\" -Location "FTPSite" `
        -Name "." -Value @{ accessType="Allow"; users="?"; permissions="Read" }

    Write-Host "Autorización FTP configurada." -ForegroundColor Green
}

# =====================================
# 6. Abrir puerto FTP
# =====================================
function Puerto {
    New-NetFirewallRule -DisplayName "FTP Port 21" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
}