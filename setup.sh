#!/bin/bash

# Install wget and download Zulu OpenJDK 23
sudo apt install wget -y
wget -O zulu-jdk.deb 'https://cdn.azul.com/zulu/bin/zulu23.30.13-ca-jdk23.0.1-linux_arm64.deb?_gl=1*9354sk*_gcl_au*MTQxMTg2Mzg5Mi4xNzM2Mjc3Nzg0*_ga*NjM5NTk4NDU5LjE3MzYyNzc3ODQ.*_ga_42DEGWGYD5*MTczNjI3Nzc4NC4xLjEuMTczNjI3ODEyMC41OS4wLjA.'
sudo dpkg -i zulu-jdk.deb
sudo apt --fix-broken install -y
rm zulu-jdk.deb

# Create server directory and download PaperMC
mkdir -p papermcserver
cd papermcserver
wget -O papermcserver.jar https://api.papermc.io/v2/projects/paper/versions/1.21.4/builds/77/downloads/paper-1.21.4-77.jar

# Create plugins directory and download GeyserMC and Floodgate
mkdir -p plugins
cd plugins
wget -O Geyser-Spigot.jar https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot
wget -O floodgate-spigot.jar https://download.geysermc.org/v2/projects/floodgate/versions/latest/builds/latest/downloads/spigot
cd ..

# First server initialization
echo "Starting the server for initialization..."
java -Xms1G -Xmx2G -jar papermcserver.jar nogui &
SERVER_PID=$!

# Wait until `eula.txt` is created
echo "Waiting for eula.txt to be generated..."
while [ ! -f "eula.txt" ]; do
  sleep 1
done

# Stop the server gracefully after `eula.txt` is created
echo "Stopping the server gracefully after `eula.txt` was created..."
kill -SIGTERM "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null  # Wait for the process to exit completely
echo "Server stopped."

# Accept EULA
echo "Accepting EULA..."
echo "eula=true" > eula.txt

# Start the server to load plugins
echo "Starting the server to load plugins..."
java -Xms1G -Xmx2G -jar papermcserver.jar nogui &
PLUGIN_SERVER_PID=$!

# Wait for `config.yml` to be created
echo "Waiting for GeyserMC config.yml to be generated..."
while [ ! -f "plugins/Geyser-Spigot/config.yml" ]; do
  sleep 1
done

# Stop the server gracefully after plugins are initialized
echo "Stopping the server gracefully after plugins are initialized..."
kill -SIGTERM "$PLUGIN_SERVER_PID"
wait "$PLUGIN_SERVER_PID" 2>/dev/null  # Wait for the process to exit completely
echo "Server stopped."

# Modify GeyserMC auth-type to floodgate
echo "Modifying GeyserMC config.yml..."
sed -i 's/auth-type: .*/auth-type: floodgate/' plugins/Geyser-Spigot/config.yml

# Final server start
echo "Starting the server with final configuration..."
java -Xms1G -Xmx2G -jar papermcserver.jar nogui
