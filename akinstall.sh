#!/bin/sh

# define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
LRED='\033[1;31m'
LGREEN='\033[1;32m'
RC='\033[0m'

# make sure lists are up to date
apt-get -qq update

# install sudo in case it is missing
apt-get -qq install sudo -y

# make sure that ifconfig works
sudo apt-get -qq install net-tools

# test for the main folder
if [ -d "/root/hxsy" ] ; then
echo "文件夹/root/hxsy 已经存在，请在运行脚本前重命名或删除它。"
echo "删除现有文件夹？(y/n)"
	read INVAR
	if [ "$INVAR" != "y" ] && [ "$INVAR" != "Y" ] ; then
		exit
	fi
	rm -rf "/root/hxsy"
fi
mkdir "/root/hxsy" -m 777
cd "/root/hxsy"

# get ip info; select ip
EXTIP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
if [ "$EXTIP" != "" ] ; then
	echo "请选择你的IP地址:\n1) IP地址: $EXTIP\n2) 输入其他IP"
	read INVAR
else
	INVAR="2"
fi
if [ "$INVAR" = "2" ] ; then
	echo "请输入您需要设置的IP:"
	read EXTIP
fi

# select server version
echo "Select the version you want to install.\n1) 版号007.010.01.02 (recommended)\n2) 版号007.004.01.02\n3)　技术提供:妖雨 \n4)　　QQ：9846919 ) "
read AKVERSION

# make sure start / stop commands are working
sudo apt-get -qq install psmisc -y

# install wget in case it is missing
sudo apt-get -qq install wget -y

# install unzip in case it is missing
sudo apt-get -qq install unzip -y

# install postgresql in case it is missing
sudo apt-get -qq install postgresql -y
POSTGRESQLVERSION=$(psql --version | grep -Eo '[0-9].[0-9]' | head -n1)

# install pwgen in case it is missing
sudo apt-get -qq install pwgen -y

# generate database password
DBPASS=$(pwgen -s 32 1)

# setup postgresql
cd "/etc/postgresql/$POSTGRESQLVERSION/main"
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" postgresql.conf
sed -i "s+host    all             all             127.0.0.1/32            md5+host    all             all             0.0.0.0/0            md5+g" pg_hba.conf

# change password for the postgres account
sudo -u postgres psql -c "ALTER user postgres WITH password '$DBPASS';"

# ready ip for hexpatch
PATCHIP=$(printf '\\x%02x\\x%02x\\x%02x\n' $(echo "$EXTIP" | grep -o [0-9]* | head -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n2 | tail -n1) $(echo "$EXTIP" | grep -o [0-9]* | head -n3 | tail -n1))

# set version name
VERSIONNAME="NONE"

# --------------------------------------------------
# yokohiro - 010.004.01.02
# --------------------------------------------------
if [ "$AKVERSION" = 1 ] ; then
	cd "/root/hxsy"
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/yokohiro_007_010_01_02" -O "yokohiro_007_010_01_02"
	chmod 777 yokohiro_007_010_01_02
	. "/root/hxsy/yokohiro_007_010_01_02"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/xxxxxxxx/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/192.168.178.59/$EXTIP/g" "GatewayServer/setup.ini"
	sed -i "s/xxxxxxxx/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/192.168.178.59/$EXTIP/g" "TicketServer/setup.ini"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "WorldServer/WorldServer"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "ZoneServer/ZoneServer"
	
	# Data folder
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
	unzip "Data.zip" -d "Data"
	rm -f "Data.zip"
	
	# SQL files
	wget --no-check-certificate "$SQLFILES" -O "SQL.zip"
	unzip "SQL.zip" -d "SQL"
	rm -f "SQL.zip"
	
	# set permissions
	chmod 777 /root -R
	
	# install postgresql database
	service postgresql restart
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffdb1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffmember encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.bak';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.bak';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.bak';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.178.59';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.178.59';"
	
	# remove server setup files
	rm -f yokohiro_007_010_01_02
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="yokohiro - 007.010.01.02"
	CREDITS="yokohiro, Eperty123 and WangWeiJing1262"
fi

