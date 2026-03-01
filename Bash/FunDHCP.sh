#!/bin/bash
source ./FunGENERALES.sh

INTERFAZ="ens37"
MASCARA="255.255.255.0"

Configurar() {
    echo "Iniciando la configuracion..."
    read -p "Nombre del ambito: " scope

    ip_fija=$(PedirIp "IP fija del servidor: ")
    mascara=$(CalcularMascara "$ip_fija")
    MASCARA="$mascara"

    read -p "Gateway (opcional, deja vacio si no aplica): " gateway

    echo "IP fija del servidor: $ip_fija"

    inicioInt=$(IPaInt "$ip_fija")
    inicioInt=$((inicioInt + 1))

    rango_inicio=$(printf "%d.%d.%d.%d" \
        $(( (inicioInt >> 24) & 255 )) \
        $(( (inicioInt >> 16) & 255 )) \
        $(( (inicioInt >> 8) & 255 )) \
        $(( inicioInt & 255 ))
    )

    echo "IP inicial del ámbito: $rango_inicio"

    sudo bash -c "cat > /etc/network/interfaces.d/$INTERFAZ.cfg" <<EOF
auto $INTERFAZ
iface $INTERFAZ inet static
    address $ip_fija
    netmask $mascara
EOF

    echo "Configuración de red escrita en /etc/network/interfaces.d/$INTERFAZ.cfg"
    echo "Recargando interfaz..."
    sudo ip addr flush dev $INTERFAZ
    prefix=$(MaskToPrefix "$mascara")
    sudo ip addr add $ip_fija/$prefix dev $INTERFAZ
    sudo ip link set $INTERFAZ up


    while true; do
        rango_fin=$(PedirIp "IP final: ")

        inicioInt=$(IPaInt "$rango_inicio")
        finInt=$(IPaInt "$rango_fin")
        maskInt=$(IPaInt "$mascara")

        if (( inicioInt > finInt )); then
            echo "La IP inicial no puede ser mayor que la IP final"
        elif (( (inicioInt & maskInt) != (finInt & maskInt) )); then
            echo "El rango no pertenece a la misma subred"
        else
            break
        fi
    done

    echo "IP final valida: $rango_fin"

    read -p "DNS primario (opcional): " dns
    read -p "DNS alternativo (opcional): " dns_alt
    read -p "Tiempo de concesion (en segundos): " lease_time

    redInt=$(( inicioInt & maskInt ))
    red=$(printf "%d.%d.%d.0" \
        $(( (redInt >> 24) & 255 )) \
        $(( (redInt >> 16) & 255 )) \
        $(( (redInt >> 8) & 255 ))
    )

    echo "Configurando DHCP..."
    sudo apt-get update -y -qq > /dev/null 2>&1
    sudo systemctl enable isc-dhcp-server > /dev/null 2>&1
    sudo sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$INTERFAZ\"/" /etc/default/isc-dhcp-server

    options=""
if [[ -n "$gateway" ]]; then
    options+=$'    option routers '"$gateway"$';\n'
fi

if [[ -n "$dns" || -n "$dns_alt" ]]; then
    dns_list=""
    [[ -n "$dns" ]] && dns_list="$dns"
    [[ -n "$dns_alt" ]] && dns_list="$dns_list, $dns_alt"
    options+=$'    option domain-name-servers '"$dns_list"$';\n'
fi


    sudo bash -c "cat > /etc/dhcp/dhcpd.conf" <<EOF
default-lease-time $lease_time;
max-lease-time $lease_time;

subnet $red netmask $MASCARA {
    range $rango_inicio $rango_fin;
$options}
EOF

    echo "Validando configuración..."
    sudo dhcpd -t
    echo "Reiniciando servicio DHCP..."
    sudo systemctl restart isc-dhcp-server
    echo "Ambito DHCP configurado correctamente."
}

ListarConcesiones() {
    if dpkg -l | grep -q isc-dhcp-server; then
        systemctl status isc-dhcp-server --no-pager
        echo "Concesiones activas:"
        cat /var/lib/dhcp/dhcpd.leases
    else
        echo "No esta instalado DHCP"
    fi
}

Reiniciar() {
    if dpkg -l | grep -q isc-dhcp-server; then
        sudo systemctl restart isc-dhcp-server
        echo "Servicio DHCP reiniciado."
    else
        echo "No esta instalado DHCP"
    fi
}