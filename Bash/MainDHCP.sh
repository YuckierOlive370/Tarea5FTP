#!/bin/bash
source ./FunGENERALES.sh
source ./FunDHCP.sh
while true; do
    echo "===== Automatización y Gestión del Servidor DHCP ====="
    echo "1.- Verificar la presencia del servicio"
    echo "2.- Instalar el servicio"
    echo "3.- Configurar"
    echo "4.- Monitoreo"
    echo "5.- Reiniciar Servicios"
    echo "6.- Salir"
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) VerificarPaquete "isc-dhcp-server" ;;
        2) InstalarPaquete "isc-dhcp-server" ;;
        3) Configurar ;;
        4) ListarConcesiones ;;
        5) Reiniciar ;;
        6) echo "Saliendo..."; break ;;
        *) echo "Opción inválida" ;;
    esac
    echo ""
done