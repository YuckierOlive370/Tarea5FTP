#!/bin/bash
source ./FunGENERALES.sh
source ./FunFTP.sh

while true; do
    echo "===== Automatización y Gestión de FTP ====="
    echo "1.- Instalar"
    echo "2.- Verificar Servicio"
    echo "3.- Configurar"
    echo "4.- Crear Usuario"
    echo "5.- Salir"
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) InstalarPaquete "vsftpd" ;;
        2) VerificarPaquete "vsftpd" ;;
        3)
            CrearGrupos
            CrearEstructuras
            ;;
        4) CrearUsuario ;;
        5) break ;;
        *) echo "Opción inválida" ;;
    esac
    echo ""
done