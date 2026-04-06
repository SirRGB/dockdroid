## Why Docker/Podman?

Docker/Podman provides a uniform build environment, without external dependencies, that you have to set up manually.  
The goal is to make building properly with ota and signing easy for everyone.  
This project targets Android 7 up to the most recent version.


<details>
<summary>Initial Setup</summary>

## Prerequisites

- [Podman](https://podman.io/docs/installation)
  - podman-docker or alias
- or [Docker](https://docs.docker.com/engine/install)
- [SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [GitConfig](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- ZRam (highly recommended): [Debian](https://wiki.debian.org/ZRam), [Fedora](https://github.com/systemd/zram-generator), [Ubuntu, Arch and others](https://wiki.archlinux.org/title/Zram)


We need to manually create the required folders for the respective volumes
```
mkdir --parents ~/docker_droid/src ~/docker_droid/dotfiles ~/docker_droid/ccache ~/docker_droid/logs ~/docker_droid/keys
```
Copy the required dotfiles from the host machines
```
cp ~/.gitconfig ~/docker_droid/dotfiles/
cp --recursive ~/.ssh ~/docker_droid/dotfiles/
```
and clone this repo
```
git clone https://github.com/SirRGB/dockdroid ~/docker_droid/minideb
```

Then we need to chown that directory to the Docker user:

</details>


<details>
<summary>Variables</summary>

### required

- ```DEVICE```: Codename(s) of your device(s)
- ```ROM_DIR```: Only change the last part after src/. Defines the source path within the container
- ```ROM_MANIFEST```: URL of the rom manifest you want to sync
- ```ROM_BRANCH```: Branch of the rom you want to sync
- ```LOCAL_MANIFEST```: Direct link to the local manifest(s)
or
- ```CLONE_REPOS```: Links to the repo(s) to clone. Repo name MUST have the following pattern https://github.com/user/android_dir1_dir2_dir3/tree/branch, https://github.com/user/dir1_dir2_dir3/tree/branch or https://github.com/user/proprietary_dir1_dir2_dir3/tree/branch. Not recommended.

These variables should be defined in the target.env.

```
cp ~/docker_droid/minideb/example.env ~/docker_droid/minideb/target.env
```

```
DEVICE=cheeseburger,dumpling,TP1803
ROM_DIR=/droid_workdir/src/Los15
ROM_MANIFEST=https://github.com/LineageOS/android.git
ROM_BRANCH=lineage-22.2
LOCAL_MANIFEST=https://raw.githubusercontent.com/SirRGB/local_manifests/refs/heads/main/cheeseburgerdumpling/A15Lineage.xml,https://raw.githubusercontent.com/SirRGB/local_manifests/refs/heads/main/TP1803/A15Lineage.xml
```

### optional

- Fallbacks
  - ```LUNCH_PREFIX_FALLBACK```: Prefix for lunching, i.e. lineage_ for LineageOS. Needed when neither ```LOCAL_MANIFEST``` or ```CLONE_REPOS``` are specified.
  - ```ROM_PREFIX_FALLBACK```: Prefix for naming, i.e. lineage will result in a package name like lineage-extraversion(if set)-version-date-device-signed.zip. Needed when *_TARGET_PACKAGE is not defined in vendor/*/build/tasks/* or build/core/Makefile.
  - ```ROM_VERSION_FALLBACK```: Version fallback for package name. Needed when rom does not specify PRODUCT_VERSION_MINOR/PRODUCT_VERSION_MAJOR in vendor/*/config/.
  - ```ROM_OTA_BRANCH_FALLBACK```: Ota branch fallback. Needed when roms have conflicting branch names and ota updates are set up.
  - ```RELEASETOOL_EXTRA_FLAGS```: Releasetool flags for setting up legacy quirks i.e. skip certain vintf checks.
- GitHub Upload
  - ```[GITHUB_TOKEN]```: [Github Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) for upload (and/or push) authentification
  - ```OTA_REPO_URL```: for example git@github.com:user/ota_config, will also be used for uploading
  - Requires ```GITHUB_TOKEN``` or passwordless ssh keys [added to your GitHub account](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
- SourceForge Upload
  - ```SF_USER```: Username of your account
  - ```SF_RELEASES_REPO```: Project name
  - Requires passwordless ssh keys added to your [SourceForge account](https://sourceforge.net/p/forge/documentation/SSH%20Keys)
- SSH Upload
  - ```SSH_USER```: Username on the ssh server
  - ```SSH_UPLOAD_URL```: ssh server domain or ip
  - ```SSH_DOWNLOAD_URL```: Direct download url excluding filename to ssh server
  - Requires passwordless ssh keys with respective public keys authorized on your ssh server
- Telegram logging
  - ```TELEGRAM_TOKEN```: [Telegram Token](https://core.telegram.org/bots/features#botfather). Needed when telegram logging is set up.
  - ```TELEGRAM_CHAT```: either as @xyz or the id
- ```TIME_ZONE```: either as in the format UTC+2 or CET
- ```ROM_BUILD_FLAGS```: if you want to define values like ```WITH_GMS=true``` you can do this in here, even with multiple of them separated by comma for separate builds or space for the same build
- OTA Updates
  - At least one file provider mentioned above
  - ```OTA_REPO_URL```: Any git hoster using ssh authentification i.e. GitHub, GitLab, CodeBerg,...
- Repopick
  - ```REPOPICK_PICKS```: Fetch changes from respective Gerrit instance using short-form change-id
  - ```REPOPICK_TOPICS```: Fetch changes from respective Gerrit instance using topics
  - ```REPOPICK_PULLS```: Pull changes from respective Gerrit instance using short-form change-id

These variables should be defined in config.env.

```
GITHUB_TOKEN=thing1234
OTA_REPO_URL=git@github.com:user/ota_config
```
</details>


## Directories

- ```dotfiles```: .gitconfig for syncing and .ssh for authentification. Needs to be copied from the host manually.
- ```keys```: Contains keys for signing the build. Will be generated automatically if not provided.
- ```logs```: Contains logs and error messages. Logs older than a day will be deleted on a rerun.
- ```ccache```: Used for build caching to speed up compilation. Set to 40GB by default. Can be disabled by overwriting the value with 0 for space-saving.


## Run the build

- After setting everything up you should do a test build with the default variables for testing. (Be sure to be in ~/docker_droid/minideb)
```
bash dockdroid
```


## Debugging

- Look up known issues in [TODO.md](TODO.md)
- If the error is undocumented you can set DEBUG=true in the target.env and send the part of the logs, where things go overboard via the [issues](https://github.com/SirRGB/dockdroid/issues) or debug it on your own and send a pull request.


## Too much RAM

You can further speed up build times by using tmpfs as described [here](https://github.com/alsutton/aosp-build-docker-images/tree/main?tab=readme-ov-file#improving-performance-on-linux)


## Limitations

- GitHub releases enforces a maximum file size of [2 GiB](https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github#distributing-large-binaries) in their releases
- SourceForge restricts project size to [5-30 GiB](https://sourceforge.net/p/forge/documentation/Disk%20Quotas) depending on the download throughput
- GitLab releases are not feasible due to their [100 MiB](https://docs.gitlab.com/user/gitlab_com/#gitlab-cicd) attachment size limit
- CodeBerg releases are not feasible due to their [100 MiB](https://codeberg.org/Codeberg-e.V./requests/issues/129) size limit as well


## Credits/Reference

- [alsutton](https://github.com/alsutton/aosp-build-docker-images/blob/main/debian-12-aosp.dockerfile)
- [Jarlpenguin](https://github.com/Jarlpenguin/releases)
- [ederevx](https://github.com/ederevx/android_scripts)
- [LeafOS](https://github.com/LeafOS-Project/leaf_build)
- [LineageOS4MicroG](https://github.com/lineageos4microg/docker-lineage-cicd)
- [amyROM](https://github.com/amyROM/vendor_amy/blob/207d5e32c3fba38b9fe1ab9cd12c71ca6b81d653/scripts/generate_json_build_info.sh)
- [LineageOS Infra](https://github.com/lineageos-infra/build-config/tree/main/android)
- [Halogen OS](https://github.com/halogenOS/android_external_xos/blob/fb9a58362b930807766100d1288ff809df6b7c51/xostools/xostools.sh)
