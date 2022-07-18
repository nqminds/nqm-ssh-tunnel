# NQM SSH Tunnel

In order to enable NQM SSH tunnel as a service, you can run the following:

## Rootless SSH tunnel

You can run SSH tunnel without `sudo` by using a user systemd instance.

First, make sure it's enabled with:

```bash
# start user-systemd on boot, not login
sudo loginctl enable-linger "$(whoami)"
```

Then, you can start ssh-tunnel without `sudo` using:

```bash
systemctl --user start ssh-tunnel.service
# systemctl --user enable ssh-tunnel.service to auto run on startup
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
