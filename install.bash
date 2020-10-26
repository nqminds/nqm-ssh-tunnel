#!/usr/bin/env bash
#
# Installs the ssh tunnel service

command_name="$0"
server_private_key="$1"

function print_help() {
    # TODO: Fill this
    cat << EndOfMessage
${0} - Installs the ssh-tunnel service

Usage: ${0} ../path/to/server/ssh_private_key
EndOfMessage
}

server="nqminds-iot-hub-ssh-control"

if [[ -z "$server_private_key" || ! -f "$server_private_key" ]]; then
  >&2 echo "Error: You did not pass the SSH private key file to the server."
  print_help
  exit 1
fi

# stop the script if anything fails
# (see: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/)
set -Eeuo pipefail

# Absolute path to this script. /home/user/bin/foo.sh
script_path=$(readlink -f "$0")
# Absolute path this script is in. /home/user/bin
script_dir=$(dirname "$script_path")

function install-config() {
    if grep -Fxq "$server" "${HOME}/.ssh/config"; then
        # exists already, so return
        return
    else
        # append config to file only if it isn't already in config
        cat "${script_dir}/config" >> "${HOME}/.ssh/config"
    fi
}

function install-service() {
    mkdir -p "${HOME}/.local/bin"
    cp "${script_dir}/ssh-tunnel.bash" "${HOME}/.local/bin/"
    # start user-systemd on boot, not login
    sudo loginctl enable-linger "$USER"
    mkdir -p "${HOME}/.config/systemd/user"
    cp "${script_dir}/ssh-tunnel.service" "${HOME}/.config/systemd/user/"
    systemctl --user daemon-reload
    systemctl --user start ssh-tunnel.service
    systemctl --user enable ssh-tunnel.service
}

function install-ssh-key() {
    sudo apt-get install haveged -y # recommended to increase entropy
    # create SSH key if one does not exist
    if [ ! -f "${HOME}/.ssh/id_ed25519.pub" ]; then
        ssh-keygen -t ed25519 -C "${USER}@$(hostname)" \
        -f "${HOME}/.ssh/id_ed25519" -N ""
    fi
    ssh-copy-id -o "IdentityFile $server_private_key" "$server" -f
}

function main() {
    install-config
    install-ssh-key
    install-service
}
main
