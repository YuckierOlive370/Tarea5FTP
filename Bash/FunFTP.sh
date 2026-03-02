#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
source ./FunGENERALES.sh

FTP_ROOT="/srv/ftp"
GENERAL="$FTP_ROOT/general"
USUARIOS="$FTP_ROOT/usuarios"

CrearGrupos(){
    for grupo in reprobados recursadores; do
        if ! getent group "$grupo" > /dev/null; then
            groupadd "$grupo"
            echo "Grupo $grupo creado."
        else
            echo "Grupo $grupo ya existe."
        fi

        mkdir -p $FTP_ROOT/$grupo
        chown root:$grupo $FTP_ROOT/$grupo
        chmod 770 $FTP_ROOT/$grupo
    done
}

CrearEstructuras(){

    mkdir -p $GENERAL
    mkdir -p $USUARIOS

cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=YES
anon_root=$GENERAL
anon_upload_enable=NO
anon_mkdir_write_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
chroot_local_user=YES
allow_writeable_chroot=YES
pam_service_name=vsftpd
user_sub_token=\$USER
local_root=$USUARIOS/\$USER

EOF

    systemctl restart vsftpd

    if systemctl is-active --quiet vsftpd; then
        echo "vsftpd configurado correctamente."
    else
        echo "ERROR: vsftpd no inició"
    fi
}

CrearUsuario(){

    read -p "¿Cuántos usuarios deseas crear? " n

    for ((i=1;i<=n;i++))
    do
        read -p "Nombre del usuario: " usuario
        read -s -p "Contraseña: " pass
        echo ""
        read -p "Grupo (reprobados/recursadores): " grupo

        if ! id "$usuario" &>/dev/null; then
            useradd -m -d $USUARIOS/$usuario -s /bin/bash -g "$grupo" "$usuario"
            echo "$usuario:$pass" | chpasswd
            echo "Usuario $usuario creado."
        else
            echo "Usuario ya existe."
        fi

        mkdir -p $USUARIOS/$usuario
        chown "$usuario:$grupo" $USUARIOS/$usuario
        chmod 770 $USUARIOS/$usuario
    done
}

CambiarGrupoUsuario() {

    read -p "Usuario a cambiar: " usuario
    read -p "Nuevo grupo (reprobados/recursadores): " nuevoGrupo

    if id "$usuario" &>/dev/null; then
        usermod -g $n
        nuevoGrupo $usuario

        # Ajustar permisos carpeta personal
        chown $usuario:$nuevoGrupo $USUARIOS/$usuario
        chmod 770 $USUARIOS/$usuario

        echo "Grupo cambiado correctamente."
        echo "Ahora $usuario solo puede acceder a /$nuevoGrupo"
    else
        echo "El usuario no existe."
    fi
}