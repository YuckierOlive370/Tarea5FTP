#!/bin/bash

source ./FunFTP.sh

while true
do
clear
echo "==========================="
echo "        FTP MANAGER"
echo "==========================="
echo "1) Instalar servidor FTP"
echo "2) Crear usuario FTP"
echo "3) Eliminar usuario FTP"
echo "4) Listar usuarios FTP"
echo "5) Estado del servicio"
echo "6) Reiniciar servicio"
echo "0) Salir"
echo ""

read -p "Selecciona: " op

case $op in

1) InstalarFTP ;;
2) CrearUsuario ;;
3) EliminarUsuario ;;
4) ListarUsuarios ;;
5) EstadoServicio ;;
6) ReiniciarServicio ;;
0) exit ;;
*) echo "Opcion invalida"; sleep 2 ;;

esac

done