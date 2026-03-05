#!/bin/bash

PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH

FTP_ROOT="/srv/ftp"
LOCALUSER="$FTP_ROOT/LocalUser"
PUBLICA="$FTP_ROOT/publica"

GRUPOS=("reprobados" "recursadores")

########################################

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

crear_grupos
crear_estructura
configurar_vsftpd
configurar_acl

systemctl enable vsftpd
systemctl restart vsftpd

echo "FTP instalado correctamente"

read

}

########################################
# GRUPOS
########################################

crear_grupos(){

for g in "${GRUPOS[@]}"
do
groupadd $g 2>/dev/null
done

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
chmod 770 $FTP_ROOT/$g
done

chmod 777 $PUBLICA

}

########################################
# CONFIGURAR VSFTPD
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

xferlog_enable=YES

EOF

}

########################################
# ACL
########################################

configurar_acl(){

setfacl -d -m g:reprobados:rwx $FTP_ROOT/reprobados
setfacl -d -m g:recursadores:rwx $FTP_ROOT/recursadores

}

########################################
# CREAR USUARIO
########################################

crear_usuario(){

read -p "Usuario: " user

if id "$user" &>/dev/null; then
echo "Usuario ya existe"
sleep 2
return
fi

echo "Selecciona grupo"
echo "1) reprobados"
echo "2) recursadores"

read g

if [ "$g" = "1" ]; then
grupo="reprobados"
else
grupo="recursadores"
fi

useradd -m -s /usr/sbin/nologin -g "$grupo" "$user"

passwd "$user"

mkdir -p $LOCALUSER/$user

mkdir $LOCALUSER/$user/$user
mkdir $LOCALUSER/$user/$grupo
mkdir $LOCALUSER/$user/publica

chown root:root $LOCALUSER/$user
chmod 755 $LOCALUSER/$user

chown $user:$grupo $LOCALUSER/$user/$user
chmod 700 $LOCALUSER/$user/$user

crear_bind_mount "$user" "$grupo"

systemctl restart vsftpd

echo "Usuario creado correctamente"

read

}

########################################
# BIND MOUNT
########################################

crear_bind_mount(){

user=$1
grupo=$2

mount --bind $FTP_ROOT/$grupo $LOCALUSER/$user/$grupo
mount --bind $PUBLICA $LOCALUSER/$user/publica

if ! grep -q "$LOCALUSER/$user/$grupo" /etc/fstab
then
echo "$FTP_ROOT/$grupo $LOCALUSER/$user/$grupo none bind 0 0" >> /etc/fstab
fi

if ! grep -q "$LOCALUSER/$user/publica" /etc/fstab
then
echo "$PUBLICA $LOCALUSER/$user/publica none bind 0 0" >> /etc/fstab
fi

}

########################################
# ELIMINAR USUARIO
########################################

eliminar_usuario(){

read -p "Usuario: " user

if ! id "$user" &>/dev/null; then
echo "Usuario no existe"
sleep 2
return
fi

umount $LOCALUSER/$user/publica 2>/dev/null
umount $LOCALUSER/$user/reprobados 2>/dev/null
umount $LOCALUSER/$user/recursadores 2>/dev/null

sed -i "/$LOCALUSER\/$user/d" /etc/fstab

userdel "$user"

rm -rf $LOCALUSER/$user

systemctl restart vsftpd

echo "Usuario eliminado"

read

}

########################################
# LISTAR
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

echo "Servicio reiniciado"

sleep 2

}