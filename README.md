# Laboratorio di piattaforme e metodologie cloud - AA 2024-25
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
6. Modificare la configurazione della VM rimuovendo l'IP pubblico (external). Riavviare.
7. Collegarsi alla VM appserver via SSH
8. Eseguire i seguenti comandi:
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
9. Collegarsi all'ip pubblico della VM e verificare il corretto funzionamento

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

## Deploy H - Scalabilità orizzontale tramite MIG
1. (se necessario) Creare l'istanza Cloud SQL come previsto dal deploy E
    - Aggiungendo anche un ip privato, selezionando la relativa opzione nella sezione Connections
        - Selezionare la default network e attivare il private service access (abilitando la relativa API e lasciando a Google assegnare un IP)
    - Evitando di compiere il passo 8 in quanto non sono noti gli indirizzi IP delle istanze create dal MIG
2. Creare un nuovo Cloud Storage Bucket con i seguenti parametri
    - name: calculusmasterdeploybucketXX (sostituendo XX con numeri/lettere a caso. Il nome del bucket deve essere globalmente univoco)
    - Location type: regional
    - Location: us-central1
    - Storage class: Standard
3. Aggiungere una nuova permission aggiungendo il principal allUsers con il ruolo di Storage Object Viewer 
4. Caricare sul bucket il file startup_script_deployH.sh tramite `gsutil cp startup_script_deployH.sh gs://calculusmasterdeploybucketXX`. Lo script deve contenere i seguenti passi (estratti dai deploy precedenti, con la rimozione del comando sudo) ed è recuperabile anche da https://raw.githubusercontent.com/dluppoli/CalculusMasterV2/main/startup_script_deployH.sh. Modificare opportunamente i parametri di connessione a Cloud SQL
```sh
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
npm start
```
4. Configurare una instance template con la seguente configurazione:
    - appservertemplate as instance name
    - Regional in us-central1
    - e2-micro Instance
    - Spot provisioning model
    - 10 GB Persistent Disk
    - Debian 12 operating system
    - HTTP & HTTPS traffic allowed
    - Nella sezione Advanced Options > Management > Metadata aggiungere il metadato di key = startup-script-url e value = gs://calculusmasterdeploybucketXX/startup_script_deployH.sh
5. Creare un Managed Instance Group con i seguenti parametri
    - appservermig as name
    - appservertemplate as instance template
    - multiple zone, scegliento region us-central1
    - Settare a 2 il numero minimo di istanze
    - Settare a 4 il numero minimo di istanze
6. Verificare il corretto funzionamento:
    - constatando che sono state create due istanze
    - constatando che CalculusMaster risponde ad entrambi gli indirizzi IP

## Deploy I – Aggiunta Cloud Load Balancer e CDN 
1. Creare un nuovo Application Load Balancer (HTTP/S)
2. Configurarlo con i seguenti parametri:
    - From Internet to my VMs or serverless services
    - Global external Application Load Balancer
3. Assegnare appserverlb come nome
4. Confermare la frontend configuration
5. Nella backend configuration creare un nuovo backend service con i seguenti parametri:
    - name: appserverbackend
    - instance group: appservermig
    - port number: 80
    - creare un nuovo health check
6. Attendere la creazione del LB e collegarsi all'IP pubblico per verificare la corretta operatività

## Deploy I (semplificato) con Terraform
1. Caricare il file `startup_script_deployI.sh` in un bucket Cloud Storage esistente o in uno nuovo appositamente creato
2. Entrare nella cartella `terraform` contenente i file dell'infrastruttura
3. Editare il file `terraform.tfvars` impostando l'id del progetto GCP e l'indirizzo gs:// del file caricato al punto 1
4. Eseguire i seguenti comandi terraform
```sh
terraform init
terraform validate
terraform plan
terraform apply
```
5. Verificare il corretto funzionamento dell'infrastruttura creata
6. Cancellare l'infrastruttura con `terraform destroy`

