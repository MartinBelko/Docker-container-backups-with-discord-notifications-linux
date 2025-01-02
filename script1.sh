#!/bin/bash

webhook_url="YOUR_DISCORD_WEBHOOK_URL"
docker_compose_file="/path/to/your/docker-compose.yml"
container_name="your_container_name"
backup_folder="/path/to/backups/"
smb_server="your_smb_server_ip_or_hostname"
smb_share_name="your_share_name"
smb_user="your_smb_username"
smb_password="your_smb_password"
mount_point="/mnt/backup_mount"
passphrase="your_passphrase"
max_backups=7
log_file="/path/to/logs/backup_log.txt"

# Function to send notification to Discord
send_discord_notification() {
  local message="$1"
  local file_path="$2"
  curl -H "Content-Type: application/json" -X POST -d "${message}" "${webhook_url}"
  if [ -n "${file_path}" ] && [ -f "${file_path}" ]; then
    echo "Attaching log file: ${file_path}"
    curl -F "file=@${file_path}" "${webhook_url}"
  elif [ -n "${file_path}" ]; then
    echo "Log file not found: ${file_path}"
  fi
}

# Function to capture terminal output and handle errors
capture_output() {
  local output
  output=$(mktemp)
  if ! "$@" > >(tee -a "$output") 2>&1; then
    local return_code=$?
    local error_message
    error_message=$(cat "$output")
    failure_message=$(cat << EOF
{
  "embeds": [
    {
      "title": "Docker Container Backup Failed",
      "description": "Backup of \"${container_name}\" failed.",
      "color": 16711680,
      "fields": [
        {
          "name": "Terminal Output",
          "value": "See attached log file for details.",
          "inline": false
        }
      ]
    }
  ]
}
EOF
)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup failed" >> "$log_file"
    cat "$output" >> "$log_file"
    echo "Log file content:"
    cat "$log_file"
    send_discord_notification "${failure_message}" "${log_file}"
    rm "$output"
    exit $return_code
  fi
  rm "$output"
}

# Reset the log file
> "$log_file"

# Get current date and time
start_time=$(date +%s)
current_datetime=$(date '+%Y-%m-%d %H:%M:%S')

# Create backup directory if it doesn't exist
capture_output mkdir -p "${backup_folder}"

# Create mount point directory if it doesn't exist
capture_output mkdir -p "${mount_point}"

# Change to the directory where the docker-compose.yml file is located
cd "$(dirname "${docker_compose_file}")"

# Stop Docker Compose services
echo "Stopping Docker Compose services..."
capture_output docker compose down

# Create backup archive
echo "Creating backup archive..."
capture_output tar -czvf "${backup_folder}/${container_name}_${current_datetime}.tar.gz" -C "$(dirname "${docker_compose_file}")" . -P

# Encrypt backup archive
echo "Encrypting backup archive..."
capture_output gpg --batch --yes --passphrase "${passphrase}" -c "${backup_folder}/${container_name}_${current_datetime}.tar.gz"

# Remove unencrypted archive
capture_output rm "${backup_folder}/${container_name}_${current_datetime}.tar.gz"

# Mount SMB share
echo "Mounting SMB share..."
capture_output mount -t cifs -o username="${smb_user}",password="${smb_password}" "//${smb_server}/${smb_share_name}" "${mount_point}"

# Copy encrypted backup to SMB share
echo "Copying backup to SMB share..."
capture_output cp "${backup_folder}/${container_name}_${current_datetime}.tar.gz.gpg" "${mount_point}"

# Remove old backups from remote location
echo "Removing old backups from remote location..."
capture_output find "${mount_point}" -type f -name "${container_name}_*.tar.gz.gpg" -printf '%T+ %p\n' | sort | head -n -${max_backups} | cut -d' ' -f2- | xargs -d '\n' rm -f

# Count remote backups before unmounting
remote_backup_count=$(find "${mount_point}" -type f -name "${container_name}_*.tar.gz.gpg" | wc -l)

# Unmount SMB share
echo "Unmounting SMB share..."
capture_output umount "${mount_point}"

# Remove old backups from local location
echo "Removing old backups from local location..."
capture_output find "${backup_folder}" -type f -name "${container_name}_*.tar.gz.gpg" -printf '%T+ %p\n' | sort | head -n -${max_backups} | cut -d' ' -f2- | xargs -d '\n' rm -f

# Start Docker Compose services
echo "Starting Docker Compose services..."
capture_output docker compose up -d

# Calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))

# Count local backups
local_backup_count=$(find "${backup_folder}" -type f -name "${container_name}_*.tar.gz.gpg" | wc -l)

# Success message
success_message=$(cat << EOF
{
  "embeds": [
    {
      "title": "Docker Container Backup Successful",
      "description": "Backup of \"${container_name}\" completed successfully.",
      "color": 65280,
      "fields": [
        {
          "name": "Date and Time",
          "value": "${current_datetime}",
          "inline": true
        },
        {
          "name": "Duration",
          "value": "${duration} seconds",
          "inline": true
        },
        {
          "name": "Local Backups",
          "value": "${local_backup_count}",
          "inline": true
        },
        {
          "name": "Remote Backups",
          "value": "${remote_backup_count}",
          "inline": true
        }
      ]
    }
  ]
}
EOF
)

# Send success notification to Discord
send_discord_notification "${success_message}" ""