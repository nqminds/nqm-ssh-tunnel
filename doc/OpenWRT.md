# OpenWRT Usage

Please see the [@nqminds/manysecured-openwrt-packages git repo](https://github.com/nqminds/manysecured-openwrt-packages) for build instructions.

## Installation

You can use `opkg install ssh-legion*.ipk` to install ssh-legion on OpenWRT from an `.ipk` file.

Alternatively, you could build an OpenWRT image already containing ssh-legion,
see the [OpenWRT wiki's quick image building guide](https://openwrt.org/docs/guide-developer/toolchain/beginners-build-guide#quick_image_building_guide)

## Post install steps

First, view the SSH key with:

```bash
ssh-legion --check --view-key
```

Next, add it to the server's `~/.ssh/authorized_keys` file (or `/home/ssh-tunnel/.ssh/authorized_keys` if you are using a different username):

Finally, confirm it's working with a final:

```bash
ssh-legion --check
```

You can restart the service with `/etc/init.d/ssh-legion restart`.

The service can be enabled (e.g. will run on startup) using `/etc/init.d/ssh-legion enable`.

Finally, you can view logs with `logread -e ssh-legion`.

It is highly recommended to restart the OpenWRT box and confirm that `ssh-legion` works.

## Turris OS

For Turris OS, you also need to add `ssh-legion` to the local repo, to prevent
Turris OS updates from automatically uninstalling your custom package.

See https://wiki.turris.cz/doc/en/public/custom_packages

Essentially, you need to run `localrepo add ~/download/ssh-legion_0.1.4-1_all.ipk`.

This will:

- create repository directory `/usr/share/updater/localrepo/user`
- add it into the configuration at `/usr/share/updater/localrepo/localrepo.lua`
- copy the specified `ssh-legion` package there (ie. into _user_ local repository)