# --------------------------------------------------
# wangweijing1262 - 007.004.01.02
# --------------------------------------------------
if [ "$AKVERSION" = 2 ] ; then
	cd "/root/hxsy"
	wget --no-check-certificate "https://raw.githubusercontent.com/haruka98/ak_oneclick_installer/master/wangweijing1262_007_004_01_02" -O "wangweijing1262_007_004_01_02"
	chmod 777 wangweijing1262_007_004_01_02
	. "/root/hxsy/wangweijing1262_007_004_01_02"
	
	# config files
	wget --no-check-certificate "$MAINCONFIG" -O "config.zip"
	unzip "config.zip"
	rm -f "config.zip"
	sed -i "s/xxxxxxxx/$DBPASS/g" "setup.ini"
	
	# subservers
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$SUBSERVERSID" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$SUBSERVERSID" -O "server.zip" && rm -rf "/tmp/cookies.txt"
	unzip "server.zip"
	rm -f "server.zip"
	sed -i "s/192.168.178.59/$EXTIP/g" "GatewayServer/setup.ini"
	sed -i "s/xxxxxxxx/$DBPASS/g" "GatewayServer/setup.ini"
	sed -i "s/192.168.178.59/$EXTIP/g" "TicketServer/setup.ini"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "WorldServer/WorldServer"
	sed -i "s/\xc0\xa8\xb2/$PATCHIP/g" "ZoneServer/ZoneServer"
	
	# Data folder
	wget --no-check-certificate --load-cookies "/tmp/cookies.txt" "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate "https://docs.google.com/uc?export=download&id=$DATAFOLDER" -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=$DATAFOLDER" -O "Data.zip" && rm -rf "/tmp/cookies.txt"
	unzip "Data.zip" -d "Data"
	rm -f "Data.zip"
	
	# SQL files
	wget --no-check-certificate "$SQLFILES" -O "SQL.zip"
	unzip "SQL.zip" -d "SQL"
	rm -f "SQL.zip"
	
	# set permissions
	chmod 777 /root -R
	
	# install postgresql database
	service postgresql restart
	sudo -u postgres psql -c "create database ffaccount encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffdb1 encoding 'UTF8' template template0;"
	sudo -u postgres psql -c "create database ffmember encoding 'UTF8' template template0;"
	sudo -u postgres psql -d ffaccount -c "\i '/root/hxsy/SQL/FFAccount.bak';"
	sudo -u postgres psql -d ffdb1 -c "\i '/root/hxsy/SQL/FFDB1.bak';"
	sudo -u postgres psql -d ffmember -c "\i '/root/hxsy/SQL/FFMember.bak';"
	sudo -u postgres psql -d ffaccount -c "UPDATE worlds SET ip = '$EXTIP' WHERE ip = '192.168.178.59';"
	sudo -u postgres psql -d ffdb1 -c "UPDATE serverstatus SET ext_address = '$EXTIP' WHERE ext_address = '192.168.178.59';"
	
	# remove server setup files
	rm -f wangweijing1262_007_004_01_02
	
	#set the server date to 2013
	timedatectl set-ntp 0
	date -s "$(date +'2013%m%d %H:%M')"
	hwclock --systohc
	
	# setup info
	VERSIONNAME="wangweijing1262 - 007.004.01.02"
	CREDITS="WangWeiJing1262"
fi

# --------------------------------------------------
# yokohiro - 003.005.01.04
# --------------------------------------------------

# --------------------------------------------------
# genz - 003.005.01.04
# --------------------------------------------------

# --------------------------------------------------
# eperty123 - 003.005.01.04
# --------------------------------------------------

# --------------------------------------------------
# hycker - 003.005.01.03
# --------------------------------------------------


if [ "$VERSIONNAME" = "NONE" ] ; then
# 显示错误
echo "${RED}-----------------------------------------------”
echo "安装失败！"
echo "-------------------------------------------------------”
echo "无法安装所选版本。请重试并选择其他版本。${RC}"
else
# 显示信息屏幕
echo "${LGREEN}-------------------------------------------- ------”
echo "安装完成！"
echo "------------------------------------------------ ——”
echo "服务器版本：$VERSIONNAME"
echo "服务器 IP: $EXTIP"
echo "Postgresql 版本：$POSTGRESQLVERSION"
echo "数据库用户：postgres"
echo "数据库密码：$DBPASS"
echo "服务器路径：/root/hxsy/"
echo "Postgresql 配置路径：/etc/postgresql/$POSTGRESQLVERSION/main/"
echo "\n一定要感谢 $CREDITS!"
echo "\n要启动服务器，请运行 /root/hxsy/start"
echo "要停止服务器，请运行 /root/hxsy/stop${RC}"
fi
