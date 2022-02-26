# Workbook Betriebssysteme hftm

- [Workbook Betriebssysteme hftm](#workbook-betriebssysteme-hftm)
  - [Installation & Einrichtung Linux VM](#installation--einrichtung-linux-vm)
  - [SSH](#ssh)
    - [SSH Key](#ssh-key)
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

Da die Windows Implementation von OpenSSH leider den Command `ssh-copy-id` nicht unterstüzt, habe ich das File mit scp manuell auf die VM kopiert: `scp -P 5679 $env:USERPROFILE\.ssh\id_rsa.pub joshua@127.0.0.1:/home/joshua/windows10_rsa.pub` wichtig ist die Port Option hier mit grossem P zu verwenden, da -p der scp parameter für die preserves Option verwendet wird.

Als nächstes habe ich dann auf der Linux VM das Verzeichnis .ssh und die Datei authorized_keys erstellt:
`mkdir -p ~/.ssh` & `touch ~/.ssh/authorized_keys`
Nun kopiere ich den Inhalt meines public keys in das authorized_keys file: `cat ~/windows10_rsa.pub >> ~/.ssh/authorized_keys`
Nun kann ich mich verbinden ohne mein User Passwor einzugeben:
![ssh-key-access](images/login-with-ssh-key.png)

Da ich aus Sicherheitsgründen meinem private Key eine Passphrase gegeben habe muss ich diese eingeben, hätte ich aber ein key ohne Passphrase generiert könnte ich ohne jegliche Eingabe von Passwort eine ssh Verbindung auf die VM herstellen.

Um die VM sicherer zu machen, kann man das Login via User Passwort ausschalten, so kann nur noch mit dem ssh-key zugegriffen werden, also auch nur von Servern/PC's welche einen korrekten private key haben zudem der public key auf der vm ist. Das ganze habe ich gemacht indem ich in der sshd_config Datei die Password Authentication disabeld habe:
![disable-ssh-password](images/disable-ssh-password.png)

Nun muss die Konfiguration noch neu geladen werden mit: `sudo systemctl reload ssh`

Wenn ich nun versuche mich auf die VM zu verbinden und den private key nicht habe, erhalte ich Permission denied und es wird nicht nach dem Passwort gefragt, da dies disabeld ist. 
![failed-pwd-login](images/failed-pwd-login.png)


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