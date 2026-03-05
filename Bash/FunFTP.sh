#!/bin/bash

FTP_ROOT="/srv/ftp"
LOCALUSER="$FTP_ROOT/LocalUser"

PUBLICA="$FTP_ROOT/publica"

GRUPOS=("reprobados" "recursadores")

check_root(){

if [ "$EUID" -ne 0 ]; then
 echo "Ejecuta como root"
 exit
fi

}

########################################
# INSTALAR FTP
########################################

instalar_ftp(){

apt update
apt install -y vsftpd acl

crear_estructura
configurar_vsftpd
configurar_acl

systemctl enable vsftpd
systemctl restart vsftpd

echo "Servidor FTP instalado"

read

}

########################################
# ESTRUCTURA
########################################

crear_estructura(){

mkdir -p $LOCALUSER
mkdir -p $PUBLICA

chmod 755 $FTP_ROOT

for g in "${GRUPOS[@]}"
do
mkdir -p $FTP_ROOT/$g
groupadd $g 2>/dev/null
done

chmod 777 $PUBLICA

}

########################################
# VSFTPD CONFIG
########################################

configurar_vsftpd(){

cat > /etc/vsftpd.conf <<EOF

listen=YES
listen_ipv6=NO

anonymous_enable=YES
anon_root=$PUBLICA
anon_upload_enable=NO

local_enable=YES
write_enable=YES

chroot_local_user=YES
allow_writeable_chroot=YES

local_root=$LOCALUSER/\$USER

pasv_enable=YES
pasv_min_port=30000
pasv_max_port=31000

EOF

}

########################################
# CREAR USUARIO
########################################

crear_usuario(){

read -p "Usuario: " user

echo "Selecciona grupo"
echo "1) reprobados"
echo "2) recursadores"

read g

if [ "$g" = "1" ]; then
grupo="reprobados"
else
grupo="recursadores"
fi

useradd -m -g $grupo $user

passwd $user

mkdir -p $LOCALUSER/$user

mkdir $LOCALUSER/$user/$user
mkdir $LOCALUSER/$user/$grupo
mkdir $LOCALUSER/$user/publica

chown root:root $LOCALUSER/$user
chmod 755 $LOCALUSER/$user

chown $user:$grupo $LOCALUSER/$user/$user
chmod 700 $LOCALUSER/$user/$user

mount --bind $FTP_ROOT/$grupo $LOCALUSER/$user/$grupo
mount --bind $PUBLICA $LOCALUSER/$user/publica

setfacl -m g:$grupo:rwx $FTP_ROOT/$grupo

echo "Usuario creado"

systemctl restart vsftpd

read

}

########################################
# ACL
########################################

configurar_acl(){

setfacl -m d:g:reprobados:rwx $FTP_ROOT/reprobados
setfacl -m d:g:recursadores:rwx $FTP_ROOT/recursadores

}

########################################
# ELIMINAR USUARIO
########################################

eliminar_usuario(){

read -p "Usuario: " user

umount $LOCALUSER/$user/publica 2>/dev/null
umount $LOCALUSER/$user/reprobados 2>/dev/null
umount $LOCALUSER/$user/recursadores 2>/dev/null

userdel $user

rm -rf $LOCALUSER/$user

echo "Usuario eliminado"

systemctl restart vsftpd

read

}

########################################
# LISTAR USUARIOS
########################################

listar_usuarios(){

ls $LOCALUSER

read

}

########################################
# SERVICIO
########################################

estado_servicio(){

systemctl status vsftpd

read

}

reiniciar_servicio(){

systemctl restart vsftpd

}