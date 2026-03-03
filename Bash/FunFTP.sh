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
        chmod 2770 $FTP_ROOT/$grupo
    done
}

CrearEstructuras(){

    mkdir -p $GENERAL
    mkdir -p $USUARIOS

    groupadd ftpusers 2>/dev/null

cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=YES
anon_root=/srv/ftp
anon_upload_enable=NO
anon_mkdir_write_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
pam_service_name=vsftpd
chroot_local_user=NO
EOF

    chmod 755 $FTP_ROOT
    chown root:ftpusers $GENERAL
    chmod 2755 $GENERAL
    chmod 2770 $FTP_ROOT/reprobados
    chmod 2770 $FTP_ROOT/recursadores
    chown root:reprobados $FTP_ROOT/reprobados
    chown root:recursadores $FTP_ROOT/recursadores
    chmod 755 $USUARIOS

    chown root:reprobados $FTP_ROOT/reprobados
    chown root:recursadores $FTP_ROOT/recursadores

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
            useradd -d $USUARIOS/$usuario -s /bin/bash -g "$grupo" "$usuario"
            echo "$usuario:$pass" | chpasswd
            usermod -aG ftpusers "$usuario"
            echo "Usuario $usuario creado."
        else
            echo "Usuario ya existe."
        fi

        mkdir -p $USUARIOS/$usuario
        chown "$usuario:$grupo" $USUARIOS/$usuario
        chmod 750 $USUARIOS/$usuario

    done
}

CambiarGrupoUsuario() {

    read -p "Usuario a cambiar: " usuario
    read -p "Nuevo grupo (reprobados/recursadores): " nuevoGrupo

    if id "$usuario" &>/dev/null; then

        usermod -g "$nuevoGrupo" "$usuario"

        chown "$usuario:$nuevoGrupo" $USUARIOS/$usuario
        chmod 750 $USUARIOS/$usuario

        echo "Grupo cambiado correctamente."

    else
        echo "El usuario no existe."
    fi
}