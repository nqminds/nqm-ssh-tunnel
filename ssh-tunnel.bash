#!/usr/bin/env bash
#
# Creates an SSH Tunnel to the specified server.

function ssh-tunnel() {
  MACHINE_ID=$(cat /etc/machine-id)
  SALTED_MACHINE_ID=$(\
          echo "${MACHINE_ID}_nqminds-random-fixed-saltWW19bNQ5VI2xkM" \
          | shasum -a 512256 | xxd -r -p | base64 -w0)

  # default tunnel port in 49152-65535 fixed on machine id
  PORT=$((0x$MACHINE_ID%16383 + 49152))

  # see https://tools.ietf.org/html/rfc3548#page-6 for base64 in filenames
  SALTED_MACHINE_ID=${SALTED_MACHINE_ID//"/"/"_"}
  SALTED_MACHINE_ID=${SALTED_MACHINE_ID//"+"/"-"}
  MYNAME="$(whoami)@$(hostname)"

  # keep on running ssh tunnel until we don't have a listen port failure

  # putting localhost:${PORT} means the port is only accessible from localhost.
  # putting *:${PORT}, means the port is accessible from all interfaces, ie
  # going www.server.com:8080 will connect to the client:22

  while FNAME="${MYNAME}:${PORT}" \
    && ssh -tt -o "RemoteForward=localhost:${PORT} localhost:22" "${destination}" \
    "mkdir -p ~/connections \
    && FNAME=${FNAME} \
    && if [ -f ~/connections/\${FNAME} \
        && ! grep "Machine ID: ${SALTED_MACHINE_ID}" < ~/connections/\${FNAME}]; then \
      FNAME=${FNAME}+${SALTED_MACHINE_ID}; fi \
    && echo $( \
        DATA="${MYNAME} tunneled to localhost:${PORT} on $(date --iso-8601=seconds)"; \
        DATA="${DATA}\nSalted Machine ID: ${SALTED_MACHINE_ID}"; \
        IP_A_DATA="${MYNAME}:~$ ip a \n $(ip a) \n"; \
        printf "${DATA}\n${IP_A_DATA}" | gzip | base64 -w0 \
      ) \
      | base64 -d | gunzip > ~/connections/\${FNAME} \
    && rm -f ~/connections/\${FNAME}+disconnected \
    && eval 'sleep infinity&' \
    && eval 'echo \\\$1' | read SLEEP_PID \
    && trap \"mv ~/connections/\${FNAME} \
      ~/connections/\${FNAME}+disconnected\
      && eval 'echo Disconnected at \\\$(date --iso-8601=seconds)'\
        >> ~/connections/\${FNAME}+disconnected\
      && kill -SIGINT \\\${SLEEP_PID} \" EXIT \
    && wait" \
  |& grep "Error: remote port forwarding failed for listen port"; do
    # RemotePortForwarding Failed!
    # Port already in use
    # Try using random ports until one works.

    # we want a port between 1024 and 65535, range of 64511 numbers
    R=$(($RANDOM%64511))
    # our random port
    PORT=$(($R+1024))
    # make sure the PORT isn't in the list of IANA registered ports
    while grep "${PORT}/tcp" /etc/services; do
      # find a new random port
      R=$(($RANDOM%64511)); PORT=$(($R+1024))
    done
  done
}

destination=nqminds-iot-hub-ssh-control

help_text="Usage: $(basename "$0") [OPTIONS] [DESTINATION]

Creates an SSH tunnel to the specified server.

The tunnel port will be 'localhost:<port>' on the server, where
<port> is a pseudo-random port based on this machines's /etc/machine-id value.
(or random if it's not available).

While the tunnel is active, a file called '~/connections/<hostname>:<port>'
will be created on the server, containing the 'ip a' data of this
machine. You can then SSH into this machine from the server using:
'ssh <user>@localhost -p <port>'.

When the tunnel is closed, the file will be renamed to
'~/connections/<hostname>:<port>+disconnected'.

Options:
  -h, --help: Show this help message and exit.
  -d, --destination: The destination to SSH to.
                     Defaults to nqminds-iot-hub-ssh-control
                     in your ~/.ssh/config file.
"

showHelp() {
  echo 2>&1 "$help_text"
}

options=$(getopt -l "help,destination:" -o "h,d:" -- "$@")
eval set -- "$options"

while true; do
case $1 in
-h|--help)
    showHelp
    exit 0
    ;;
-d|--destination)
    destination="$2"
    shift
    ;;
--)
    shift
    break;;
*) # default
    showHelp
    exit 1
    ;;
esac
shift
done

export destination="${destination}"

ssh-tunnel

echo 2>&1 "$(basename "$0") --destination ${destination} failed"
# always return failure since ssh-tunnel should never end
exit 1
