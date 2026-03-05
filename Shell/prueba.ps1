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
    $FTPPath = "C:\FTP"
    $LocalUser = "$FTPPath\LocalUser"
    $grupos = @("reprobados", "recursadores")

    # 1. Crear carpetas FÍSICAS reales fuera de LocalUser
    New-Item -ItemType Directory -Force -Path "$FTPPath\publica" | Out-Null
    foreach ($grupo in $grupos) {
        New-Item -ItemType Directory -Force -Path "$FTPPath\$grupo" | Out-Null
    }
    New-Item -ItemType Directory -Force -Path $LocalUser | Out-Null

    # 2. Resetear y asegurar C:\FTP
    icacls $FTPPath /reset /T /C
    icacls $FTPPath /inheritance:r
    icacls $FTPPath /grant "SYSTEM:(OI)(CI)F"
    icacls $FTPPath /grant "Administrators:(OI)(CI)F"
    icacls $FTPPath /grant "IIS_IUSRS:(RX)" # Permiso para que el servicio explore la raíz

    # 3. Permisos Carpeta PUBLICA (Anónimo: R, Usuarios: RW)
    icacls "$FTPPath\publica" /grant "IUSR:(OI)(CI)RX"
    icacls "$FTPPath\publica" /grant "Users:(OI)(CI)M"

    # 4. Permisos Carpetas de GRUPO
    foreach ($grupo in $grupos) {
        $RutaG = "$FTPPath\$grupo"
        icacls $RutaG /inheritance:r
        icacls $RutaG /grant "${grupo}:(OI)(CI)M"
        icacls $RutaG /grant "SYSTEM:(OI)(CI)F"
        icacls $RutaG /grant "Administrators:(OI)(CI)F"
    }

    # 5. FIX ANÓNIMO: IIS busca 'public' (Modo 3)
    $jAnon = "$LocalUser\public"
    if (-not (Test-Path $jAnon)) {
        cmd /c "mklink /J `"$jAnon`" `"$FTPPath\publica`"" | Out-Null
    }
    icacls "$LocalUser\public" /grant "IUSR:(OI)(CI)RX"

    Write-Host "Estructura raíz y acceso anónimo (public) configurados." -ForegroundColor Green
}

function Construir-Jaula-Usuario {
    param([string]$usuario, [string]$grupo)

    $FTPPath = "C:\FTP"
    $HomeUsuario = "$FTPPath\LocalUser\$usuario"
    $CarpetaPrivada = "$HomeUsuario\$usuario"

    # 1. Crear la 'Jaula' (Home) y la subcarpeta personal
    New-Item -ItemType Directory -Force -Path $CarpetaPrivada | Out-Null

    # 2. Permisos NTFS:
    icacls $HomeUsuario /inheritance:r
    icacls $HomeUsuario /grant "SYSTEM:(OI)(CI)F"
    icacls $HomeUsuario /grant "Administrators:(OI)(CI)F"
    
    # --- EL CAMBIO CRÍTICO AQUÍ ---
    icacls $HomeUsuario /grant "IIS_IUSRS:(RX)"        # Permiso para el SERVICIO
    icacls $HomeUsuario /grant "${usuario}:(RX)"       # Permiso para que el USUARIO vea los enlaces
    
    # Control total sobre su propia carpeta interna física
    icacls $CarpetaPrivada /grant "${usuario}:(OI)(CI)F"

    # 3. Crear Junctions (Enlaces)
    $jPublica = "$HomeUsuario\publica"
    $jGrupo   = "$HomeUsuario\$grupo"

    if (-not (Test-Path $jPublica)) {
        cmd /c "mklink /J `"$jPublica`" `"$FTPPath\publica`"" | Out-Null
    }
    if (-not (Test-Path $jGrupo)) {
        cmd /c "mklink /J `"$jGrupo`" `"$FTPPath\$grupo`"" | Out-Null
    }

    Write-Host "Jaula corregida para $usuario. Ahora el servicio FTP puede entrar." -ForegroundColor Green
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

function CrearSitioFTP {
    Import-Module WebAdministration
    $FTPPath = "C:\FTP"

    if (-not (Get-Item IIS:\Sites\FTPSite -ErrorAction SilentlyContinue)) {
        New-WebFtpSite -Name "FTPSite" -Port 21 -PhysicalPath $FTPPath -Force
    }

    # User Isolation modo 3 (User name directory)
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.userIsolation.mode" -Value 3

    # SSL opcional (0 = SslAllow)
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.controlChannelPolicy" -Value 0
    Set-ItemProperty "IIS:\Sites\FTPSite" -Name "ftpServer.security.ssl.dataChannelPolicy" -Value 0

    Restart-WebItem "IIS:\Sites\FTPSite"
}

function CrearUsuario {
    $n = Read-Host "¿Cuántos usuarios deseas crear?"
    for ($i=1; $i -le $n; $i++) {
        $usuario = Read-Host "Nombre del usuario"
        $pass    = PedirPassword  # Asegúrate que esta función esté en FunGENERALES
        $grupo   = Read-Host "Grupo (reprobados/recursadores)"

        if (-not (Get-LocalUser -Name $usuario -ErrorAction SilentlyContinue)) {
            New-LocalUser -Name $usuario -Password $pass -PasswordNeverExpires -UserMayNotChangePassword
        }

        # Limpiar grupos anteriores
        foreach ($g in @("reprobados","recursadores")) {
            Remove-LocalGroupMember -Group $g -Member $usuario -ErrorAction SilentlyContinue
        }
        Add-LocalGroupMember -Group $grupo -Member $usuario

        # Construir la jaula
        Construir-Jaula-Usuario -usuario $usuario -grupo $grupo
    }
    Restart-Service FTPSVC
    Write-Host "Proceso finalizado. Servicio reiniciado." -ForegroundColor Yellow
}

function Puerto {
    New-NetFirewallRule -DisplayName "FTP Port 21" -Direction Inbound -Protocol TCP -LocalPort 21 -Action Allow
}