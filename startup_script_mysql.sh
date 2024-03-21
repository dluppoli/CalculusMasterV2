sudo apt-get update
sudo apt-get install -y wget

export DEBIAN_FRONTEND=noninteractive
export DEB_FILE=mysql-apt-config_0.8.29-1_all.deb
cd /tmp
curl -L --output ${DEB_FILE} https://dev.mysql.com/get/${DEB_FILE}

sudo -E dpkg -i ${DEB_FILE}
sudo apt-get update
sudo -E apt-get -y install mysql-community-server

wget https://raw.githubusercontent.com/dluppoli/CalculusMasterV2/main/CreateDatabase.sql

sudo mysql --user=root --password=root < CreateDatabase.sql 