## Terraform state su cloud storage
1. Creare un nuovo bucket Cloud Storage o riutilizzare uno di quelli utilizzati in precedenza
2. Aggiungere all'infrastruttura terraform in file `backend.tf` con il seguente contenuto, sostituendo BUCKET_NAME con il nome del bucket identificato al punto precedente:
```
terraform {
 backend "gcs" {
   bucket  = "BUCKET_NAME"
   prefix  = "terraform/state"
 }
}
```
3. Eseguire il comando `terraform init` accettando di trasferire lo stato locale sul bucket remoto


## Deploy N - Container su compute engine
1. Creare docker file con le seguenti informazioni
```dockerfile
FROM node:18-alpine3.18
RUN mkdir -p /opt/app
WORKDIR /opt/app
COPY package.json package-lock.json ./
RUN npm install
COPY ./ .
CMD [ "npm", "start"]
```
2. Aggiungere il file .dockerignore per evitare di copiare file non necessari
```
.vscode/
.git/
.gitignore
.dockerignore
.env
dockerfile
node_modules/
terraform*
startup_script*
CreateDatabase.sql
```
3. Creare l'immagine docker inserendo il riferimento al proprio repository di immagini `docker build -t DOKER_REPO/calculusmaster:n .`
4. Pubblicare l'immagine sul proprio repositrory docker `docker push DOKER_REPO/calculusmaster:n`
5. Eseguire deploy terraform contenuto nella cartella terraformContainer, impostando adeguatamente le variabili contenute nel file terraform.tfvars
```sh
terraform init
terraform validate
terraform plan
terraform apply
```

## Deploy O - Container su Cloud Run
1. Si utilizza la stessa immagine creata nel deploy N
2. Eseguire deploy terraform contenuto nella cartella terraformCloudRun, impostando adeguatamente le variabili contenute nel file terraform.tfvars
```sh
terraform init
terraform validate
terraform plan
terraform apply
```

## Deploy P - Aggiunta di un sistema CI/CD al deploy O
Con il deploy O operativo eseguire i seguenti passi:
1. Creare un repository chiamato CalculusMasterV2 su Cloud Source Repositories. Prendere nota dell'indirizzo del repository, che dovrebbe essere simile a `https://source.developers.google.com/p/unibocloud2025-422006/r/CalculusMasterV2`
2. Caricare il codice di CalculusMaster sul nuovo repository:
```sh
#Clonare il repository di CalculusMasterV3 (se non già fatto in precedenza). Utilizzare CloudShell per comodità nelle autorizzazioni
git clone https://github.com/dluppoli/CalculusMasterV2
cd CalculusMasterV2

# Autenticare cloud shell verso il nuovo repo
git config --global credential.https://source.developers.google.com.helper gcloud.sh

# Aggiungere il nuovo repository remoto ed effettuare il push
git remote add google https://source.developers.google.com/p/unibocloud2025-422006/r/CalculusMasterV2
git push --all google
```
3. Creare il seguente file cloudbuild.yaml
```yaml
steps:
  - name: "gcr.io/cloud-builders/docker"
    args:
      ["build", "-t", "gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${SHORT_SHA}", "."]

  - name: "gcr.io/cloud-builders/docker"
    args: ["push", "gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${SHORT_SHA}"]

  - name: "gcr.io/cloud-builders/gcloud"
    args:
      [
        "run",
        "deploy",
        "${_SERVICE_NAME}",
        "--image",
        "gcr.io/$PROJECT_ID/${_SERVICE_NAME}:${SHORT_SHA}",
        "--region",
        "us-central1",
        "--platform",
        "managed",
        "--allow-unauthenticated",
      ]
```
4. Creare un Cloud Build, avviato (trigger) dai push sul repository precedentemente creato. Configurare la variabile d'ambiente _SERVICE_NAME al nome del servizio cloud run creato al deploy O
5. Effettuare il push di cloudbuild.yaml e verificare il corretto funzionamento del deploy
```sh
git add cloudbuild.yaml
git commit -m "aggiunta cloud build"
git push google
```
6. (Opzionalmente) Apportare modifiche al codice, effettuare il push e verificare il corretto aggiornamento del servizio cloud run
