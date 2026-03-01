#!/bin/bash

FTP_ROOT="/srv/ftp"
GENERAL="$FTP_ROOT/general"
REPROBADOS="$FTP_ROOT/reprobados"
RECURSADORES="$FTP_ROOT/recursadores"
USUARIOS="$FTP_ROOT/usuarios"

echo "===== CONFIGURANDO SERVIDOR FTP LINUX ====="

# 1️⃣ Instalación idempotente
if ! dpkg -l | grep -q vsftpd; then
    echo "Instalando vsftpd..."
    apt update
    apt install -y vsftpd
else
    echo "vsftpd ya está instalado."
fi

# 2️⃣ Crear grupos si no existen
for grupo in reprobados recursadores; do
    if ! getent group $grupo > /dev/null; then
        groupadd $grupo
        echo "Grupo $grupo creado."
    else
        echo "Grupo $grupo ya existe."
    fi
done

# 3️⃣ Crear estructura de directorios
mkdir -p $GENERAL $REPROBADOS $RECURSADORES $USUARIOS

chmod 755 $GENERAL
chmod 770 $REPROBADOS
chmod 770 $RECURSADORES
chmod 755 $USUARIOS

# 4️⃣ Configuración vsftpd
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

# 5️⃣ Creación masiva de usuarios
read -p "¿Cuántos usuarios deseas crear? " n

for ((i=1;i<=n;i++))
do
    read -p "Nombre del usuario: " usuario
    read -s -p "Contraseña: " pass
    echo ""

    read -p "Grupo (reprobados/recursadores): " grupo

    # Crear usuario si no existe
    if ! id "$usuario" &>/dev/null; then
        useradd -m -d $USUARIOS/$usuario -s /bin/bash -g $grupo $usuario
        echo "$usuario:$pass" | chpasswd
        echo "Usuario $usuario creado."
    else
        echo "Usuario ya existe, actualizando grupo..."
        usermod -g $grupo $usuario
    fi

    # Crear carpeta personal
    mkdir -p $USUARIOS/$usuario
    chown $usuario:$grupo $USUARIOS/$usuario
    chmod 770 $USUARIOS/$usuario

    # Permisos grupo
    chown root:$grupo $FTP_ROOT/$grupo
    chmod 770 $FTP_ROOT/$grupo

done

echo "===== CONFIGURACIÓN COMPLETADA ====="