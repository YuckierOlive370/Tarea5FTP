#!/bin/bash
source ./FunGENERALES.sh

function MostrarUsuarioActual() {
    whoami
}

function ListarUsuarios() {
    cut -d: -f1 /etc/passwd
}

function CrearUsuario() {
    local FeatureName=$1
    if $FeatureName &>/dev/null; then
        echo "El usuario $FeatureName ya existe."
    else
        sudo adduser $FeatureName
        sudo usermod -aG sudo $FeatureName
        echo "Usuario $FeatureName creado y agregado al grupo sudo."
    fi
}