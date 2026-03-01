#!/bin/bash
source ./FunGENERALES.sh
source ./FunSSH.sh
while true; do
    echo "===== Automatización y Gestión de SSH ====="
    echo "1.- Instalar"
    echo "2.- Verificar Servicio"
    echo "3.- Mostrar el usuario actual"
    echo "4.- Listar Usuarios"
    echo "5.- Crear Usuario"
    echo "6.- Salir"
    read -p "Selecciona una opción: " opcion

    case $opcion in
        1) InstalarPaquete "openssh-server" ;;
        2) VerificarPaquete "openssh-server" ;;
        3) MostrarUsuarioActual ;;
        4) ListarUsuarios ;;
        5) CrearUsuario ;;
        6) echo "Saliendo..."; break ;;
        *) echo "Opción inválida" ;;
    esac
    echo ""
done