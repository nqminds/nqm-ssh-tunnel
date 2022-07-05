# Debian/Ubuntu

To build the package for debian/ubuntu, run the following commands:

## Setup build

```bash
sudo apt install pbuilder
# replace for your ubuntu/debian distribution
sudo pbuilder create --debootstrapopts --variant=buildd --distribution focal
```

## Build

Firstly, update `debian/changelog` if there is a new version.
Then run the following command.

`pdebuild` with automatically ask for your `sudo` password.

```bash
pdebuild --debbuildopts "-us -uc"
```

When finished, a `.deb` file will be created in `ls /var/cache/pbuilder/result/`.
