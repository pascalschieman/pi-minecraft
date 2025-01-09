#!/bin/bash

sudo apt install wget -y
wget -O zulu-jdk.deb 'https://cdn.azul.com/zulu/bin/zulu23.30.13-ca-jdk23.0.1-linux_arm64.deb?_gl=1*9354sk*_gcl_au*MTQxMTg2Mzg5Mi4xNzM2Mjc3Nzg0*_ga*NjM5NTk4NDU5LjE3MzYyNzc3ODQ.*_ga_42DEGWGYD5*MTczNjI3Nzc4NC4xLjEuMTczNjI3ODEyMC41OS4wLjA.'
sudo dpkg -i zulu-jdk.deb
sudo apt --fix-broken install -y  # Fehler beheben und fehlende Abhängigkeiten installieren
rm zulu-jdk.deb  # .deb-Datei löschen, um Platz zu sparen

mkdir papermcserver
cd papermcserver
wget https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/77/downloads/paper-1.21.4-77.jar
mv paper-1.21.4-77.jar papermcserver.jar
mkdir plugins
cd plugins
wget -O Geyser-Spigot.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
wget -O floodgate-spigot.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
cd ..

#first server initialization
java -Xms2G -Xmx4G -jar papermcserver.jar nogui
sleep 10
echo "eula=true" > eula.txt

# 6. Start the server to load plugins
echo "Starting the server again to load plugins..."
java -Xms2G -Xmx4G -jar papermcserver.jar nogui &
PLUGIN_SERVER_PID=$!
sleep 120  # Wait 120 seconds to ensure all plugins are loaded
kill "$PLUGIN_SERVER_PID"

cd plugins/Geyser-Spigot
sed -i 's/auth-type: .*/auth-type: floodgate/' config.yml
java -Xms2G -Xmx4G -jar papermcserver.jar nogui