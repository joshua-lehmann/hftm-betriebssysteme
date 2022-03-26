# Workbook Betriebssysteme hftm

- [Workbook Betriebssysteme hftm](#workbook-betriebssysteme-hftm)
  - [Installation & Einrichtung Linux VM](#installation--einrichtung-linux-vm)
  - [SSH](#ssh)
    - [SSH Key](#ssh-key)
    - [SSH Key only Authentication](#ssh-key-only-authentication)
  - [Filesystem und LEMP](#filesystem-und-lemp)
    - [Disks auf unserer Ubuntu VM](#disks-auf-unserer-ubuntu-vm)
    - [Disk hinzufügen](#disk-hinzufügen)
  - [Webserver](#webserver)
    - [MERN](#mern)
      - [MongoDB](#mongodb)
      - [Node.js](#nodejs)
      - [React.js](#reactjs)
      - [Express.js](#expressjs)
      - [Nginx](#nginx)
  - [Docker](#docker)
    - [Docker volumes](#docker-volumes)
    - [Eigene images](#eigene-images)
    - [Docker Networks](#docker-networks)
      - [Eigene Netzwerke](#eigene-netzwerke)
      - [Container Services veröffentlichen](#container-services-veröffentlichen)
  - [Networking](#networking)
    - [DNS](#dns)
    - [DHCP](#dhcp)

## Installation & Einrichtung Linux VM

Als erstes habe ich mir VirtualBox heruntergeladen und gemäss Anleitung ["Installation Linux Distro"](https://eight-chair-fec.notion.site/Installation-Linux-Distro-f9224eadcb124b35a61eebbbeeb98210) eine neue Virtuelle Maschine erstellt. Dann habe ich die Ubuntu Iso heruntergeladen und installiert.

## SSH

Bei der Linux Installation wurde bereits OpenSSH mitinstalliert auf der VM, wird müssen also nichts mehr installieren.
Auf dem Host habe ich als erstes Port Forwarding in VirtualBox eingerichtet:
![port-forwarding](images/PortForwarding.png)  
Dann habe ich mich via PowerShell auf dem Host mit der VM verbunden: `ssh joshua@127.0.0.1 -p 5679`

### SSH Key

Um mich in Zukunft ohne Passwort mit der VM Verbinden zu können habe ich ein SSH key eingerichtet. Dafür habe ich zuerst einen neuen ssh key in PowerShell mit dem Befehl `ssh-keygen` erstellt. Bei Windows wird dieser standardmässig in einem .ssh Ordner im user Profil abgelegt, bei mir also unter `"C:\Users\Joshua\.ssh\id_rsa.pub"`

Da die Windows Implementation von OpenSSH leider den Command `ssh-copy-id` nicht unterstützt, habe ich das File mit scp manuell auf die VM kopiert: `scp -P 5679 $env:USERPROFILE\.ssh\id_rsa.pub joshua@127.0.0.1:/home/joshua/windows10_rsa.pub` wichtig ist die Port Option hier mit grossem P zu verwenden, da -p der scp parameter für die preserves Option verwendet wird.

Als nächstes habe ich dann auf der Linux VM das Verzeichnis .ssh und die Datei authorized_keys erstellt:
`mkdir -p ~/.ssh` & `touch ~/.ssh/authorized_keys`
Nun kopiere ich den Inhalt meines public keys in das authorized_keys file: `cat ~/windows10_rsa.pub >> ~/.ssh/authorized_keys`
Nun kann ich mich verbinden ohne mein User Passwor einzugeben:
![ssh-key-access](images/login-with-ssh-key.png)

Da ich aus Sicherheitsgründen meinem private Key eine Passphrase gegeben habe muss ich diese eingeben, hätte ich aber ein key ohne Passphrase generiert könnte ich ohne jegliche Eingabe von Passwort eine ssh Verbindung auf die VM herstellen.

### SSH Key only Authentication

Um die VM sicherer zu machen, kann man das Login via User Passwort ausschalten, so kann nur noch mit dem ssh-key zugegriffen werden, also auch nur von Servern/PC's welche einen korrekten private key haben zudem der public key auf der vm ist. Das ganze habe ich gemacht indem ich in der sshd_config Datei die Password Authentication disabled habe:
![disable-ssh-password](images/disable-ssh-password.png)

Nun muss die Konfiguration noch neu geladen werden mit: `sudo systemctl reload ssh`

Wenn ich nun versuche mich auf die VM zu verbinden und den private key nicht habe, erhalte ich Permission denied und es wird nicht nach dem Passwort gefragt, da dies disabeld ist.

![failed-pwd-login](images/failed-pwd-login.png)

## Filesystem und LEMP

### Disks auf unserer Ubuntu VM

Ich habe mir mit `sudo fdisk -l` alle Disks anzeigen lassen. Insgesamt sind es 7 Disks, 6 "dev/loop" disks mit jeweils 40-75Mib bytes und die Virtuelle Harddisk die beim erstellen der VM angelegt wurde mit 50GiB Speicher.

Mit `sudo fsdisk -l | grep -i Disk` erhält nur die Informationen der ersten Zeile und die Liste wird übersichtlicher.

```Disk /dev/loop0: 61.91 MiB, 64897024 bytes, 126752 sectors
Disk /dev/loop1: 67.94 MiB, 71221248 bytes, 139104 sectors
Disk /dev/loop2: 55.45 MiB, 58130432 bytes, 113536 sectors
Disk /dev/loop3: 43.6 MiB, 45703168 bytes, 89264 sectors
Disk /dev/loop4: 55.52 MiB, 58204160 bytes, 113680 sectors
Disk /dev/loop5: 70.32 MiB, 73728000 bytes, 144000 sectors
Disk /dev/sda: 50 GiB, 53687091200 bytes, 104857600 sectors
```

Um die Partitionen zu sehen habe ich den Befehl `lsblk` verwendet. Insgesamt sind hat unsere VM 12 Partitionen, 6 für die loop Disk und 5 für unsere Harddisk und eine für die rom.

```
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop0                       7:0    0 61.9M  1 loop /snap/core20/1361
loop1                       7:1    0 67.9M  1 loop /snap/lxd/22526
loop2                       7:2    0 55.4M  1 loop /snap/core18/2128
loop3                       7:3    0 43.6M  1 loop /snap/snapd/14978
loop4                       7:4    0 55.5M  1 loop /snap/core18/2284
loop5                       7:5    0 70.3M  1 loop /snap/lxd/21029
sda                         8:0    0   50G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.5G  0 part /boot
└─sda3                      8:3    0 48.5G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0 24.3G  0 lvm  /
sr0                        11:0    1 1024M  0 rom
```

Die UUID's der Partionen habe ich mir mit `sudo blkid | grep UUID=` anzeigen lassen:

```/dev/sda2: UUID="8e68e83d-1274-4aaa-902a-90a1de3162cb" TYPE="ext4" PARTUUID="55ae0ae9-10d7-4eba-86d3-6017260876f0"
/dev/sda3: UUID="Ho1hA2-lloz-36t7-akHa-JEvn-4q1L-Xtop5i" TYPE="LVM2_member" PARTUUID="5458d8b3-d493-41cf-b4ff-27ed2f948707"
/dev/mapper/ubuntu--vg-ubuntu--lv: UUID="a2ba3be5-ea02-484f-b866-f66ee8bdf182" TYPE="ext4"
/dev/sda1: PARTUUID="71f35074-8aab-4b1c-be61-4abbae9c8f63"
```

Um die Filesystemtypen zu sehen kann `lsblk -f` verwendet werden.

```
NAME                   FSTYPE      LABEL UUID                                   FSAVAIL FSUSE% MOUNTPOINT
loop0                  squashfs                                                       0   100% /snap/core20/1361
loop1                  squashfs                                                       0   100% /snap/lxd/22526
loop2                  squashfs                                                       0   100% /snap/core18/2128
loop3                  squashfs                                                       0   100% /snap/snapd/14978
loop4                  squashfs                                                       0   100% /snap/core18/2284
loop5                  squashfs                                                       0   100% /snap/lxd/21029
sda
├─sda1
├─sda2                 ext4              8e68e83d-1274-4aaa-902a-90a1de3162cb      1.3G     7% /boot
└─sda3                 LVM2_member       Ho1hA2-lloz-36t7-akHa-JEvn-4q1L-Xtop5i
  └─ubuntu--vg-ubuntu--lv
                       ext4              a2ba3be5-ea02-484f-b866-f66ee8bdf182     15.7G    29% /
sr0
```

### Disk hinzufügen

Als erstes muss in der Virtualbox eine neue virtuelle Hardisk erstellt und attached werden:
![virtualbox-add-disk](images/add-virtualbox-disk.png)

Danach muss die neue Disk gemäss Anleitung gemounted werden:

```
sudo fdisk /dev/sdb
n new
p primary
1 partition number
enter (keep default)
enter (keep default)
t type
8e hex code
w write
```

Nun sollte:

```
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

erscheinen, dann wurde die Disk erfolgreich erstellt.
Nun muss mit `sudo pvcreate /dev/sdb1` ein physisches Volumen erstellt werden. Als nächstes wird mit `sudo vgcreate vg_hftm /dev/sdb1` eine Volume Group erstellt und das pv dieser hinzugefügt. Als nächstes kann mit `sudo lvcreate -l 100%FREE -n lv_hftm vg_hftm` nun das logical volume erstellt werden `-l` steht für extends und `-n` für den Namen. Nun muss noch der Filesystemtyp auf ext4 festgelegt werden: `sudo mkfs.ext4 /dev/vg_hftm/lv_hftm` Nun muss der Ordner erstellt werden in dem die neue Disk gemounted werden soll: `sudo mkdir /var/www`.

Nun muss im file fstab via `sudo nano /etc/fstab` folgende Zeile für den permanenten mount hinzugefügt werden: `/dev/disk/by-uuid/318b48d6-ea00-44d5-bd16-49aa5ca3cc4f /var/www ext4 defaults 0 0`
Nun müssen die mounts refreshed werden: `sudo umount -a` und `sudo mount -a`

Wurde alles korrekt gemacht kann mit `sudo mount -l` geprüft werden ob die neue Disk gemounted wurde: `/dev/mapper/vg_hftm-lv_hftm on /var/www type ext4 (rw,relatime)`

## Webserver
Es gibt verschiedene Webserver welche alle den Zweck erfüllen Webseiten auf einem server zu hosten und via Browser verfügbar zu machen. Die wohl bekanntesten sind Apache Webserver und Nginx. Ich hatte mit beiden schon Kontakt, in der Ausbildung mussten wir damals eine Webseite mit LAMP hosten und bei der Arbeit verwenden wir aktuell Nginx um unser React Frontend zu hosten. Es gibt sogenannte Web Stacks, also Kombinationen aus Softwaretools um eine Webseite oder Webapplikation zu hosten. Die bekanntesten wären wohl LAMP, LEMP, MEAN, XAMPP und WAMP. Eine gute Übersicht über die verschiedenen Stacks und deren Komponenten habe ich hier gefunden: https://geekflare.com/lamp-lemp-mean-xampp-stack-intro/ 

### MERN
Ich persönlich habe mich dazu entschieden einen MERN Stack + Nginx auf meiner VM aufzusetzen. Das bedeutet:  
**M**ongoDB als Datenbank  
**E**xpress.js als Backend Server Framework
**R**eact.js als Frontend  
**N**ode.js als Javascript runtime/server  
Ich habe mich für MERN entschieden, weil es einerseits ein sehr moderner Stack ist und andererseits alle Komponenten in der selben Programmiersprache, nämlich JavaScript geschrieben werden, womit ich mich gut auskenne. Auch react.js und MongoDB kenne ich bereits. Aber ich habe noch nie selbst eine Webserver Umgebung mit Node/Express aufgesetzt. Und auch nginx habe ich bereits verwendet aber noch nie selbst installiert/konfiguriert. Deshalb möchte ich dies hier einmal durchführen und üben. Ich habe dazu folgende Anleitung verwendet: https://www.cloudbooklet.com/how-to-install-and-setup-mern-stack-with-nginx-on-ubuntu-20-04/  

#### MongoDB
Als erstes habe ich MongoDB installiert, dafür zuerst `sudo apt install gnupg` gnupg installiert damit ich den GPG key importieren kann und danach mit ` wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -` den Key importiert. Danach das MongoDB repository hinzugefügt: `echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list` und als letztes noch MongoDB installiert: `sudo apt update` & `sudo apt-get install mongodb-org=4.4.8 mongodb-org-server=4.4.8 mongodb-org-shell=4.4.8 mongodb-org-mongos=4.4.8 mongodb-org-tools=4.4.8`   
*Ich habe hier explizit die Version 4.4 verwendet, da ich die aktuellste Version 5 nicht zum laufen gebracht habe und auf [Stackoverflow](https://stackoverflow.com/questions/68742794/mongodb-failed-result-core-dump) zu meinem Fehler stand, dass diese Probleme mit virtuellen Maschinen hat.*  
Nun müssen wir dafür sorgen das der MongoDB Dienst beim Systemstart immer gestartet wird: `sudo systemctl enable mongod` und ihn initial auch gleich starten `sudo service mongod start` und mit `sudo service mongod status` prüfen ober auch läuft. Erhalten wir den Status "active (running)" ist alles in Ordnung.

Nun wollen wir MongoDB noch so konfigurieren, dass wir uns anmelden müssen und nicht jeder einfach die DB nutzen kann. Dazu müssen wir das config file editieren `sudo nano /etc/mongod.conf` und folgende Konfiguration hinzufügen: 
```
security:
  authorization: enabled
```
Auch wichtig zu prüfen ist ob die Firewall aktiviert ist mit `sudo ufw status`, falls ja entweder deaktivieren oder den MongoDB Port 27017 als Ausnahme hinzufügen. In meinem Fall ist ufw bereits deaktiviert. Danach den Mongo Service Neustarten `sudo systemctl restart mongod`
Nun wollen wir noch in der mongo shell einen Admin user für uns anlegen. Dazu gehen wir in die mongo shell `mongosh` und wechseln in die Admin DB `use admin` ind legen uns einen neuen User an: 
```
db.createUser({user: "admin" , pwd: passwordPrompt() , roles: [{ role: "userAdminAnyDatabase" , db: "admin"}]})
```
Nun können wir mit `mongo -u admin -p --authenticationDatabase admin` uns einloggen und haben weiterhin alle Rechte. Aber ohne User kann nun nicht mehr auf die DB zugegriffen werden.

#### Node.js
node.js könnte über den standard packet manager installiert werden, dort ist aber nur die veraltete Version 10.19.0 verfügbar. Deshalb installiere ich node mit dem NVM (Node Version Manager). Dazu muss dieser installiert werden `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash` und danach das nvm command geladen werden `source ~/.bashrc` nun können wir mit `nvm install v16.14.2` die aktuellste LTS Version installieren. Damit wird auch gleich der package manager NPM installiert.


#### React.js
Wir können ganz einfach ein neues react Projekt erstellen mithilfe von npx und des globalen create-react-app scripts: `npx create-react-app demo` ich habe meins demo genannt. Wir müssen nun das Projekt noch builden, dafür gehen wir in den Projektordner und führen `npm run build` aus. Dies erstellt unsere statische Website für unser frontend. Diese Webseite werden wir später mit nginx verfügbar machen.

#### Express.js
Auch für express können wir mit npx ein Projekt erstellen ` npx express-generator backend`. Ich habe meins backend genannt. Danach gehen wir wieder in den Ordner und laden die dependencies herunter `npm install -y`. Damit unser express server immer im Hintergrund läuft verwenden wir den Node Process Manager PM2. Diesen installieren wir mit npm `npm install pm2 -g` danach starten wir unseren server mit PM2 `pm2 start npm --name "backend" -- start`. Nun wollen wir noch das unser Server beim Startup gestartet wird, dafür nutzen wir `pm2 startup` welches uns einen Befehl ausgibt den wir ausführen können um das startup einzurichten und mit `pm2 save` speichern wir die Konfiguration anschliessend. Nun läuft unser Express server.

#### Nginx
Als letztes installieren wir noch nginx `sudo apt install nginx`. Da wir die Firewall bereits geprüft/deaktiviert haben sollten wir hier keine Probleme haben.

Ich habe die default config gelöscht und mir eine eigene erstellt `sudo nano /etc/nginx/sites-available/application.conf`
```
server {
     listen [::]:8085;
     listen 8085;

     root /home/joshua/demo/build/;
     index index.html;

     location / {
         try_files $uri $uri/ =404;
     }

     location /api/ {
         proxy_pass http://127.0.0.1:3000/;
         proxy_http_version 1.1;
         proxy_set_header Connection '';
         proxy_set_header Host $host;
         proxy_set_header X-Forwarded-Proto $scheme;
         proxy_set_header X-Real-IP $remote_addr;
         proxy_set_header X-Forwarded-For $remote_addr;
    }
}
```
Mit dieser Config ist meine Demo React App via locahost:8085 verfügbar und der Express server via localhost:8085/api. 
Bevor alles funktioniert musst aber noch ein symbolic link erstellt werden `sudo ln -s /etc/nginx/sites-available/application.conf /etc/nginx/sites-enabled/application.conf` und der nginx neugestartet werden `sudo service nginx restart`.
Danach richten wir noch ein port-forwarding auf unsere VirtualBox ein:  
!["port-forwarding-nginx"](images/port-forwarding-nginx.png)
Nun sollten wir von unserem Host sowohl die react app als auch Express ansteuern können:  
!["react-app](images/react-app.png) !["express-server"](images/express-server.png)

## Docker

Ich habe Docker Desktop auf meinem Windows PC heruntergeladen und installiert.
Danach habe ich via Terminal gemäss Anleitung einen Container für das easyrest Image erstellt:

Um einen zweiten Container mit demselben Image zu erstellen und auf Port 8090 verfügbar zu machen, habe ich folgenden Befehl verwendet:  
`docker run --name easyrest2 -p 8090:8080 -d hftmittelland/easyrest`  
Mit `docker exec -i -t easyrest2 bash` und dann `cat /config/config.xml` kann ich sehen das auf dem zweiten Container die andere Config die ich via Post request erstellt habe ist:


```
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<machineInfo>
    <name>My other machine</name>
    <version>1.3</version>
    <speed>500.0</speed>
    <temperature>33.5</temperature>
</machineInfo>
```

### Docker volumes

Mithilfe `docker run --name easyrest -p 8080:8080 --volume D:\Work\VM\Docker\config.xml:/config/config.xml -d hftmittelland/easyrest` habe ich den easyrest container neu erstellt und ihn mit einem persistenten Volume ergänzt, damit die Daten nicht mehr verloren gehen beim Erstellen eines neuen Containers.

### Eigene images

Um das easyrest image mit dem editor nano zu ergänzen, habe ich ein neues Dockerfile mit folgendem Inhalt erstellt:

```
FROM hftmittelland/easyrest
RUN echo "deb http://legacy.raspbian.org/raspbian/ wheezy main contrib non-free rpi" > /etc/apt/sources.list
RUN apt-get update && apt-get install -y nano && rm -fr /var/lib/apt/lists/*
```

Mit `docker build -t custom-images/easyrest_nano .` habe ich das image dann erstellt und mit `docker run --name easyrest -p 8080:8080 -d custom-images/easyrest_nano` einen Container gestartet.

### Docker Networks

Es gibt verschiedene Netzwerkdriver für Docker welche standardmässig vorhanden sind:

- Bridge
- Host
- overlay
- ipvlan
- macvlan
- none

Mit `docker network ls` kann man die vorhandenen Netzwerke sehen. Mit `docker network inspect bridge` erhält man detailliertere Informationen zu einem bestimmten Netzwerk (in diesem Fall dem bridge Netzwerk)

#### Eigene Netzwerke

Mit dem Befehl `docker network create [name]` kann man eigene Netzwerke erstellen. Per default wird ein bridge Netzwerk mit Standard-Konfigurationen erstellt. Man kann aber mittels Parameter alle gängigen Netzwerkoptionen konfigurieren. Beispielsweise subnet und gateway: `docker network create backend --subnet=192.168.10.0/24 --gateway=192.168.10.1` Das gateway wird dann als IP-Adresse im host genutzt, wir können also den Container von aussen über den Host mit der IP `192.168.10.1` erreichen.

Um nun einen neuen Container zu erstellen welcher das eigene Netzwerk verwendet, wird der `--network` Parameter verwendet, beispielsweise so: `docker run --network=frontend --name nginx1 -d bitnami/nginx:latest`

Ein Vorteil von eigenen Netzwerken ist, dass man diese bei laufendem Container ändern kann, ohne diese stoppen zu müssen. Zuerst wird das neue Netzwerk connected `docker network connect backend nginx1` und dann das alte getrennt `docker network disconnect frontend nginx1`

Falls eigene Netzwerke nicht mehr benutzt werden, kann man mit `docker network prune` alle nicht verwendeten Netzwerke automatisch löschen lassen.

Falls wir einen Container ohne Netzwerkverbindung starten möchten, können wir denselben Netzwerkparameter nur dieses Mal mit dem Argument none verwenden `docker run --network=none --name nginx-no-network -d bitnami/nginx:latest`
Bei laufenden Containern kann einfach das aktive Netzwerk mit dem disconnect befehl getrennt werden `docker network disconnect backend nginx1`.
Dies kann hilfreich sein um Container welche Malware oder Sicherheitslücken haben vom Netzwerk zu isolieren.

#### Container Services veröffentlichen

Damit wir von aussen/via Host auf services welche auf unseren Container laufen zugreifen können müssen wir diese veröffentlichen. Am einfachsten geht dies mit dem host Netzwerktyp. Dieser veröffentlicht automatisch alle Ports des Containers auch auf dem Host, ohne diese manuell zu spezifizieren/freizugeben. Dies ist die einfachste Option, sollte aber nur verwendet werden, wenn nur sehr wenige Container auf dem Host verwendet werden. Da man schnell die Übersicht verliert und auch Sicherheitstechnisch keine Kontrolle hat welche Ports/Services nach aussen freigegeben sind. Auch kann ein Port dann nur einmal verwendet werden da es sonst Portkonflikte geben würde. Ein solcher Container kann via `sudo docker run --network=host --name nginx -d bitnami/nginx:latest` erstellt werden.

Der bessere Weg welcher mehr Kontrolle bietet ist das spezifische veröffentlichen von Ports bei einem bridge network. So hat man die volle Kontrolle und eine gute Übersicht welche Ports man genau öffentlich zugänglich macht und welche nicht. Ausserdem kann man auch Ports mappen, also auf dem Host System einen anderen Port verwenden als der Container verwendet, um Port Konflikte zu vermeiden.
`docker run -p 8080:8080 -p 8443:8443 --name nginx -d bitnami/nginx:latest` Hier werden die Ports 8080 und 8443 vom Container auf dem Host auf dem gleichen Port veröffentlicht. Es wäre aber auch möglich ein anderes Mapping für den Host zu verwenden, um beispielsweise einen zweiten Container zu starten welcher intern dieselben Ports verwendet

## Networking

### DNS

Der DNS (Domain Name System) Server löst den Namen einer Webseite auf die richtige IP auf. Damit wir nicht uns nicht die IP-Adresse von allen Webseiten merken müssen und einfach die direkte URL/Adresse verwenden können.

Der DNS hat eine Hierarchy, da ein DNS-Server nicht alle IP's kennen kann. Wenn eine Adresse nicht bekannt ist, leitet der DNS die Anfrage weiter, dieser Prozess wiederholt sich so lange bis wir die korrekte IP zurückerhalten.

### DHCP

DHCP erlaubt es dynamische IP's zu vergeben. Dieser vergibt/leased an clients IP-Adressen und speichert diese in einer IP-Adressen Datenbank. Das lease hat immer eine ttl = time to live. Läuft diese ab ist die IP ungültig und es muss eine neue vergeben werden oder das bestehende lease verlängern.
