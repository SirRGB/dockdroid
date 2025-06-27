WIP
----

## Why Docker/Podman?

Docker/Podman provides a uniform build environment, without external dependencies, that you have to set up manually.  
The goal is to make building properly with ota and signing easy for everyone.


<details>
<summary>Setup</summary>
<br>

## Prerequisites

- [Podman](https://podman.io/docs/installation)
  - [Python venv](https://docs.python.org/3/library/venv.html#creating-virtual-environments)
  - [Podman compose](https://github.com/containers/podman-compose?tab=readme-ov-file#pip)
- or [Docker](https://docs.docker.com/engine/install)
  - [Docker Rootless](https://docs.docker.com/engine/security/rootless/)
- [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [GitConfig](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- ZRam (highly recommended): [Debian](https://wiki.debian.org/ZRam), [Fedora](https://github.com/systemd/zram-generator), [Ubuntu](https://wiki.ubuntuusers.de/zRam)


### Setting up permissions

First we need to find the UID, that is used for Docker/Podman.  
For Debian/Ubuntu this seems to be 100999 and on Fedora 52587,  
which should be $subUID+$containerUID-1 according to the [docker forums](https://forums.docker.com/t/map-more-uid-on-rootless-docker-and-mount-volume/102928/8).


We need to manually create the required folders for the respective volumes
```
mkdir -p ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
Copy the required dotfiles from the host machines
```
cp ~/.gitconfig ~/docker_droid/dotfiles/
cp -r ~/.ssh ~/docker_droid/dotfiles/
```
and clone this repo
```
git clone https://github.com/SirRGB/dockdroid ~/docker_droid/minideb
```

Then we need to chown that directory to the Docker user:

#### Debian/Ubuntu
```
sudo chown -R 100999:"${UID}" ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```

#### Fedora
```
sudo chown -R 52587:"${UID}" ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```

#### Other
(If you know a smarter way to do this please tell me,  
I know the available subuids can be found with `cat /etc/subuid | grep $USER | cut -d":" -f2`  
I just do not know if the container uid is predictable,  
it seems to be 1000 for debian/ubuntu and 100 for fedora)

Let other users read the directory
```
sudo chmod -R 507 ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
Run the first docker build
```
docker compose up --force-recreate --build
```
Wait until it starts syncing and stop using ctrl + c  
Find out the uid by running:
```
ls -n ~/docker_droid/src/Los15/.repo
```
Give ownership to the uid you found out:  
(replace the 1st UID)
```
sudo chown -R UID:"${UID}" ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/secrets ~/docker_droid/logs ~/docker_droid/keys
```
And remove the incomplete sync
```
sudo rm -rf ~/docker_droid/src/Los15/
```
</details>


<details>
<summary>Variables</summary>
<br>

## required

- DEVICE: Codename(s) of your device(s)
- ROM_DIR: Only change the last part after src/. Defines the source path within the container
- ROM_MANIFEST: URL of the rom manifest you want to sync
- ROM_BRANCH: Branch of the rom you want to sync
- LOCAL_MANIFEST: Direct link to the local manifest(s)
or
- CLONE_REPOS: Links to the repo(s) to clone. Repo name MUST have the following pattern https://github.com/user/android_dir1_dir2_dir3/tree/branch or https://github.com/user/dir1_dir2_dir3/tree/branch. Not recommended.

These variables should be defined in the target.env.

```
mv example.env target.env
```

```
DEVICE=cheeseburger,dumpling,TP1803
ROM_DIR=/droid_workdir/src/Los15
ROM_MANIFEST=https://github.com/LineageOS/android.git
ROM_BRANCH=lineage-22.2
LOCAL_MANIFEST=https://raw.githubusercontent.com/SirRGB/local_manifests/refs/heads/main/cheeseburgerdumpling/A15Lineage.xml,https://raw.githubusercontent.com/SirRGB/local_manifests/refs/heads/main/TP1803/A15Lineage.xml
```

## optional

- GitHub Upload
  - [GITHUB_TOKEN](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
  - OTA_REPO_URL: for example git@github.com:user/ota_config, will also be used for uploading
  - Requires passwordless ssh keys [added to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- SourceForge Upload
  - SF_USER: Username of your account
  - SF_RELEASES_REPO: Project name
  - Requires passwordless ssh keys added to your [SourceForge account](https://sourceforge.net/p/forge/documentation/SSH%20Keys)
- Telegram logging
  - [TELEGRAM_TOKEN](https://core.telegram.org/bots/features#botfather)
  - TELEGRAM_CHAT: either as @xyz or the id
- TIME_ZONE: either as in the format UTC+2 or CET

These variables should be defined in ~/docker_droid/secrets/token.sh to prevent accidentally leaking tokens.

```
export GITHUB_TOKEN=thing1234
export OTA_REPO_URL=git@github.com:user/ota_config
```


## Directories

- dotfiles: .gitconfig for syncing and .ssh for authentification. Needs to be copied from the host manually.
- keys: Contains keys for signing the build. Will be generated automatically if not provided.
- logs: Contains logs and error messages. Logs older than a day will be deleted on a rerun.
- ccache: Used for build caching to speed up compilation. Set to 40GB by default. Can be disabled by overwriting the value with 0 for space-saving.
- secrets: If token.sh is provided (optional), it will be read. You can specify GITHUB_TOKEN, TELEGRAM_TOKEN and TELEGRAM_CHAT here.


## Run the build

- After setting everything up you should do a test build with the default variables for testing. (Be sure to be in ~/docker_droid/minideb)
```
podman compose up --force-recreate --build
```
```
docker compose up --force-recreate --build
```
- You can set your own parameters within the [compose file](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-environment-attribute) or specifying an [env file](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/#use-the-env_file-attribute) and rerunning the build


## Too much RAM

You can further speed up build times by using tmpfs as described [here](https://github.com/alsutton/aosp-build-docker-images/tree/main?tab=readme-ov-file#improving-performance-on-linux)


## Limitations

- GitHub releases enforces a maximum file size of [2 GiB](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github#distributing-large-binaries) in their releases
- SourceForge restricts project size to [5-30 GiB](https://sourceforge.net/p/forge/documentation/Disk%20Quotas) depending on the download throughput
- GitLab releases are not feasible due to their [100 MiB](https://docs.gitlab.com/user/gitlab_com/#gitlab-cicd) attachment size limit


## Credits/Reference

- [alsutton](https://github.com/alsutton/aosp-build-docker-images/blob/main/debian-12-aosp.dockerfile)
- [Jarlpenguin](https://github.com/Jarlpenguin/releases)
- [ederevx](https://github.com/ederevx/android_scripts)
- [LeafOS](https://github.com/LeafOS-Project/leaf_build)
- [LineageOS4MicroG](https://github.com/lineageos4microg/docker-lineage-cicd)
- [amyROM](https://github.com/amyROM/vendor_amy/blob/207d5e32c3fba38b9fe1ab9cd12c71ca6b81d653/scripts/generate_json_build_info.sh)
- [LineageOS Infra](https://github.com/lineageos-infra/build-config/tree/main/android)
