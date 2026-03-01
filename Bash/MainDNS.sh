#!/bin/bash
source ./FunGENERALES.sh
source ./FunDNS.sh
while true; do
    echo "===== Automatización y Gestión de DNS ====="
    echo "1.- Verificar Instalacion"
    echo "2.- Instalar"
    echo "3.- Configurar"
    echo "4.- Reconfigurar"
    echo "5.- ABC Dominios"
    echo "6.- Monitoreo"
    echo "7.- Salir"
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) VerificarPaquete "bind9 dnsutils" ;;
        2) InstalarPaquete "bind9 dnsutils" ;;
        3) Configurar ;;
        4) Reconfigurar ;;
        5) ABCdominios ;;
        6) Monitoreo ;;
        7) echo "Saliendo..."; break ;;
        *) echo "Opción inválida" ;;
    esac
    echo ""
done