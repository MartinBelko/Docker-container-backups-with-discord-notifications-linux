# Docker-container-backups-with-discord-notifications-linux
Basic script to stop a container and back up the contents, where your docker compose file is located at the same place as the config folders, to a samba share with discord notifications using webhook. 

Personally i use Hetzner storage box for my backups, and i dont really bother using ssh, so i went back and forth with github copilot, chatgpt and gemini to create whatever this is (i dont know myself (jk)). 

Use this script as you like, just a personal project for my homelab, dont know how many iterations this will get, i'll probably forget i even put it here.

Prerequisites:
- Docker Compose
- Docker
- rsync
- cifs-utils
- curl
- gpg

Tested on rocky linux 9.5 on arm64 on my M1 Macbook Air (through UTM) and on x86. 
