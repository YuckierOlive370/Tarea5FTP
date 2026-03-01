function VerificarRoot {
    $isAdmin = ([Security.Principal.WindowsPrincipal] `
        [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

    if (-not $isAdmin) {
        Write-Host "Ejecuta este script como Administrador"
        exit
    }
}

function InstalarPaquete {
    param (
        [string]$FeatureName
    )
    Write-Host "¿Deseas instalarlo ahora $FeatureName? (S/N)"
    $respuesta = Read-Host
    if ($respuesta -match '^[sS]$') {
        try{
            Write-Host  "Instalando" -ForegroundColor Green
            Install-WindowsFeature -Name $FeatureName -IncludeManagementTools -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Write-Host  "Instalacion finalizada" -ForegroundColor Green
        }
        catch{
            Write-Host  "Error de Instalacion" -ForegroundColor Red
        }
    } else {
        Write-Host "Instalacion cancelada por el usuario." -ForegroundColor Red
    }
}

function VerificarPaquete {
    param (
        [string]$FeatureName
    )
    if ((Get-WindowsFeature -Name $FeatureName).Installed) {
        Write-Host "El $FeatureName ya esta instalado."
    } else {
        Write-Host "El $FeatureName no esta instalado."
        $respuesta = Read-Host "¿Deseas instalarlo ahora? (S/N)"
        if ($respuesta -match '^[sS]$') {
            InstalarPaquete $FeatureName
        } else {
            Write-Host "Instalacion cancelada por el usuario."
        }
    }
}

function Validar-IP {
    param ($ip)
    if ($ip -match '^((25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)\.){3}(25[0-5]|2[0-4]\d|1\d{2}|[1-9]?\d)$') {
        return ($ip -ne "255.255.255.255" -and $ip -ne "0.0.0.0" -and $ip -ne "127.0.0.1")
    }
    return $false
}

function IP-a-Int {
    param ([string]$ip)
    $bytes = [System.Net.IPAddress]::Parse($ip).GetAddressBytes()
    [Array]::Reverse($bytes)
    return [BitConverter]::ToUInt32($bytes, 0)
}

function Pedir-IP {
    do {
        $ip = Read-Host
        if (-not (Validar-IP $ip)) {
            Write-Host "IP no valida, intenta de nuevo"
        }
    } until (Validar-IP $ip)

    return $ip
}

function Get-PrefixLength {
    param([string]$SubnetMask)
    $bytes = $SubnetMask.Split('.') | ForEach-Object { [Convert]::ToString([int]$_,2).PadLeft(8,'0') }
    ($bytes -join '').ToCharArray() | Where-Object { $_ -eq '1' } | Measure-Object | Select-Object -ExpandProperty Count
}