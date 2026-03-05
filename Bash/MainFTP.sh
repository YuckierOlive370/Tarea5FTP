#!/bin/bash

source ./FunFTP.sh

check_root

while true
do
clear

echo "=============================="
echo "        FTP MANAGER"
echo "=============================="
echo "1) Instalar servidor FTP"
echo "2) Crear usuario FTP"
echo "3) Eliminar usuario FTP"
echo "4) Listar usuarios FTP"
echo "5) Estado del servicio"
echo "6) Reiniciar servicio"
echo "0) Salir"

read -p "Selecciona: " op

case $op in

1) instalar_ftp ;;
2) crear_usuario ;;
3) eliminar_usuario ;;
4) listar_usuarios ;;
5) estado_servicio ;;
6) reiniciar_servicio ;;
0) exit ;;

*) echo "Opcion invalida"; sleep 2 ;;

esac

done