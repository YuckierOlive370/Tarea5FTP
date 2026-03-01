#!/bin/bash

INTERFAZ="ens37"
MASCARA="255.255.255.0"

VerificarRoot() {
    if [ "$EUID" -ne 0 ]; then
        echo "Este script debe ejecutarse como root"
        exit 1
    fi
}

InstalarPaquete() {
    local paquete=$1
    read -p "¿Deseas Instalarlo? (S/N): " r
    if [[ $r =~ ^[sS]$ ]]; then
    echo "Instalando paquete: '$paquete'"
    apt update -y -qq > /dev/null 2>&1
    apt install "$paquete" -y -qq > /dev/null 2>&1
    echo "Instalacion finalizada"
    fi
}

VerificarPaquete() {
    local paquete=$1
    if dpkg -l | grep -q "$paquete"; then
        echo "'$paquete' ya está instalado"
        read -p "¿Deseas reinstalarlo? (S/N): " r
        if [[ $r =~ ^[sS]$ ]]; then
            InstalarPaquete
        fi
    else
        echo "El servicio '$paquete' no está instalado"
    fi
}

ValidarIp() { # valida formato y descarta 255.255.255.255 y 0.0.0.0
    local ip=$1
    if [[ $ip =~ ^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$ ]]; then
        [[ "$ip" != "255.255.255.255" && "$ip" != "0.0.0.0" && "$ip" != "127.0.0.1" ]]
        return $?
    fi
    return 1
}

IPaInt() {
    local IFS=.
    read -r a b c d <<< "$1"
    echo $(( (a<<24) + (b<<16) + (c<<8) + d ))
}

PedirIp() {
    local mensaje=$1
    while true; do
        read -p "$mensaje" ip
        if ValidarIp "$ip"; then
            echo "$ip"
            return
        else
            echo "IP no valida, intenta de nuevo"
        fi
    done
}

CalcularMascara() {
    local ip=$1
    local IFS=.
    read -r a b c d <<< "$ip"

    if (( a >= 1 && a <= 126 )); then
        echo "255.0.0.0"
    elif (( a >= 128 && a <= 191 )); then
        echo "255.255.0.0"
    elif (( a >= 192 && a <= 223 )); then
        echo "255.255.255.0"
    else
        echo "255.255.255.0"
    fi
}

MaskToPrefix() {
    case "$1" in
        255.0.0.0) echo 8 ;;
        255.255.0.0) echo 16 ;;
        255.255.255.0) echo 24 ;;
        255.255.255.128) echo 25 ;;
        255.255.255.192) echo 26 ;;
        255.255.255.224) echo 27 ;;
        255.255.255.240) echo 28 ;;
        255.255.255.248) echo 29 ;;
        255.255.255.252) echo 30 ;;
        255.255.255.254) echo 31 ;;
        255.255.255.255) echo 32 ;;
        *) echo 0 ;;
    esac
}