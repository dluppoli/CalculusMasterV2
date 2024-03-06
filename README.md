# Laboratorio di piattaforme e metodologie cloud - AA 2023-24
Applicazione demo per laboratori di deploy su Google Cloud Platform.

|Versione App|Lezione di riferimento|
|-|-|
|1|Lezione 2 - Virtualizzazione e IaaS|
|2|Lezione 3 - Storage dei dati|
|||

## Deploy D - Aggiunta di database SQL
1. Creare una nuova istanza Compute Engine con le seguenti caratteristiche:
    - mysqlserver as instance name
    - e2-micro Instance
    - Region us-central1
    - Zone us-central1-a
    - Spot provisioning model
    - 10 GB Persistent Disk
    - Debian 12 operating system
    - HTTP & HTTPS traffic NOT allowed
2. Collegarsi alla VM mysqlserver via SSH
3. Eseguire i seguenti comandi per l'installazione di MySql (Rif. https://cloud.google.com/compute/docs/instances/sql-server/setup-mysql)
```sh
# Aggiornamento repository e installazione wget
sudo apt-get update
sudo apt-get install -y wget

# Download MySql e verifica hash MD5
export DEB_FILE=mysql-apt-config_0.8.29-1_all.deb
cd /tmp
curl -L --output ${DEB_FILE} https://dev.mysql.com/get/${DEB_FILE}

cat > ${DEB_FILE}.md5 << EOL
f732dd7d61d18dd67877c820d690756d ${DEB_FILE}
EOL
md5sum --check ${DEB_FILE}.md5

# Installazione repository MySql e installazione di MySql
sudo dpkg -i ${DEB_FILE}
sudo apt-get update
sudo apt-get -y install mysql-community-server
```
4. Eseguire upload del file CreateDatabase.sql (o scaricarlo da github `wget https://raw.githubusercontent.com/dluppoli/CalculusMasterV2/main/CreateDatabase.sql`)
5. Eseguire lo script di creazione
```sh
sudo mysql -u root -p < CreateDatabase.sql
```
6. Collegarsi alla VM appserver via SSH
7. Eseguire i seguenti comandi:
```sh
# Clonazione repository CalculusMaster Versione 2
cd /appdata
sudo git clone https://github.com/dluppoli/CalculusMasterV2
cd CalculusMasterV2

# Creazione del file di environment. Personalizzare i valori secondo le necessità 
cat > .env << EOF
#Server config
PORT=80

#Database config
DB_HOST = __MYSQLSERVER_INSTANCE_IP__
DB_USER = calculusmaster
DB_PASSWORD = pigreco
DB = CalculusMaster

#Auth Config
SESSION_SECRET = SLKSADJFOIDSACUNQWEN
EOF

# Esecuzione applicazione
npm install
sudo npm start
```
8. Collegarsi all'ip pubblico della VM e verificare il corretto funzionamento

## Deploy E - Passaggio a Cloud SQL
Creazione istanza Cloud SQL
1. Avviare la procedura di creazione istanza Cloud SQL
2. Selezionare MySql e configurarlo in questo modo:
    - name: mysqlcloudserver
    - password: pigreco
    - Edition: enterprise
    - Preset: sandbox
    - Region: us-central1 (single zone)
    - Nella sezione Data Protection rimuovere la spunta da "Enable deletion protection"
3. Attendere la creazione dell'istanza
4. Avviare Cloud Shell
5. Eseguire l'upload del file CreateDatabase.sql su Cloud Shell
6. Collegari all'istanza mysql con `gcloud sql connect mysqlcloudserver --user=root`
7. Eseguire lo script di creazione del database con `source CreateDatabase.sql`
8. Permettere all'istanza Compute Engine appserver di connettersi all'istanza Cloud Sql
    - Entrare nel dettaglio dell'istanza cloud SQL:
    - Selezionare Connections
    - Selezionare Networking
    - Scegliere "Add a Network" specificando l'IP pubblico di appserver

Collegamento istanza appserver con istanza Cloud SQL
1. Collegarsi alla VM app server in ssh
2. Modificare il file .env di CalculusMasterV2 inserendo l'indirizzo IP pubblico dell'istanza Cloud SQL

## Deploy F - Aggiunta Cloud Storage
1. Creare un nuovo Cloud Storage Bucket con i seguenti parametri
    - name: calculusmasterdataXX (sostituendo XX con numeri/lettere a caso. Il nome del bucket deve essere globalmente univoco)
    - Location type: regional
    - Location: us-central1
    - Storage class: Standard
    - Uncheck "Enforce public access prevention on this bucket"
2. Effettuare l'upload sul bucket del file bg.jpg (nella cartella assets/img)
    - Usando cloud console
    - Usando cloud shell con il comando `gsutil cp bg.jpg gs://calculusmasterdataXX`
3. Collegarsi in SSH all'istanza appserver
4. Modificare il file style.css (nella cartella assets/css) con `nano style.css`
    - Sostituire '../img/bg.jpg' con 'https://storage.cloud.google.com/calculusmasterdataXX/bg.jpg' (sono presenti due occorrenze)
5. Cancellare il file locale bg.img dalla cartella /assets/img
6. Testare il corretto funzionamento con `npm start`