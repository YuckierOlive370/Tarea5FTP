#!/bin/bash

FTP_ROOT="/srv/ftp"
LOCAL_USER="$FTP_ROOT/LocalUser"
PUBLICA="$FTP_ROOT/publica"

GRUPOS=("reprobados" "recursadores")

InstalarFTP(){

apt update
apt install vsftpd acl -y

mkdir -p $FTP_ROOT
mkdir -p $LOCAL_USER
mkdir -p $PUBLICA

chmod 755 $FTP_ROOT
chmod 755 $LOCAL_USER
chmod 777 $PUBLICA

CrearGrupos
ConfigurarVSFTPD

systemctl restart vsftpd

echo "Servidor FTP instalado"
read
}

CrearGrupos(){

for g in "${GRUPOS[@]}"
do
groupadd $g 2>/dev/null

mkdir -p $FTP_ROOT/$g
chown root:$g $FTP_ROOT/$g
chmod 770 $FTP_ROOT/$g

done
}

ConfigurarVSFTPD(){

cat > /etc/vsftpd.conf <<EOF
listen=YES

anonymous_enable=YES
anon_root=$PUBLICA
anon_upload_enable=NO

local_enable=YES
write_enable=YES

local_umask=002

chroot_local_user=YES
allow_writeable_chroot=YES

user_sub_token=\$USER
local_root=$LOCAL_USER/\$USER

pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

xferlog_enable=YES
EOF

}

CrearUsuario(){

read -p "Usuario: " usuario

echo "Selecciona grupo"
echo "1) reprobados"
echo "2) recursadores"
read g

if [ "$g" == "1" ]; then
grupo="reprobados"
else
grupo="recursadores"
fi

useradd -m -d $LOCAL_USER/$usuario -s /usr/sbin/nologin -g $grupo $usuario
passwd $usuario

mkdir -p $LOCAL_USER/$usuario/$usuario
mkdir -p $LOCAL_USER/$usuario/$grupo
mkdir -p $LOCAL_USER/$usuario/publica

chmod 755 $LOCAL_USER/$usuario

chown $usuario:$grupo $LOCAL_USER/$usuario/$usuario
chmod 700 $LOCAL_USER/$usuario/$usuario

setfacl -m g:$grupo:rwx $LOCAL_USER/$usuario/$grupo
setfacl -m u:$usuario:rwx $LOCAL_USER/$usuario/$grupo

setfacl -m u:$usuario:rwx $LOCAL_USER/$usuario/publica
setfacl -m g:$grupo:rwx $LOCAL_USER/$usuario/publica

mount --bind $FTP_ROOT/$grupo $LOCAL_USER/$usuario/$grupo
mount --bind $PUBLICA $LOCAL_USER/$usuario/publica

echo ""
echo "Usuario creado correctamente"
read
}

EliminarUsuario(){

read -p "Usuario a eliminar: " usuario

userdel -r $usuario

rm -rf $LOCAL_USER/$usuario

echo "Usuario eliminado"
read
}

ListarUsuarios(){

ls $LOCAL_USER

read
}

EstadoServicio(){

systemctl status vsftpd

read
}

ReiniciarServicio(){

systemctl restart vsftpd

echo "Servicio reiniciado"
read
}