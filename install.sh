# #!/bin/bash

USER_HOME=$(getent passwd $USER | cut -d: -f6)

export STYLES='
  window=,black
  border=white,black
  textbox=white,black
  button=black,white'

#  select installation

options=(\
 "Yes" "" \
 "No" "" \
)

declare -A os_info
while IFS='=' read -r key value; do
  os_info["$key"]="$value"
done < "/etc/os-release"

repos=(\
 "NEMP Server" ""  \
 "NEMP Web Admin" "" \
 "NEMP Web Client" "" \
 "WebSocket Developer Console" "" \
)
installation_repo=$(whiptail --title "Select software to install" --menu "Choose an option:" 15 110 4 "${repos[@]}" 3>&1 1>&2 2>&3)

# # SERVER:
if [ -z "$installation_repo" ]; then
 whiptail --msgbox "Nothing selected" 15 110
 exit 1
fi
case $installation_repo in
  "NEMP Server")
    SERVER_INSTALL_DIR=$(whiptail --title "NEMP Server installer" --inputbox "NEMP Server installation directory:" 10 60 "$USER_HOME/nemp-server" 3>&1 1>&2 2>&3)
    if [ -z "$SERVER_INSTALL_DIR" ]; then
      whiptail --msgbox "Invalid installation directory." 10 60
      exit 1
    fi
    if [ ! -d "$SERVER_INSTALL_DIR" ]; then
      echo "Directory does not exist, creating new: $SERVER_INSTALL_DIR"
      mkdir $SERVER_INSTALL_DIR
    fi
    cd $SERVER_INSTALL_DIR
    case "${os_info[ID]}" in
      "debian")
        {
          output_file=$(mktemp)
          curl -fsSL https://deb.nodesource.com/setup_19.x bash - 
          echo -e "XXX\n10\nPlease wait while installing node.js...\nXXX"
          sleep 4
          echo -e "XXX\n20\nNode.Js installed successfully.\nXXX"
          sleep 0.5
          echo -e "XXX\n20\nInstalling packages....\nXXX"
          apt -y install screen certbot whiptail nodejs curl > /tmp/apt_output.txt 2>&1 &
          PID=$!
          while kill -0 $PID >/dev/null 2>&1; do
              echo "XXX\n20\nInstalling packages: $(tail -n 1 /tmp/apt_output.txt)\nXXX"
              sleep 4
          done
          echo -e "XXX\n45\nPackages installed successfully\nXXX"
          rm /tmp/apt_output.txt
          sleep 0.5
          npm i -g npm
          echo -e "XXX\n45\nInstaling npm...\nXXX"
          sleep 5
          echo -e "XXX\n60\nNPM installed successfully.\nXXX"
          sleep 0.5
          git clone https://github.com/libersoft-org/nemp-server.git
          echo -e "XXX\n60\nCloning nemp-server.....\nXXX"
          sleep 4
          echo -e "XXX\n95\nNemp server cloned successfully.\nXXX"
          sleep 0.5
          cd nemp-server/src
          npm i -g
          echo -e "XXX\n95\nInstaling server npm packages...\nXXX"
          sleep 5
          echo -e "XXX\n100\nInstall complete.\nXXX"
          sleep 1
        } | whiptail --title "Server installation" --gauge "Running install...." 15 110 0
        echo "running server install on debian"
        ;;
      "centos")
        curl -fsSL https://deb.nodesource.com/setup_19.x | bash -
        whiptail --msgbox "Downloading nodejs" 15 110
        dnf -y install screen certbot whiptail nodejs curl # curl optional?
        whiptail --msgbox "Installing packagaes" 15 110
        npm i -g npm
        whiptail --msgbox "Installing npm" 15 110
        git clone https://github.com/libersoft-org/nemp-server.git
        cd nemp-server/src/
        npm i
        echo "centos"
        ;;
    esac
    init_settings=$(whiptail --title "Create settings" --menu "Would you like to create a new server settings file?:" 15 110 4 "${options[@]}" 3>&1 1>&2 2>&3)
    case $init_settings in
      "no")
        whiptail --msgbox "Installed server, exiting...." 15 110
        exit 1
        ;;
      "yes")
        node index.js --create-settings
        whiptail --msgbox "Creating settings...." 15 110
        init_https_certificate=$(whiptail --title "Create https certificate" --menu "Would you like to create a new https certificate?:" 15 110 4 "${options[@]}" 3>&1 1>&2 2>&3)
        case $init_https_certificate in
          "no")
            whiptail --msgbox "Installed server and added default settings, exiting...." 15 110
            exit 1
            ;;
          "yes")
            ./cert.sh
            whiptail --msgbox "Creating https certificate...." 15 110
            init_database=$(whiptail --title "Create admin" --menu "Would you like to create a new database?:" 15 110 4 "${options[@]}" 3>&1 1>&2 2>&3)
            case $init_database in
              "no")
                whiptail --msgbox "Installed server, added default settings and https certificate, exiting...." 15 110
                exit 1
                ;;
              "yes")
                node index.js --create-database
                whiptail --msgbox "Creating database...." 15 110
                init_admin=$(whiptail --title "Create admin" --menu "Would you like to create a new admin account?:" 15 110 4 "${options[@]}" 3>&1 1>&2 2>&3)
                case $init_admin in
                  "no")
                    whiptail --msgbox "Installed server, added default settings, https certificate and created new database, exiting...." 15 110
                    exit 1
                    ;;
                  "yes")
                    node index.js --create-admin
                    whiptail --msgbox "Installed server and all default information. Start the server: node index.js" 15 110
                    ;;
                esac
              ;;
            esac
            ;;
        esac
        ;;
    esac
    cd ../
    ;;
  "NEMP Web Admin")
    CLIENT_INSTALL_DIR=$(whiptail --title "NEMP Server installer" --inputbox "NEMP web installation directory:" 10 60 "$USER_HOME/data/www" 3>&1 1>&2 2>&3)
    if [ -z "$CLIENT_INSTALL_DIR" ]; then
      whiptail --msgbox "Invalid installation directory." 10 60
      exit 1
    fi
    if [ ! -d "$CLIENT_INSTALL_DIR" ]; then
      echo "Directory does not exist, creating new: $CLIENT_INSTALL_DIR"
      mkdir $CLIENT_INSTALL_DIR
    fi
    cd ../
    rm $CLIENT_INSTALL_DIR/admin -rf && mkdir $CLIENT_INSTALL_DIR/admin && cd $CLIENT_INSTALL_DIR
    whiptail --title "Downloading admin web" --gauge "Cloning repository" 6 60 0 < <(
      git clone --progress https://github.com/libersoft-org/nemp-admin-web.git 2>&1 | while read line; do
      percent=$(echo $line | grep -o "[0-9]\{1,3\}%" | tr -d '%')
      percent=${percent:-0}
      sleep 0.15
      done
    )
    cd nemp-admin-web
    mv ./src/* $CLIENT_INSTALL_DIR/admin/
    cd ../ && rm nemp-admin-web -rf
    whiptail --msgbox "Downloaded admin web successfully" 15 110
    ;;
  "NEMP Web Client")
    CLIENT_INSTALL_DIR=$(whiptail --title "NEMP Server installer" --inputbox "NEMP web installation directory:" 10 60 "$USER_HOME/data/www" 3>&1 1>&2 2>&3)
    if [ -z "$CLIENT_INSTALL_DIR" ]; then
      whiptail --msgbox "Invalid installation directory." 10 60
      exit 1
    fi
    cd ../
    rm $CLIENT_INSTALL_DIR -rf && mkdir $CLIENT_INSTALL_DIR/client && cd $CLIENT_INSTALL_DIR
    whiptail --title "Downloading client web" --gauge "Cloning repository" 6 60 0 < <(
      git clone --progress https://github.com/libersoft-org/nemp-client-web.git 2>&1 | while read line; do
      percent=$(echo $line | grep -o "[0-9]\{1,3\}%" | tr -d '%')
      percent=${percent:-0}
      sleep 0.15
      done
    )
    cd nemp-client-web
    mv ./src/* $CLIENT_INSTALL_DIR/client/
    cd ../ && rm nemp-client-web -rf
    whiptail --msgbox "Downloaded client web successfully" 15 110
    ;;
  "WebSocket Developer Console")
    CLIENT_INSTALL_DIR=$(whiptail --title "NEMP Server installer" --inputbox "NEMP web installation directory:" 10 60 "$USER_HOME/data/www" 3>&1 1>&2 2>&3)
    if [ -z "$CLIENT_INSTALL_DIR" ]; then
      whiptail --msgbox "Invalid installation directory." 10 60
      exit 1
    fi
    cd ../
    rm $CLIENT_INSTALL_DIR -rf && mkdir $CLIENT_INSTALL_DIR/console && cd $CLIENT_INSTALL_DIR
    whiptail --title "Downloading console web" --gauge "Cloning repository" 6 60 0 < <(
      git clone --progress https://github.com/libersoft-org/websocket-console.git 2>&1 | while read line; do
      percent=$(echo $line | grep -o "[0-9]\{1,3\}%" | tr -d '%')
      percent=${percent:-0}
      sleep 0.15
      done
    )
    cd nemp-console-web
    mv ./src/* $CLIENT_INSTALL_DIR/console/
    cd ../ && rm nemp-console-web -rf
    whiptail --msgbox "Downloaded console web successfully" 15 110
    ;;
  *)
    whiptail --msgbox "invalid choice" 15 110 #todo: add multiple selections later
    ;;
esac
# SERVER_INSTALL_DIR=$(whiptail --title "NEMP Server installer" --inputbox "NEMP Server installation directory:" 10 60 "$USER_HOME/nemp-server" 3>&1 1>&2 2>&3)
# if [ -z "$SERVER_INSTALL_DIR" ]; then
#  whiptail --msgbox "Invalid installation directory." 10 60
#  exit 1
# fi
# cd ../
# git clone https://github.com/libersoft-org/nemp-server.git
# git pull https://github.com/libersoft-org/nemp-server.git
# cp -r ./nemp-server/src/* $SERVER_INSTALL_DIR

# cd $SERVER_INSTALL_DIR
# npm install &
# PID=$!
# PERCENT=0

# function update_progress {
#  PERCENT=$(echo "scale=2; $PERCENT + 0.5" | bc)
#  echo $PERCENT
# }

# whiptail --title "Installing npm packages" --gauge "Please wait..." 6 50 0 < <(
#  while true; do
#   if [[ $(ps -p $PID | grep $PID) ]]; then
#    update_progress
#    echo "$PERCENT Installing packages... "
#   else
#    echo "100 Installation complete."
#    break
#   fi
#   sleep 0.1
#  done
# )

# #NEMP SERVER - DEBIAN:
# #apt -y install curl screen certbot whiptail
# #curl -fsSL https://deb.nodesource.com/setup_19.x | bash -
# #apt -y install nodejs
# #npm i -g npm
# #git clone https://github.com/libersoft-org/nemp-server.git
# #cd nemp-server/src/
# #npm i

# #NEMP SERVER - CENTOS:
# #dnf -y install curl screen certbot whiptail
# #curl -fsSL https://rpm.nodesource.com/setup_19.x | bash -
# #dnf -y install nodejs
# #npm i -g npm
# #git clone https://github.com/libersoft-org/nemp-server.git
# #cd nemp-server/src/
# #npm i

# ## NEMP SERVER CONFIGURATION

# #WHIPTAIL - Would you like to create a new server settings file?
# #node index.js --create-settings

# #WHIPTAIL - Would you like to create a new server database file?
# #node index.js --create-database

# #WHIPTAIL - Would you like to create a new server admin account?
# #node index.js --create-admin

# #WHIPTAIL - Would you like to create a new server HTTPS certificate?
# #./cert.sh

# #WHIPTAIL - Would you like to add HTTPS server certificate renewal to crontab?
# #crontab -e
# #... and add this line at the end:
# #0 12 * * * /usr/bin/certbot renew --quiet

# #WHIPTAIL - NEMP Server installation complete.
# #Now you can just start the server using:
# #./start.sh
# #If you need some additional configuration, just edit the **settings.json** file.

# #You can attach the server screen using:
# #screen -x nemp

# #To detach screen press **CTRL+A** and then **CTRL+D**.

# #Alternatively you can run server without using **screen** by:
# #node index.js

# #To stop the server just press **CTRL+C**.

# #Add this domain record in your DNS for your NEMP server:
# #- **A** record of your NEMP server, eg.: **A - nemp.domain.tld** targeting your NEMP server IP address

# #Now for each domain you'd like to use with your NEMP server add this record:
# #- **TXT** record that identifies your NEMP server, eg.: **domain.tld TXT nemp=nemp.domain.tld:443**

# # TODO: show progress bar of git clone & cp
# #whiptail --gauge "Installing NEMP Web Admin" 6 60 0

# # TODO: add update.sh script too
