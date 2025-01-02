# Docker-container-backups-with-discord-notifications-linux
A basic script to stop a container and back up its contents. The Docker Compose file and configuration folders should be located in the same directory. The backup is then sent to a Samba share with Discord notifications via a webhook.

Personal Note: I use Hetzner Storage Box for my backups and tend to avoid SSH. So, after some back-and-forth with GitHub Copilot, ChatGPT, and Gemini, I concocted whatever this is (I’m still figuring it out myself—just kidding).

Feel free to use this script as you like. It’s a personal project for my homelab, and I can't predict how many iterations this will go through. I might even forget I shared it here.

Prerequisites:
- Docker Compose
- Docker
- rsync
- cifs-utils
- curl
- gpg

Tested Environments:
- Rocky Linux 9 on ARM64 (via my M1 MacBook Air through UTM)
- Rocky Linux 9 on x86
