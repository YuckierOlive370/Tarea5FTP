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
    $n = Read-Host "¿Cuántos usuarios deseas crear?"

    for ($i=1; $i -le $n; $i++) {

        $usuario = Read-Host "Nombre del usuario"
        $pass = Read-Host "Contraseña" -AsSecureString
        $grupo = Read-Host "Grupo (reprobados/recursadores)"

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