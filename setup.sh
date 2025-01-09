#!/bin/bash

# Install wget and download Zulu OpenJDK 23
sudo apt install wget -y
wget -O zulu-jdk.deb 'https://cdn.azul.com/zulu/bin/zulu23.30.13-ca-jdk23.0.1-linux_arm64.deb?_gl=1*9354sk*_gcl_au*MTQxMTg2Mzg5Mi4xNzM2Mjc3Nzg0*_ga*NjM5NTk4NDU5LjE3MzYyNzc3ODQ.*_ga_42DEGWGYD5*MTczNjI3Nzc4NC4xLjEuMTczNjI3ODEyMC41OS4wLjA.'
sudo dpkg -i zulu-jdk.deb
sudo apt --fix-broken install -y
rm zulu-jdk.deb  # Remove .deb to save space
sudo apt install git build-essential -y  # Install build tools
git clone https://github.com/Tiiffi/mcrcon.git
cd mcrcon
make
sudo make install
cd ..

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
echo -e "\e[32mStarting the server for initialization...\e[0m"
java -Xms1G -Xmx2G -jar papermcserver.jar nogui &
SERVER_PID=$!

# Wait until `eula.txt` is created
echo -e "\e[32mWaiting for eula.txt to be generated...\e[0m"
while [ ! -f "eula.txt" ]; do
  sleep 1
done

# Stop the server gracefully after `eula.txt` is created
echo -e "\e[32mStopping the server gracefully after eula.txt was created...\e[0m"
kill -SIGTERM "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null  # Wait for the process to exit completely
echo -e "\e[32mServer stopped.\e[0m"

# Accept EULA
echo -e "\e[32mAccepting EULA...\e[0m"
echo "eula=true" > eula.txt

# Enable RCON in server.properties
echo -e "\e[32mEnabling RCON for stopping the server...\e[0m"
echo "enable-rcon=true" >> server.properties
echo "rcon.port=25575" >> server.properties
echo "rcon.password=myStrongPassword123!" >> server.properties

# Start the server to load plugins
echo -e "\e[32mStarting the server to load plugins...\e[0m"
java -Xms1G -Xmx2G -jar papermcserver.jar nogui &
PLUGIN_SERVER_PID=$!

# Wait for `config.yml` to be created
echo -e "\e[32mWaiting for GeyserMC config.yml to be generated...\e[0m"
while [ ! -f "plugins/Geyser-Spigot/config.yml" ]; do
  sleep 1
done

# Send `/stop` to the server via RCON to stop it gracefully
echo -e "\e[32mStopping the server gracefully after plugins are initialized...\e[0m"
mcrcon -H 127.0.0.1 -P 25575 -p myStrongPassword123! "stop"
sleep 5  # Give the server time to shut down

# Modify GeyserMC auth-type to floodgate
echo -e "\e[32mModifying GeyserMC config.yml...\e[0m"
sed -i 's/auth-type: .*/auth-type: floodgate/' plugins/Geyser-Spigot/config.yml

# Final server start
echo -e "\e[32mStarting the server with final configuration...\e[0m"
java -Xms1G -Xmx2G -jar papermcserver.jar nogui
