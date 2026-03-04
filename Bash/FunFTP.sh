#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
source ./FunGENERALES.sh

FTP_ROOT="/srv/ftp"
GENERAL="$FTP_ROOT/general"
HOMES="$FTP_ROOT/homes"
GRUPOS=("reprobados" "recursadores")
FTP_USERS_GROUP="ftpusers"

# Crear carpetas principales y grupos
CrearGrupos() {
    groupadd $FTP_USERS_GROUP 2>/dev/null

    mkdir -p $GENERAL
    chown root:$FTP_USERS_GROUP $GENERAL
    chmod 2775 $GENERAL

    mkdir -p $HOMES
    chown root:root $HOMES
    chmod 755 $HOMES

    for grupo in "${GRUPOS[@]}"; do
        if ! getent group "$grupo" >/dev/null; then
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

# Configurar vsftpd
ConfigurarVsftpd() {
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
chroot_local_user=YES
allow_writeable_chroot=YES
EOF

    systemctl restart vsftpd

    if systemctl is-active --quiet vsftpd; then
        echo "vsftpd configurado correctamente."
    else
        echo "ERROR: vsftpd no inició"
    fi
}

# Crear usuarios
CrearUsuario() {
    read -p "¿Cuántos usuarios deseas crear? " n

    for ((i=1; i<=n; i++)); do
        read -p "Nombre del usuario: " usuario
        read -s -p "Contraseña: " pass
        echo ""
        read -p "Grupo (reprobados/recursadores): " grupo

        if ! id "$usuario" &>/dev/null; then
            useradd -d $HOMES/$usuario -s /bin/bash -g "$grupo" "$usuario"
            echo "$usuario:$pass" | chpasswd
            usermod -aG $FTP_USERS_GROUP "$usuario"
            echo "Usuario $usuario creado."
        else
            echo "Usuario ya existe."
        fi

        # Carpeta personal
        mkdir -p $HOMES/$usuario
        chown "$usuario:$grupo" $HOMES/$usuario
        chmod 700 $HOMES/$usuario   # solo dueño puede ver

        # Enlaces simbólicos a general y su grupo
        ln -s $GENERAL $HOMES/$usuario/general
        ln -s $FTP_ROOT/$grupo $HOMES/$usuario/$grupo
    done
}

# Cambiar grupo
CambiarGrupoUsuario() {
    read -p "Usuario a cambiar: " usuario
    read -p "Nuevo grupo (reprobados/recursadores): " nuevoGrupo

    if id "$usuario" &>/dev/null; then
        usermod -g "$nuevoGrupo" "$usuario"
        chown "$usuario:$nuevoGrupo" $HOMES/$usuario
        chmod 700 $HOMES/$usuario

        # Actualizar enlace simbólico a carpeta de grupo
        rm -f $HOMES/$usuario/$nuevoGrupo
        ln -s $FTP_ROOT/$nuevoGrupo $HOMES/$usuario/$nuevoGrupo

        echo "Grupo cambiado correctamente."
    else
        echo "El usuario no existe."
    fi
}