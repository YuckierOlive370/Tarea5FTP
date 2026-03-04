#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
source ./FunGENERALES.sh

FTP_ROOT="/srv/ftp"
GENERAL="$FTP_ROOT/general"
GRUPOS=("reprobados" "recursadores")
FTP_USERS_GROUP="ftpusers"

CrearGrupos(){
    # Grupo global de FTP
    groupadd $FTP_USERS_GROUP 2>/dev/null

    # Carpeta general
    mkdir -p $GENERAL
    chown root:$FTP_USERS_GROUP $GENERAL
    chmod 2775 $GENERAL   # lectura/escritura para todos los usuarios

    # Carpetas de grupo
    for grupo in "${GRUPOS[@]}"; do
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

cat > /etc/vsftpd.conf <<EOF
listen=YES
anonymous_enable=YES
anon_root=$GENERAL
anon_upload_enable=NO
anon_mkdir_write_enable=NO
local_enable=YES
write_enable=YES
local_umask=002
dirmessage_enable=YES
use_localtime=YES
pam_service_name=vsftpd
chroot_local_user=NO
EOF

    chmod 755 $FTP_ROOT

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
            # Carpeta personal directamente en FTP_ROOT
            mkdir -p $FTP_ROOT/$usuario
            chown "$usuario:$grupo" $FTP_ROOT/$usuario
            chmod 700 $FTP_ROOT/$usuario   # solo el dueño puede acceder

            # Crear usuario con home en su carpeta personal
            useradd -d $FTP_ROOT/$usuario -s /bin/bash -g "$grupo" "$usuario"
            echo "$usuario:$pass" | chpasswd
            usermod -aG $FTP_USERS_GROUP "$usuario"

            echo "Usuario $usuario creado."
        else
            echo "Usuario ya existe."
        fi
    done
}

CambiarGrupoUsuario() {
    read -p "Usuario a cambiar: " usuario
    read -p "Nuevo grupo (reprobados/recursadores): " nuevoGrupo

    if id "$usuario" &>/dev/null; then
        usermod -g "$nuevoGrupo" "$usuario"
        chown "$usuario:$nuevoGrupo" $FTP_ROOT/$usuario
        chmod 700 $FTP_ROOT/$usuario
        echo "Grupo cambiado correctamente."
    else
        echo "El usuario no existe."
    fi
}