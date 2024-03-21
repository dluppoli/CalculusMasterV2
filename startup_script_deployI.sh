# Aggiornamento repository
apt-get update
# Installazione git
apt-get install -yq git

# Installazione node.js (estratto da https://cloud.google.com/nodejs/getting-started/getting-started-on-compute-engine?hl=it)
mkdir /opt/nodejs
curl https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.gz | tar xvzf - -C /opt/nodejs --strip-components=1
ln -s /opt/nodejs/bin/node /usr/bin/node
ln -s /opt/nodejs/bin/npm /usr/bin/npm

# Clonazione repository CalculusMaster Versione 2
git clone https://github.com/dluppoli/CalculusMasterV2
cd CalculusMasterV2

DB_IP=$(curl http://metadata.google.internal/computeMetadata/v1/instance/attributes/db_ip -H "Metadata-Flavor: Google")

# Creazione del file di environment. Personalizzare i valori secondo le necessità 
cat > .env << EOF
#Server config
PORT=80

#Database config
DB_HOST = $DB_IP
DB_USER = calculusmaster
DB_PASSWORD = pigreco
DB = CalculusMaster

#Auth Config
SESSION_SECRET = SLKSADJFOIDSACUNQWEN
EOF

# Esecuzione applicazione
npm install
npm start
