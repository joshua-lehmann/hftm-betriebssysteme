# Workbook Betriessysteme hftm

- [Workbook Betriessysteme hftm](#workbook-betriessysteme-hftm)
  - [Installation & Einrichtung Linux VM](#installation--einrichtung-linux-vm)
  - [SSH](#ssh)
    - [SSH Key](#ssh-key)
  - [Docker](#docker)
    - [Docker volumes](#docker-volumes)
    - [Eigene images](#eigene-images)

## Installation & Einrichtung Linux VM
Als erstes habe ich mir Virtualbox heruntergeladen und gemäss Anleitung "Installation Linux Distro" eine neue Virtuelle maschiene erstellt. Dann habe ich die Ubuntu Iso heruntergeladen und installiert.

## SSH

Als erstes habe ich das PortForwarding in Virtualbox eingerichtet: 
![port-forwarding](images/PortForwarding.png)  
Dann habe ich mich via Powershell auf dem Host mit der VM verbunden: `ssh joshua@127.0.0.1 -p 5679`

### SSH Key
Um mich in Zukunft ohne Passwort mit der VM Verbinden zu können habe ich ein SSH key eingerichtet. Dafür habe ich zuerst einen neuen ssh key in PowersShell mit dem Befehle `ssh-keygen` erstellt.


## Docker
Ich habe Docker Desktop auf meinem Windows PC heruntergeladen und installiert.
Danach habe ich via Terminal gemäss Anleitung einen Container für das easyrest imagage erstellt:


Um einen zweiten Container mit demselben Image zu erstellen und auf Port 8090 verügbar zu machen, habe ich folgenden Befehl verwendet:  
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
Mithilfe `docker run --name easyrest -p 8080:8080 --volume D:\Work\VM\Docker\config.xml:/config/config.xml -d hftmittelland/easyrest` habe ich den easyrest container neu erstellt und ihn mit einem persitenten Volume ergänzt, damit die Daten nicht mehr verloren gehen beim erstellen eines neuen Containers.

### Eigene images
Um das easyrest image mit dem editor nano zu ergänzen, habe ich ein neues Dockerfile mit folgendem inhalt erstellt:
``` 
FROM hftmittelland/easyrest
RUN echo "deb http://legacy.raspbian.org/raspbian/ wheezy main contrib non-free rpi" > /etc/apt/sources.list
RUN  apt-get update && apt-get install -y nano && rm -fr /var/lib/apt/lists/*
```
Mit `docker build -t custom-images/easyrest_nano .` habe ich das image dann erstellt und mit `docker run --name easyrest -p 8080:8080 -d custom-images/easyrest_nano` einen Container gestartet.