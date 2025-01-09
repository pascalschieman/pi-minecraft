#!/bin/bash

# Install wget and download Zulu OpenJDK 23
sudo apt install wget -y
wget -O zulu-jdk.deb 'https://cdn.azul.com/zulu/bin/zulu23.30.13-ca-jdk23.0.1-linux_arm64.deb?_gl=1*9354sk*_gcl_au*MTQxMTg2Mzg5Mi4xNzM2Mjc3Nzg0*_ga*NjM5NTk4NDU5LjE3MzYyNzc3ODQ.*_ga_42DEGWGYD5*MTczNjI3Nzc4NC4xLjEuMTczNjI3ODEyMC41OS4wLjA.'
sudo dpkg -i zulu-jdk.deb
sudo apt --fix-broken install -y  # Fix broken dependencies
rm zulu-jdk.deb  # Remove .deb to save space

# Create server directory and download PaperMC
mkdir papermcserver
cd papermcserver
wget https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/77/downloads/paper-1.21.4-77.jar
mv paper-1.21.4-77.jar papermcserver.jar

# Create plugins directory and download GeyserMC and Floodgate
mkdir plugins
cd plugins
wget -O Geyser-Spigot.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
wget -O floodgate-spigot.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
cd ..

# First server initialization (run in the background)
echo "Starting the server for initialization..."
java -Xms2G -Xmx3G -jar papermcserver.jar nogui &

# Wait for `eula.txt` to be generated
echo "Waiting for eula.txt to be generated..."
while [ ! -f "eula.txt" ]; do
  sleep 1  # Check every second until the file exists
done

# Stop the server once `eula.txt` is generated
echo "Stopping the server after eula.txt was created..."
SERVER_PID=$(pgrep -f papermcserver.jar)
kill "$SERVER_PID"

# Accept EULA
echo "Accepting EULA..."
echo "eula=true" > eula.txt

# Start the server to load plugins
echo "Starting the server again to load plugins..."
java -Xms2G -Xmx3G -jar papermcserver.jar nogui &
PLUGIN_SERVER_PID=$!
sleep 120  # Wait 120 seconds for plugins to load
kill "$PLUGIN_SERVER_PID"

# Modify GeyserMC auth-type to floodgate
echo "Modifying GeyserMC config.yml..."
if [ -f "plugins/Geyser-Spigot/config.yml" ]; then
  sed -i 's/auth-type: .*/auth-type: floodgate/' plugins/Geyser-Spigot/config.yml
else
  echo "Error: GeyserMC config.yml not found!"
  exit 1
fi

# Final server start
echo "Starting the server with final configuration..."
java -Xms2G -Xmx3G -jar papermcserver.jar nogui
