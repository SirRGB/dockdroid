WIP
----

Prerequisites
--
- [docker](https://docs.docker.com/engine/install)
- [docker rootless (recommended)](https://docs.docker.com/engine/security/rootless/)
- [ssh](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
- [gitconfig](https://git-scm.com/book/en/v2/Getting-Started-First-Time-Git-Setup)
- [zram/swap (distro dependant, highly recommended)](https://github.com/systemd/zram-generator)
- currently the only way it seems to work is creating ~/docker_droid/Los14/.repo by hand, chmodding that to 707  
  and getting a sync started and then checking the uid with ls -n, to chown everything to dockeruser:user and chmodding it to 770.  
  for debian/ubuntu this seems to be 100999 and on fedora 52587, which should be  $subUID+$containerUID-1 according to the [docker forums](https://forums.docker.com/t/map-more-uid-on-rootless-docker-and-mount-volume/102928/8)

Variables (secrets)
--
- [GITHUB_TOKEN](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)
- GH_RELEASES_REPO
- SF_USER
- SF_RELEASES_REPO
- [TELEGRAM_TOKEN](https://core.telegram.org/bots/features#botfather)
- TELEGRAM_CHAT

Authentication:
while github releases relies on the token, ota info pushing to a github repo and the sourceforge upload require ssh keys, that are added in your account and gitconfig.

Credits/Reference
--
- https://github.com/alsutton/aosp-build-docker-images/blob/main/debian-12-aosp.dockerfile
- https://github.com/Jarlpenguin/releases
- https://github.com/ederevx/android_scripts
- https://github.com/LeafOS-Project/leaf_build
- https://github.com/lineageos4microg/docker-lineage-cicd
- https://github.com/amyROM/vendor_amy/blob/207d5e32c3fba38b9fe1ab9cd12c71ca6b81d653/scripts/generate_json_build_info.sh

github release taken from
- https://github.com/Jarlpenguin/releases/raw/main/bin/github-release
