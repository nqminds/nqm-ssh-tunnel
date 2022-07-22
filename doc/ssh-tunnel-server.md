# SSH Tunnel Server

Recommended secure config for the Nquiringminds's SSH Tunnel Server.

The following instructions creates a new user called `ssh-tunnel` on your server.
A chroot jail is then created at `/home/ssh-tunnel/chroot-jail` containing
only the files required for the ssh-legion script to work.

Finally, the `/etc/ssh/sshd_config` SSH config is modified so that ssh-ing
into the `ssh-tunnel` will always lead into the Chroot Jail.

### Create Chroot Jail

```bash
# creates /home/ssh-tunnel
sudo adduser --system ssh-tunnel --shell /usr/bin/bash
sudo -u ssh-tunnel mkdir --parents /home/ssh-tunnel/.ssh
chroot="/home/ssh-tunnel/chroot-jail"
# The path to the chroot-jail must be owned by root
sudo chown root:root /home/ssh-tunnel
sudo -u ssh-tunnel touch /home/ssh-tunnel/.ssh/authorized_keys
sudo -u ssh-tunnel chmod 600 /home/ssh-tunnel/.ssh/authorized_keys

function create_chroot_jail() {
    chroot_folder="$1"

    if [ -z "$chroot_folder" ]; then
        >&2 echo "Error in create_chroot_jail: chroot folder cannot be empty"
        exit 1
    fi

    sudo mkdir --parents "$chroot"/{dev,usr/bin,lib/x86_64-linux-gnu,lib64,home/ssh-tunnel/connections}
    # chroot jail must be owned by root
    sudo chown --recursive root:root "$chroot"
    sudo chmod 0755 "$chroot"
    sudo chown --recursive ssh-tunnel "$chroot"/home/ssh-tunnel/connections

    function copy_symlinks_to_file() {
        file="$1"
        output_dir="$2"
        if ls "$file" |& grep --quiet "Too many levels of symbolic links"; then
            ls "$file"
            exit "$?"
        fi
        sudo cp --verbose --parents --archive "$file" "$output_dir"
        while [ -L "$file" ]; do
            relative_path="$(readlink "$file")"
            file="$( cd "$(dirname "$file")" && cd "$(dirname "$relative_path")" && pwd )/$(basename "$relative_path")"
            sudo cp --verbose --parents --archive "$file" "$output_dir"
        done
    }
    copy_binaries=(bash /bin/sh printf base64 gunzip gzip mkdir rm sleep date mv touch)
    for binary in $(ldd $(which "${copy_binaries[@]}")|grep -v dynamic|cut -d " " -f 3|sed 's/://'|sort|uniq)
    do
        copy_symlinks_to_file "$binary" "$chroot"
    done

    # copy loader
    # ARCH amd64
    if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
        copy_symlinks_to_file /lib64/ld-linux-x86-64.so.2 "$chroot"
    fi

    # makes minimal /dev/* devices
    sudo mknod "$chroot/dev/null" c 1 3
    sudo mknod "$chroot/dev/zero" c 1 5
    sudo mknod "$chroot/dev/tty"  c 5 0
    sudo chmod 0666 "$chroot"/dev/{null,tty,zero}
    sudo chown root.tty "$chroot"/dev/tty
    # sudo mount -t devtmpfs none /home/ssh-tunnel/chroot-jail/dev
}

create_chroot_jail "$chroot"
ln -s "$chroot"/home/ssh-tunnel/connections /home/ssh-tunnel/connections
```

### `/etc/ssh/sshd_config` config

Then, add the following file to your `/etc/ssh/sshd_config` file:

```conf
# warning, this does not work from /etc/ssh/sshd_config/*.conf
# in OpenSSH <= 8.4, see https://bugzilla.mindrot.org/show_bug.cgi?id=3122
Match User ssh-tunnel
    ChrootDirectory %h/chroot-jail
```
