# NQM SSH Tunnel

Creates a reverse SSH tunnel to an SSH server.

## Usage

First, configure `config` to contain the username and hostname of the
SSH server:

```
Host nqminds-iot-hub-ssh-control
        HostName ec2-34-251-158-148.eu-west-1.compute.amazonaws.com # change this
        User ubuntu # change this
```

Run the `ssh-tunnel.bash` script to install, using a pre-existing private key for the SSH server (e.g. the one autogenerated by AWS).
This private key will only be used for the initial setup, and can be removed later.

Do not run this bash script as root using `sudo`,
the script will ask you for your `sudo` password when needed.

```bash
bash install.bash ./your/path/to/the/private/key
```

This will:

- install the given config in the `~/.ssh/config` file if it doesn't exist.
  - WARNING, IT WILL NOT UPDATE IF THERE IS ALREADY AN ENTRY
- connect to the SSH server using the privatekey provided,
- create a new public/private key that will be used for future logins,
- install the new public key on the SSH server,
- install a systemd user service to automatically setup a reverse tunnel
- starts the reverse tunnel service

Then, when you connect to the SSH server, you will find a folder called `connections`.
Each file will have the name of a connected reverse SSH host, of format `<username>@<hostname>:<port>`, e.g.

```console
ubuntu@nqminds-iot-hub-ssh-control $ ls connections/
alexandru@dazzling-dream:48106
```

You can then connect to one of the hosts via `ssh <username>@localhost -p <port>`.
The port is normally constant.
The only time it changes is if the port is already in use when an SSH client connects to the server (can happen sometimes when a client loses connection to the server and instantly reconnects, while the server still has the previous connection open).

Because the port is constant, you can use the following config to jump straight to a reverse-SSHed device,
from your local PC, in your `~/.ssh/config` file, to just run `ssh dazzling-dream`:

```config
# The SSH Reverse Server
Host amazonhubnqm
	HostName ec2-34-251-158-148.eu-west-1.compute.amazonaws.com
	User ubuntu

Host dazzling-dream
	HostName localhost
	User alexandru
	Port 48106 # this is the port you will see when you run ls connections/ on the server
	ProxyJump amazonhubnqm # we "Jump" through the SSH reverse server
```

### Viewing logs

If you ever want to view the logs of the reverse SSH service, you can do this
via:

```bash
journalctl --user -u ssh-tunnel.service
```

`journalctl` has the `-f` flag to watch the live logs of a service, that
may be useful in debugging:

```bash
journalctl --user -fu ssh-tunnel.service
```

### Stopping/disabling the service

You can disable (prevent the service from launching on startup), or stop
the service by using `systemctl --user`. Example:

**To stop the service**

```bash
systemctl --user stop ssh-tunnel.service
```

**To disable the service from running on the next boot**

```bash
systemctl --user disable ssh-tunnel.service
```
