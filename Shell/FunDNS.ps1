. .\FunGENERALES.ps1

function ValidarDominio{
    param (
        [string]$dominio
    )

    $regex = '^(?!-)(?:[a-zA-Z0-9-]{1,63}\.)+[a-zA-Z]{2,}$'

    if ($dominio -match $regex){
        Write-Host  "Dominio valido" -ForegroundColor Green
        return $true
    }else {
        Write-Host  "Dominio no valido, intenta de nuevo" -ForegroundColor Red
        return $false
    }
}

function Configurar {
    param (
        [string]$subnetMask = "255.255.255.0"
    )

    if ((Get-WindowsFeature -Name DNS).Installed) {
    Write-Host "El rol DNS ya está instalado."
    } else {
    return
    }
    Write-Host "Opciones 1.-Asignar tu IP fija 2.-Asignar tu mismo la IP: "
    $opc = Read-Host
    if ($opc -eq 1) {
        Write-Host "Elegiste opcion 1."

            $adapter = Get-NetIPInterface -InterfaceAlias "Ethernet1" -AddressFamily IPv4
    if ($adapter.Dhcp -eq "Disabled"){
        Write-Host "Se cuenta con IP fija"
        $IP = (Get-NetIPAddress -InterfaceAlias "Ethernet1" -AddressFamily IPv4).IPAddress
        Write-Host "La IP fija detectada es $IP"

    }  else {
        Write-Host "No se cuenta con IP fija"
            Write-Host "IP fija del servidor"
            $IP = Pedir-IP
            $prefix = Get-PrefixLength -SubnetMask $subnetMask
        try {
            Remove-NetIPAddress -InterfaceIndex 11 -Confirm:$false
            $interface = Get-NetAdapter -Name "Ethernet1"
            New-NetIPAddress -InterfaceIndex $interface.InterfaceIndex `
            -IPAddress $IP `
            -PrefixLength $prefix -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Host "No se asigno la IP fija" -ForegroundColor Red
        }
    }

    }
    elseif ($opc -eq 2) {
        Write-Host "Elegiste opcion 2."
        Write-Host "IP perzonalizada: "
        $IP = Pedir-IP
    }
    else {
        Write-Host "Opcion no valida..."
    }

    do {
        Write-Host "Ingresa el dominio: "
        $dominio = Read-Host
    } until (ValidarDominio $dominio)
    
    try{
        Add-DnsServerPrimaryZone -Name "$dominio" -ZoneFile "$dominio.dns"
        Add-DnsServerResourceRecordA -Name "@" -ZoneName "$dominio" -IPv4Address $IP
        Add-DnsServerResourceRecordA -Name "www" -ZoneName "$dominio" -IPv4Address $IP
        Get-DnsServerZone -Name "$dominio"
        Get-DnsServerResourceRecord -ZoneName "$dominio"
        Write-Host "Se asigno Dominio: $dominio" -ForegroundColor Green
    }
    catch{
        Write-Host  "No se asigno Dominio" -ForegroundColor Red
    }
}

function Reconfigurar {
    Write-Host "Bienvenido a la reconfiguracion."
    Uninstall-WindowsFeature -Name DNS
    Instalar
    Configurar
}

function Agregar{
    Configurar
}

function Borrar{
    do {
        Write-Host "Ingresa el dominio: "
        $dominio = Read-Host
    } until (ValidarDominio $dominio)
    try{
        Remove-DnsServerZone -Name "$dominio" -Force
        Write-Host "Dominio eliminado: $dominio" -ForegroundColor Green
    }
    catch{
        Write-Host "No se elimino dominio: $dominio" -ForegroundColor Red
    }
}

function Consultar{
    do {
        Write-Host "Ingresa el dominio: "
        $dominio = Read-Host
    } until (ValidarDominio $dominio)
    $Zona = Get-DnsServerZone -Name $dominio -ErrorAction SilentlyContinue
    Get-DnsServerZone -Name "$dominio"
    Get-DnsServerResourceRecord -ZoneName "$dominio"
}

function ABC{

    if ((Get-WindowsFeature -Name DNS).Installed) {

    }else {
        return
    }

    Write-Host "Bienvenidio al ABC de DNS" -ForegroundColor Yellow
    Write-Host "++++++++ Menu de Opciones ++++++++"
    Write-Host "1.-Agregar"
    Write-Host "2.-Borrar"
    Write-Host "3.-Consultar"
    Write-Host "4.-Regreso al Menu"
    Write-Host "Selecciona: "
    $op = [int](Read-Host)
    switch($op){
        1{Agregar}
        2{Borrar}
        3{Consultar}
        4{return}
        default{Write-Host "Opcion no valida" -ForegroundColor Red}
    }
}

function Monitoreo{
    Write-Host "++++++++ Monitoreo del servidor DNS ++++++++"
    $dnsService = Get-Service -Name DNS -ErrorAction SilentlyContinue
    if ($dnsService -and $dnsService.Status -eq "Running"){
        Write-Host "El servidor DNS esta activo" -ForegroundColor Green
    }else{
        Write-Host "El servidor DNS no esta activo" -ForegroundColor Red
        return
    }
    $zonas = Get-DnsServerZone -ErrorAction SilentlyContinue

    if($zonas){
        Write-Host "Zonas configuradas"
        $zonas | Format-Table -Property ZoneName, ZoneType, IsReverseLookupZone
    }else{
        Write-Host "No hay zonas configuradas" -ForegroundColor Red
    }

    foreach ($zona in $zonas){
        Write-Host "Registro en las zona $($zona.ZoneName) :"
        Get-DnsServerResourceRecord -ZoneName $zona.ZoneName | Format-Table -Property HostName, RecordType, RecordData
    }
}
