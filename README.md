WIP
----

## Why Docker?

Docker provides a uniform build environment, without external dependencies,  
that you have to set up manually.  
The goal is to make building properly with ota and signing easy for everyone.


## Prerequisites

- [Docker](https://docs.docker.com/engine/install)
- [Docker Rootless (recommended)](https://docs.docker.com/engine/security/rootless/)
- [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [GitConfig](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- ZRam [Debian](https://wiki.debian.org/ZRam), [Fedora](https://github.com/systemd/zram-generator), [Ubuntu](https://wiki.ubuntuusers.de/zRam)


## Setup

### Setting up permissions (rootless)

First we need to find the avaliable subuids, that are used for docker.  
For debian/ubuntu this seems to be 100999 and on fedora 52587,  
which should be $subUID+$containerUID-1 according to the [docker forums](https://forums.docker.com/t/map-more-uid-on-rootless-docker-and-mount-volume/102928/8).


We need to manually create the required folders, because Docker does not run as Root (assuming you did choose the Rootless Setup).
```
mkdir -p ~/docker_droid/src/Los14/.repo ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
and clone this repo
```
git clone https://github.com/SirRGB/dockdroid ~/docker_droid/dockdroid
```

Then we need to chown that directory to the Docker user:  

#### Debian/Ubuntu
```
sudo chown -R 100999:100999 ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```

#### Fedora
```
sudo chown -R 52587:52587 ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```

#### Other
(If you know a smarter way to do this please tell me,  
I know the available suibuids can be found with `cat /etc/subuid | grep $USER | cut -d":" -f2`  
I just do not know if the container uid is predictable,  
it seems to be 1000 for debian/ubuntu and 100 for fedora)

Let other users read the directory
```
sudo chmod -R 507 ~/docker_droid/src/Los14/.repo ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
Run the first docker build
```
docker compose up --force-recreate --build
```
Wait until it starts syncing and stop using ctrl + c  
Find out the uid by running:
```
ls -n ~/docker_droid/src/Los14/.repo
```
Give ownership to the uid you found out:
```
(replace UID)
sudo chown -R UID:UID ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
And remove the incomplete sync
```
sudo rm -rf ~/docker_droid/src/Los14/
```


## Variables (secrets)

- [GITHUB_TOKEN](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- GH_RELEASES_REPO
- SF_USER
- SF_RELEASES_REPO
- [TELEGRAM_TOKEN](https://core.telegram.org/bots/features#botfather)
- TELEGRAM_CHAT

Authentication:
while github releases relies on the token, ota info pushing to a github repo and the sourceforge upload require ssh keys, that are added in your account and gitconfig.

# Directories

- dotfiles: .gitconfig for syncing and .ssh for authentification. Needs to be copied from the host manually.
- keys: Contains keys for signing the build. Will be generated automatically if not provided.
- logs: Will soon contain logs and error messages.
- ccache: Used for build caching to speed up compilation. Set to 80GB by default. Can be disabled by overwriting the value with 0 for space saving.
- secrets: If token.sh is provided (optional), it will be read. You can specify GITHUB_TOKEN, TELEGRAM_TOKEN and TELEGRAM_CHAT here.


# Run the build

- After setting everything up you should do a test build with the default variables for testing. (Be sure to be in ~/docker_droid/dockdroid)
```
docker compose up --force-recreate --build
```
- You can set your own parameters within the [compose file](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-environment-attribute) or specifying an [env file](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute) and rerunning the build


# Too much RAM

You can further speed up build times by using tmpfs as described [here](https://github.com/alsutton/aosp-build-docker-images/tree/main?tab=readme-ov-file#improving-performance-on-linux)


## Credits/Reference

- [alsutton/aosp-build-docker-images](https://github.com/alsutton/aosp-build-docker-images/blob/main/debian-12-aosp.dockerfile)
- [Jarlpenguin/releases](https://github.com/Jarlpenguin/releases)
- [ederevx/android_scripts](https://github.com/ederevx/android_scripts)
- [LeafOS-Project/leaf_build](https://github.com/LeafOS-Project/leaf_build)
- [lineageos4microg/docker-lineage-cicd](https://github.com/lineageos4microg/docker-lineage-cicd)
- [amyROM/vendor_amy](https://github.com/amyROM/vendor_amy/blob/207d5e32c3fba38b9fe1ab9cd12c71ca6b81d653/scripts/generate_json_build_info.sh)

github release taken from
- [Jarlpenguin/releases](https://github.com/Jarlpenguin/releases/raw/main/bin/github-release)
